#!/usr/bin/env bash
set -euo pipefail

# Syncs plugin jars/configs from ./plugins into ./server/plugins, overwriting existing ones.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGINS_DIR="$REPO_ROOT/plugins"
SERVER_DIR="$REPO_ROOT/server"
SERVER_PLUGINS_DIR="$SERVER_DIR/plugins"

if [[ ! -d "$PLUGINS_DIR" ]]; then
  echo "plugins directory not found: $PLUGINS_DIR" 1>&2
  exit 1
fi

mkdir -p "$SERVER_PLUGINS_DIR"

echo "[plugins] Syncing $PLUGINS_DIR -> $SERVER_PLUGINS_DIR"
if command -v rsync >/dev/null 2>&1; then
  rsync -av --exclude='.gitkeep' --exclude='*/.gitkeep' "$PLUGINS_DIR/" "$SERVER_PLUGINS_DIR/"
else
  (
    cd "$PLUGINS_DIR"
    tar -cf - --exclude='./.gitkeep' --exclude='*/.gitkeep' .
  ) | (
    cd "$SERVER_PLUGINS_DIR"
    tar -xpf -
  )
fi

echo "[plugins] Done"


