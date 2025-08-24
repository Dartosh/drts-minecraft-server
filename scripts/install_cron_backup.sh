#!/usr/bin/env bash
set -euo pipefail

# Installs or reinstalls a cron job to run backup_and_prune.sh every 12 hours
# Uses user crontab. Requires that scripts/ is accessible from the same path.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CRON_ID="# minecraft-backup-cron"
CMD="bash $REPO_ROOT/scripts/backup_and_prune.sh"

# Prepare cron line: every 12 hours at minute 0
CRON_LINE="0 */12 * * * $CMD $CRON_ID"

echo "Installing cron job: $CRON_LINE"

existing="$(crontab -l 2>/dev/null || true)"

# Remove previous job (if exists)
filtered="$(printf "%s\n" "$existing" | grep -v "$CRON_ID" || true)"

printf "%s\n%s\n" "$filtered" "$CRON_LINE" | crontab -

echo "Cron installed. Current crontab:"
crontab -l | sed -n "1,200p"


