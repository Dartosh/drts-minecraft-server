#!/usr/bin/env bash
set -euo pipefail

# Installs or reinstalls systemd service for Minecraft server
# Ubuntu 24.04 (systemd). Requires sudo privileges.
#
# Usage:
#   scripts/install_systemd_service.sh [--service-name minecraft-server-service] [--user <user>] [--workdir <repo_root>]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SERVICE_NAME="minecraft-server-service"
RUN_USER="${SUDO_USER:-$USER}"
WORKDIR="$REPO_ROOT"

function usage() {
  echo "Usage: $0 [--service-name <name>] [--user <user>] [--workdir <repo_root>]" 1>&2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --service-name)
      SERVICE_NAME="${2:-}"; shift 2 ;;
    --user)
      RUN_USER="${2:-}"; shift 2 ;;
    --workdir)
      WORKDIR="${2:-}"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" 1>&2; usage; exit 2 ;;
  esac
done

UNIT_PATH="/etc/systemd/system/${SERVICE_NAME}.service"
START_SCRIPT="$WORKDIR/scripts/start_server.sh"

if [[ -f "$START_SCRIPT" && ! -x "$START_SCRIPT" ]]; then
  chmod +x "$START_SCRIPT" 2>/dev/null || sudo chmod +x "$START_SCRIPT" 2>/dev/null || true
fi
if [[ ! -f "$START_SCRIPT" ]]; then
  echo "Start script not found: $START_SCRIPT" 1>&2
  exit 1
fi

echo "Installing systemd service: $SERVICE_NAME"

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

sudo mv "$TMP_UNIT" "$UNIT_PATH"
sudo chmod 0644 "$UNIT_PATH"

echo "Reloading systemd daemon"
sudo systemctl daemon-reload

if systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
  echo "Service exists, restarting..."
  sudo systemctl restart "$SERVICE_NAME"
else
  echo "Enabling and starting service..."
  sudo systemctl enable "$SERVICE_NAME"
  sudo systemctl start "$SERVICE_NAME"
fi

echo "Done. Status:"
systemctl status "$SERVICE_NAME" --no-pager || true


