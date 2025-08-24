#!/usr/bin/env bash
set -euo pipefail

# Runs backup_worlds.sh then prunes old snapshots in maps/, keeping only the last N (default 4)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MAPS_DIR="$REPO_ROOT/maps"

# How many snapshots to keep (can override via env KEEP_COUNT)
KEEP_COUNT="${KEEP_COUNT:-4}"

mkdir -p "$MAPS_DIR"

"$SCRIPT_DIR/backup_worlds.sh"

# Collect timestamped snapshot folders (top-level subdirs of maps/)
snapshots=()
while IFS= read -r -d '' dir; do
  bn="$(basename "$dir")"
  snapshots+=("$bn")
done < <(find "$MAPS_DIR" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null || true)

count=${#snapshots[@]}
if [[ $count -le $KEEP_COUNT ]]; then
  exit 0
fi

# Sort by name (YYYYmmdd-HHMMSS sorts lexicographically)
readarray -t sorted < <(printf '%s\n' "${snapshots[@]}" | sort)
to_delete=$(( count - KEEP_COUNT ))

for (( i=0; i<to_delete; i++ )); do
  dir="$MAPS_DIR/${sorted[$i]}"
  rm -rf "$dir"
done

exit 0


