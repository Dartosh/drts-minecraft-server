#!/usr/bin/env bash
set -euo pipefail

# Downloads server jar and prepares minimal files
# Usage:
#   scripts/reinstall_server.sh --new_fork <Bukkit|Spigot|Paper|Tuinity|Purpur> --url <download_url>

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SERVER_DIR="$REPO_ROOT/server"

ALLOWED_FORKS=("Bukkit" "Spigot" "Paper" "Tuinity" "Purpur")

new_fork=""
url=""

function usage() {
  echo "Usage: $0 --new_fork <${ALLOWED_FORKS[*]}> --url <download_url>" 1>&2
}

function is_allowed_fork() {
  local value="$1"
  for f in "${ALLOWED_FORKS[@]}"; do
    if [[ "$f" == "$value" ]]; then return 0; fi
  done
  return 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --new_fork)
      new_fork="${2:-}"; shift 2 ;;
    --url)
      url="${2:-}"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" 1>&2; usage; exit 2 ;;
  esac
done

if [[ -z "$new_fork" || -z "$url" ]]; then
  echo "--new_fork and --url are required" 1>&2; usage; exit 2
fi
if ! is_allowed_fork "$new_fork"; then
  echo "Invalid --new_fork: $new_fork. Allowed: ${ALLOWED_FORKS[*]}" 1>&2; exit 2
fi

mkdir -p "$SERVER_DIR"

tmpfile="$(mktemp)"
trap 'rm -f "$tmpfile"' EXIT

echo "[reinstall] Downloading $new_fork from URL"
curl -L --fail --connect-timeout 20 --retry 3 --retry-delay 2 -o "$tmpfile" "$url"

filesize=$(stat -f%z "$tmpfile" 2>/dev/null || stat -c%s "$tmpfile" 2>/dev/null || echo 0)
if [[ "$filesize" -lt 1024 ]]; then
  echo "[reinstall] Downloaded file size looks too small ($filesize bytes). Aborting." 1>&2
  exit 3
fi

echo "[reinstall] Installing to $SERVER_DIR/server.jar"
mv -f "$tmpfile" "$SERVER_DIR/server.jar"
chmod 0644 "$SERVER_DIR/server.jar"

if [[ ! -f "$SERVER_DIR/eula.txt" ]]; then
  echo "eula=true" > "$SERVER_DIR/eula.txt"
fi

echo "[reinstall] Done"


