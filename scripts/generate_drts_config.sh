#!/usr/bin/env bash
set -euo pipefail

# Generates configs/drts-config.yml strictly from agreed pipeline env vars.
# Inputs: POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB, POSTGRES_PORT (optional)
#         REDIS_PORT (optional). Hosts assumed 127.0.0.1, dbms fixed.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIGS_DIR="$REPO_ROOT/configs"
TARGET_FILE="$CONFIGS_DIR/drts-config.yml"

mkdir -p "$CONFIGS_DIR"

DBMS_DB="postgresql"
DB_HOST="127.0.0.1"
DB_PORT="${POSTGRES_PORT:-5432}"
DB_NAME="${POSTGRES_DB:-drts_server}"
DB_USER="${POSTGRES_USER:-drts}"
DB_PASSWORD="${POSTGRES_PASSWORD:-change_me}"

CACHE_DBMS="redis"
CACHE_HOST="127.0.0.1"
CACHE_PORT="${REDIS_PORT:-6379}"

cat > "$TARGET_FILE" <<EOF
database:
  dbms: "postgresql"
  password: "$DB_PASSWORD"
  database: "$DB_NAME"
  user: "$DB_USER"
  port: "$DB_PORT"
  host: "$DB_HOST"
cache:
  dbms: "redis"
  host: "$CACHE_HOST"
  port: "$CACHE_PORT"
EOF

echo "[generate] Wrote $TARGET_FILE"


