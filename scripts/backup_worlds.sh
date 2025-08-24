#!/usr/bin/env bash
set -euo pipefail

# Saves current worlds from ./server into ./maps/<timestamp>/

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SERVER_DIR="$REPO_ROOT/server"
MAPS_DIR="$REPO_ROOT/maps"

timestamp="$(date +%Y%m%d-%H%M%S)"

mkdir -p "$SERVER_DIR" "$MAPS_DIR"

echo "[backup] Detecting worlds in $SERVER_DIR"
world_dirs=()
if [[ -d "$SERVER_DIR" ]]; then
  while IFS= read -r -d '' dir; do
    if [[ -f "$dir/level.dat" ]]; then
      world_dirs+=("$dir")
    fi
  done < <(find "$SERVER_DIR" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null || true)
fi

if [[ ${#world_dirs[@]} -eq 0 ]]; then
  echo "[backup] No worlds found"
  exit 0
fi

TARGET="$MAPS_DIR/$timestamp"
mkdir -p "$TARGET"
echo "[backup] Saving worlds into $TARGET"
for src in "${world_dirs[@]}"; do
  name="$(basename "$src")"
  dest="$TARGET/$name"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete "$src/" "$dest/"
  else
    rm -rf "$dest" && mkdir -p "$dest" && cp -a "$src/." "$dest/"
  fi
done

echo "[backup] Done: $TARGET"


