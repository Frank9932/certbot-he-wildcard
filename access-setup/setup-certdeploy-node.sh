#!/usr/bin/env bash
set -euo pipefail

CERTDEPLOY_USER="certdeploy"
REMOTE_CERT_BASE="/etc/ssl/certs-by-domain"
DOMAIN_NAME="$1"
CERTMASTER_PUBKEY="$2"

if [ -z "$DOMAIN_NAME" ] || [ -z "$CERTMASTER_PUBKEY" ]; then
    echo "Usage: sudo ./setup-certdeploy-node.sh <domain> '<certmaster_public_key>'"
    exit 1
fi

echo "=== Setting up certdeploy on node ==="

# 1. Create user if not exists
if ! id "$CERTDEPLOY_USER" >/dev/null 2>&1; then
    useradd -r -m -s /sbin/nologin "$CERTDEPLOY_USER"
    echo "[OK] User $CERTDEPLOY_USER created"
else
    echo "[SKIP] User $CERTDEPLOY_USER exists"
fi

# 2. Setup SSH directory
HOME_DIR="/home/$CERTDEPLOY_USER"
SSH_DIR="$HOME_DIR/.ssh"
AUTH_KEYS="$SSH_DIR/authorized_keys"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
touch "$AUTH_KEYS"
chmod 600 "$AUTH_KEYS"
chown -R "$CERTDEPLOY_USER:$CERTDEPLOY_USER" "$SSH_DIR"

# 3. Install public key if not present
if ! grep -Fq "$CERTMASTER_PUBKEY" "$AUTH_KEYS"; then
    echo "$CERTMASTER_PUBKEY" >> "$AUTH_KEYS"
    echo "[OK] Public key installed"
else
    echo "[SKIP] Public key already present"
fi

# 4. Configure sudo rules
SUDO_FILE="/etc/sudoers.d/certdeploy"
if [ ! -f "$SUDO_FILE" ]; then
cat > "$SUDO_FILE" <<EOF
certdeploy ALL=(root) NOPASSWD: \
/bin/mkdir, \
/bin/chmod, \
/usr/bin/rsync, \
/bin/systemctl reload gost, \
/bin/systemctl restart gost, \
/usr/bin/docker restart gost
EOF
chmod 440 "$SUDO_FILE"
echo "[OK] Sudo rules created"
else
echo "[SKIP] Sudo rules already exist"
fi

# 5. Create certificate directory
TARGET="$REMOTE_CERT_BASE/$DOMAIN_NAME"
mkdir -p "$TARGET"
chown root:"$CERTDEPLOY_USER" "$TARGET"
chmod 750 "$TARGET"

echo "[OK] Certificate directory prepared: $TARGET"

echo "=== Node setup complete ==="

