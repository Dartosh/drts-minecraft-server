#!/usr/bin/env bash
set -euo pipefail

# Restores worlds from maps/<timestamp>/ into server/
# Usage:
#   scripts/restore_worlds.sh [--backup <timestamp_folder>]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SERVER_DIR="$REPO_ROOT/server"
MAPS_DIR="$REPO_ROOT/maps"

backup_folder=""

function usage() {
  echo "Usage: $0 [--backup <timestamp_folder>]" 1>&2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --backup|-b)
      backup_folder="${2:-}"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" 1>&2; usage; exit 2 ;;
  esac
done

mkdir -p "$SERVER_DIR" "$MAPS_DIR"

src_maps_dir=""
if [[ -n "$backup_folder" ]]; then
  candidate="$MAPS_DIR/${backup_folder%/}"
  if [[ -d "$candidate" ]]; then
    src_maps_dir="$candidate"
  else
    echo "[restore] Specified backup folder not found: $candidate" 1>&2
    exit 1
  fi
else
  latest_snapshot=""
  if ls -1d "$MAPS_DIR"/*/ >/dev/null 2>&1; then
    latest_snapshot="$(ls -1d "$MAPS_DIR"/*/ 2>/dev/null | sed 's:/*$::' | awk -F/ '{print $NF}' | sort | tail -n 1)"
  fi
  if [[ -n "$latest_snapshot" && -d "$MAPS_DIR/$latest_snapshot" ]]; then
    src_maps_dir="$MAPS_DIR/$latest_snapshot"
  else
    echo "[restore] No snapshots in $MAPS_DIR" 1>&2
    exit 0
  fi
fi

echo "[restore] Restoring from $src_maps_dir"

map_worlds=()
while IFS= read -r -d '' dir; do
  if [[ -f "$dir/level.dat" ]]; then
    map_worlds+=("$dir")
  fi
done < <(find "$src_maps_dir" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null || true)

if [[ ${#map_worlds[@]} -eq 0 ]]; then
  echo "[restore] No valid worlds found in $src_maps_dir" 1>&2
  exit 0
fi

for src in "${map_worlds[@]}"; do
  name="$(basename "$src")"
  dest="$SERVER_DIR/$name"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete "$src/" "$dest/"
  else
    rm -rf "$dest" && mkdir -p "$dest" && cp -a "$src/." "$dest/"
  fi
  echo "[restore] World '$name' restored"
done

echo "[restore] Done"


