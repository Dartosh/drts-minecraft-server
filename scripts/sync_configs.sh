#!/usr/bin/env bash
set -euo pipefail

# Syncs configuration files from ./configs into ./server, overwriting existing ones.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIGS_DIR="$REPO_ROOT/configs"
SERVER_DIR="$REPO_ROOT/server"

if [[ ! -d "$CONFIGS_DIR" ]]; then
  echo "configs directory not found: $CONFIGS_DIR" 1>&2
  exit 1
fi

mkdir -p "$SERVER_DIR"

echo "[configs] Syncing $CONFIGS_DIR -> $SERVER_DIR"
if command -v rsync >/dev/null 2>&1; then
  rsync -av --exclude='.gitkeep' --exclude='*/.gitkeep' "$CONFIGS_DIR/" "$SERVER_DIR/"
else
  # Fallback without touching target .gitkeep: stream via tar excluding .gitkeep
  (
    cd "$CONFIGS_DIR"
    tar -cf - --exclude='./.gitkeep' --exclude='*/.gitkeep' .
  ) | (
    cd "$SERVER_DIR"
    tar -xpf -
  )
fi

echo "[configs] Done"


