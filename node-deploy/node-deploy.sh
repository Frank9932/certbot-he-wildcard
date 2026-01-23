#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

load_env_file() {
  local label="$1"; shift
  for candidate in "$@"; do
    if [ -f "$candidate" ]; then
      echo "[DEPLOY] Loading $label from $candidate"
      # shellcheck source=/dev/null
      . "$candidate"
      return
    fi
  done
  echo "[ERROR] Missing $label (checked: $*)"
  exit 1
}

load_env_file "env.certbot" /env.certbot "$ROOT_DIR/env.certbot"
load_env_file "env.nodes" /env.nodes "$ROOT_DIR/env.nodes"

: "${DOMAIN_NAME:?DOMAIN_NAME is required}"
: "${REMOTE_HOSTS:?REMOTE_HOSTS is required}"
: "${REMOTE_CERT_BASE:?REMOTE_CERT_BASE is required}"

CERT_SRC="/etc/letsencrypt/live/$DOMAIN_NAME"
CERT_KEY="/home/certmaster/.ssh/certdeploy_ed25519"
REMOTE_CERT_DIR="$REMOTE_CERT_BASE/$DOMAIN_NAME"

if [ ! -d "$CERT_SRC" ]; then
  echo "[ERROR] Certificate path missing: $CERT_SRC"
  exit 1
fi

if [ ! -f "$CERT_KEY" ]; then
  echo "[ERROR] SSH key missing: $CERT_KEY"
  exit 1
fi

ssh_target() {
  local port="$1"
  local host="$2"
  shift 2
  ssh -i "$CERT_KEY" -p "$port" certdeploy@"$host" "$@"
}

echo "[DEPLOY] Using certificate from $CERT_SRC"
echo "[DEPLOY] Target base: $REMOTE_CERT_DIR"

for entry in $REMOTE_HOSTS; do
  IFS=':' read -r HOST PORT <<<"$entry"
  HOST="${HOST:-}"
  PORT="${PORT:-22}"

  if [ -z "$HOST" ]; then
    echo "[WARN] Skipping empty host entry: $entry"
    continue
  fi

  echo "[DEPLOY] -> $HOST:$PORT"

  ssh_target "$PORT" "$HOST" sudo mkdir -p "$REMOTE_CERT_DIR"
  ssh_target "$PORT" "$HOST" sudo chown root:certdeploy "$REMOTE_CERT_DIR"
  ssh_target "$PORT" "$HOST" sudo chmod 750 "$REMOTE_CERT_DIR"

  rsync -av \
    --rsync-path="sudo rsync" \
    -e "ssh -i $CERT_KEY -p $PORT" \
    "$CERT_SRC/fullchain.pem" "$CERT_SRC/privkey.pem" \
    certdeploy@"$HOST":"$REMOTE_CERT_DIR/"

  ssh_target "$PORT" "$HOST" sudo chown root:certdeploy "$REMOTE_CERT_DIR/fullchain.pem" "$REMOTE_CERT_DIR/privkey.pem"
  ssh_target "$PORT" "$HOST" sudo chmod 640 "$REMOTE_CERT_DIR/fullchain.pem" "$REMOTE_CERT_DIR/privkey.pem"

  if [ -n "${REMOTE_SYSTEMD_SERVICE:-}" ]; then
    echo "[DEPLOY] Reloading systemd service: $REMOTE_SYSTEMD_SERVICE"
    ssh_target "$PORT" "$HOST" "sudo systemctl reload \"$REMOTE_SYSTEMD_SERVICE\" || sudo systemctl restart \"$REMOTE_SYSTEMD_SERVICE\""
  fi

  if [ -n "${REMOTE_DOCKER_CONTAINER:-}" ]; then
    echo "[DEPLOY] Restarting docker container: $REMOTE_DOCKER_CONTAINER"
    ssh_target "$PORT" "$HOST" sudo docker restart "$REMOTE_DOCKER_CONTAINER"
  fi

  echo "[DEPLOY] Host $HOST done."
done

echo "[DEPLOY] Distribution finished."
