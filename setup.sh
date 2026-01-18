#!/usr/bin/env bash
set -euo pipefail

if [ ! -f .env ]; then
  echo "Missing .env file. Copy env.example to .env and edit it."
  exit 1
fi
source .env

CERTBOT_DATA_DIR="${CERTBOT_DATA_DIR:-./certbot-data}"
DEPLOY_HOOK_SCRIPT="${DEPLOY_HOOK_SCRIPT:-./hooks/deploy-certs.sh}"

echo "== Domain: $DOMAIN_NAME =="

# --- Prepare directories ---
mkdir -p "$CERTBOT_DATA_DIR/letsencrypt"

# --- Create HE credentials file ---
INI="$CERTBOT_DATA_DIR/dns_he_ddns.ini"
if [ ! -f "$INI" ]; then
cat > "$INI" <<EOF
dns_he_ddns_record = $HE_DDNS_RECORD
dns_he_ddns_key = $HE_DDNS_KEY
EOF
chmod 600 "$INI"
echo "[OK] dns_he_ddns.ini created"
else
echo "[SKIP] dns_he_ddns.ini exists"
fi

# --- Start container ---
if ! docker ps --format '{{.Names}}' | grep -q '^certbot-he$'; then
  docker compose up -d
  echo "[OK] certbot container started"
else
  echo "[SKIP] certbot container already running"
fi

# --- Ensure plugin installed ---
if ! docker exec certbot-he pip show certbot-dns-he-ddns >/dev/null 2>&1; then
  docker exec certbot-he pip install certbot-dns-he-ddns
  echo "[OK] Plugin installed"
else
  echo "[SKIP] Plugin already installed"
fi

# --- Issue certificate if missing ---
LIVE="$CERTBOT_DATA_DIR/letsencrypt/live/$DOMAIN_NAME/fullchain.pem"
if [ ! -f "$LIVE" ]; then
  docker exec certbot-he certbot certonly \
    --authenticator dns-he-ddns \
    --dns-he-ddns-credentials /dns_he_ddns.ini \
    -d "$DOMAIN_NAME" -d "*.$DOMAIN_NAME" \
    --agree-tos --non-interactive -m "$ADMIN_EMAIL"
  echo "[OK] Certificate issued"
else
  echo "[SKIP] Certificate already exists"
fi

# --- Test deploy hook once ---
echo "[OK] Running deploy hook placeholder"
docker exec certbot-he /deploy-certs.sh

# --- Setup auto-renew cron ---
CRON_LINE="$RENEW_CRON_TIME docker exec certbot-he certbot renew --deploy-hook /deploy-certs.sh >> /var/log/certbot-renew.log 2>&1"

# Get existing crontab safely even if empty
EXISTING_CRON="$(crontab -l 2>/dev/null || true)"

if ! echo "$EXISTING_CRON" | grep -Fq "$CRON_LINE"; then
  ( echo "$EXISTING_CRON"; echo "$CRON_LINE" ) | crontab -
  echo "[OK] Auto-renew cron installed"
else
  echo "[SKIP] Auto-renew cron already present"
fi

echo "==== CERTBOT BASELINE SETUP COMPLETE ===="
echo "Certificates will auto-renew. Deployment hook ready for future extension."
