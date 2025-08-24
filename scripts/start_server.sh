#!/usr/bin/env bash
set -euo pipefail

# Starts the Minecraft server from ./server/server.jar

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SERVER_DIR="$REPO_ROOT/server"

JAVA_BIN="${JAVA_BIN:-java}"
MIN_MEM="${MIN_MEM:-1G}"
MAX_MEM="${MAX_MEM:-2G}"
EXTRA_OPTS="${EXTRA_OPTS:-}"

cd "$SERVER_DIR"

exec "$JAVA_BIN" -Xms"$MIN_MEM" -Xmx"$MAX_MEM" $EXTRA_OPTS -jar server.jar nogui


