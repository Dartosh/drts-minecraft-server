#!/usr/bin/env bash
set -euo pipefail

# Installs or reinstalls systemd service for Minecraft server
# Ubuntu 24.04 (systemd). Supports system scope (root) and user scope (no sudo).
#
# Usage:
#   scripts/install_systemd_service.sh \
#     [--service-name minecraft-server-service] \
#     [--user <user>] \
#     [--workdir <repo_root>] \
#     [--scope system|user] \
#     [--cron-fallback]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SERVICE_NAME="minecraft-server-service"
RUN_USER="${SUDO_USER:-$USER}"
WORKDIR="$REPO_ROOT"
SCOPE="system"    # system -> /etc/systemd/system (requires sudo), user -> ~/.config/systemd/user (no sudo)
CRON_FALLBACK=false

function usage() {
  echo "Usage: $0 [--service-name <name>] [--user <user>] [--workdir <repo_root>] [--scope system|user] [--cron-fallback]" 1>&2
}

# Runs a command with elevated privileges when needed.
# - If running as root, runs directly
# - If SUDO_PASSWORD is set, uses `sudo -S` non-interactively
# - Otherwise falls back to plain `sudo` (may prompt)
function sudo_run() {
  if [[ $EUID -eq 0 ]]; then
    "$@"
  else
    if [[ -n "${SUDO_PASSWORD:-}" ]]; then
      printf '%s\n' "$SUDO_PASSWORD" | sudo -S -p '' "$@"
    else
      sudo "$@"
    fi
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --service-name)
      SERVICE_NAME="${2:-}"; shift 2 ;;
    --user)
      RUN_USER="${2:-}"; shift 2 ;;
    --workdir)
      WORKDIR="${2:-}"; shift 2 ;;
    --scope)
      SCOPE="${2:-}"; shift 2 ;;
    --cron-fallback)
      CRON_FALLBACK=true; shift 1 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" 1>&2; usage; exit 2 ;;
  esac
done

if [[ "$SCOPE" == "user" ]]; then
  UNIT_PATH="$HOME/.config/systemd/user/${SERVICE_NAME}.service"
  SYSTEMCTL_CMD=(systemctl --user)
  # Login session for user services: enable lingering to run without active login session
  if command -v loginctl >/dev/null 2>&1; then
    loginctl enable-linger "$RUN_USER" >/dev/null 2>&1 || true
  fi
else
  UNIT_PATH="/etc/systemd/system/${SERVICE_NAME}.service"
  SYSTEMCTL_CMD=(systemctl)
fi
START_SCRIPT="$WORKDIR/scripts/start_server.sh"

if [[ -f "$START_SCRIPT" && ! -x "$START_SCRIPT" ]]; then
  chmod +x "$START_SCRIPT" 2>/dev/null || sudo_run chmod +x "$START_SCRIPT" 2>/dev/null || true
fi
if [[ ! -f "$START_SCRIPT" ]]; then
  echo "Start script not found: $START_SCRIPT" 1>&2
  exit 1
fi

echo "Installing systemd service: $SERVICE_NAME (scope: $SCOPE)"

TMP_UNIT="$(mktemp)"
cat > "$TMP_UNIT" <<EOF
[Unit]
Description=Minecraft Server Service
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
User=${RUN_USER}
WorkingDirectory=${WORKDIR}
ExecStart=${START_SCRIPT}
Restart=always
RestartSec=5
Environment=JAVA_BIN=java
Environment=MIN_MEM=1G
Environment=MAX_MEM=2G

[Install]
WantedBy=multi-user.target
EOF

if [[ "$SCOPE" == "user" ]]; then
  mkdir -p "$(dirname "$UNIT_PATH")"
  mv "$TMP_UNIT" "$UNIT_PATH"
  chmod 0644 "$UNIT_PATH"
else
  sudo_run mv "$TMP_UNIT" "$UNIT_PATH"
  sudo_run chmod 0644 "$UNIT_PATH"
fi

echo "Reloading systemd daemon"
if [[ "$SCOPE" == "user" ]]; then
  if ! "${SYSTEMCTL_CMD[@]}" daemon-reload; then
    if [[ "$CRON_FALLBACK" == true ]]; then
      echo "systemd --user not available. Installing cron @reboot fallback..."
      mkdir -p "$(dirname "$UNIT_PATH")" >/dev/null 2>&1 || true
      CRON_LINE="@reboot \"$START_SCRIPT\""
      # Install or update crontab entry idempotently
      (crontab -l 2>/dev/null | grep -v -F "$CRON_LINE"; echo "$CRON_LINE") | crontab -
      # Start now in background for current boot
      nohup "$START_SCRIPT" >/dev/null 2>&1 < /dev/null &
      echo "Cron fallback installed and server started (nohup)."
      exit 0
    else
      echo "systemd --user not available and --cron-fallback not set." 1>&2
      exit 1
    fi
  fi
else
  sudo_run "${SYSTEMCTL_CMD[@]}" daemon-reload
fi

if "${SYSTEMCTL_CMD[@]}" is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
  echo "Service exists, restarting..."
  if [[ "$SCOPE" == "user" ]]; then
    "${SYSTEMCTL_CMD[@]}" restart "$SERVICE_NAME"
  else
    sudo_run "${SYSTEMCTL_CMD[@]}" restart "$SERVICE_NAME"
  fi
else
  echo "Enabling and starting service..."
  if [[ "$SCOPE" == "user" ]]; then
    "${SYSTEMCTL_CMD[@]}" enable --now "$SERVICE_NAME" || true
    "${SYSTEMCTL_CMD[@]}" start "$SERVICE_NAME"
  else
    sudo_run "${SYSTEMCTL_CMD[@]}" enable "$SERVICE_NAME"
    sudo_run "${SYSTEMCTL_CMD[@]}" start "$SERVICE_NAME"
  fi
fi

echo "Done. Status:"
if [[ "$SCOPE" == "user" ]]; then
  "${SYSTEMCTL_CMD[@]}" status "$SERVICE_NAME" --no-pager || true
else
  sudo_run "${SYSTEMCTL_CMD[@]}" status "$SERVICE_NAME" --no-pager || true
fi


