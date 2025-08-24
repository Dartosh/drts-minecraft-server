#!/usr/bin/env bash
set -euo pipefail

# Required env: REMOTE_APP_DIR, MINECRAFT_DIR, POSTGRES_USER, POSTGRES_DB, POSTGRES_PASSWORD
# Optional: REDIS_PASSWORD

echo "[remote_deploy] Starting..."

REMOTE_APP_DIR="${REMOTE_APP_DIR:-/opt/minecraft/app}"
MINECRAFT_DIR="${MINECRAFT_DIR:-/opt/minecraft/server}"
POSTGRES_USER="${POSTGRES_USER:-minecraft}"
POSTGRES_DB="${POSTGRES_DB:-minecraft}"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is required}"
REDIS_PASSWORD="${REDIS_PASSWORD:-}"

DATA_DIR="${REMOTE_APP_DIR}/data"
PG_DATA_DIR="${DATA_DIR}/postgres"
REDIS_DATA_DIR="${DATA_DIR}/redis"
DOCKER_NETWORK="minecraft_net"

mkdir -p "$PG_DATA_DIR" "$REDIS_DATA_DIR" "$MINECRAFT_DIR" "$REMOTE_APP_DIR/configs" "$REMOTE_APP_DIR/plugins" "$REMOTE_APP_DIR/server"

echo "[remote_deploy] Ensuring Docker network ${DOCKER_NETWORK}"
if ! docker network inspect "$DOCKER_NETWORK" >/dev/null 2>&1; then
  docker network create "$DOCKER_NETWORK"
fi

echo "[remote_deploy] Starting PostgreSQL container"
docker rm -f minecraft-postgres >/dev/null 2>&1 || true
docker run -d --name minecraft-postgres \
  --restart unless-stopped \
  -e POSTGRES_USER="$POSTGRES_USER" \
  -e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
  -e POSTGRES_DB="$POSTGRES_DB" \
  -v "$PG_DATA_DIR:/var/lib/postgresql/data" \
  --network "$DOCKER_NETWORK" \
  -p 5432:5432 \
  postgres:15-alpine

echo "[remote_deploy] Starting Redis container"
docker rm -f minecraft-redis >/dev/null 2>&1 || true
if [ -n "$REDIS_PASSWORD" ]; then
  REDIS_ARGS="--requirepass $REDIS_PASSWORD"
else
  REDIS_ARGS=""
fi
docker run -d --name minecraft-redis \
  --restart unless-stopped \
  -v "$REDIS_DATA_DIR:/data" \
  --network "$DOCKER_NETWORK" \
  -p 6379:6379 \
  redis:7-alpine redis-server $REDIS_ARGS

echo "[remote_deploy] Syncing configs and plugins to server directory"

# Copy configs into the server directory (merge)
rsync -av --delete "$REMOTE_APP_DIR/configs/" "$MINECRAFT_DIR/" || true

# Copy plugins jar files into server/plugins
mkdir -p "$MINECRAFT_DIR/plugins"
rsync -av --delete "$REMOTE_APP_DIR/plugins/" "$MINECRAFT_DIR/plugins/" || true

# Copy server jar into place if present
if ls "$REMOTE_APP_DIR/server"/*.jar >/dev/null 2>&1; then
  cp "$REMOTE_APP_DIR/server"/*.jar "$MINECRAFT_DIR/"
fi

echo "[remote_deploy] Done. Ensure your Minecraft server service/process restarts to pick changes."


