#!/usr/bin/env bash
set -euo pipefail

CERTMASTER_USER="certmaster"
KEY_NAME="certdeploy_ed25519"
KEY_PATH="/home/$CERTMASTER_USER/.ssh/$KEY_NAME"

echo "=== Setting up certmaster user ==="

# 1. Create user if not exists
if ! id "$CERTMASTER_USER" >/dev/null 2>&1; then
    useradd -m -s /bin/bash "$CERTMASTER_USER"
    echo "[OK] User $CERTMASTER_USER created"
else
    echo "[SKIP] User $CERTMASTER_USER exists"
fi

# 2. Ensure .ssh directory
SSH_DIR="/home/$CERTMASTER_USER/.ssh"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
chown "$CERTMASTER_USER:$CERTMASTER_USER" "$SSH_DIR"

# 3. Generate key if not exists
if [ ! -f "$KEY_PATH" ]; then
    sudo -u "$CERTMASTER_USER" ssh-keygen -t ed25519 \
        -f "$KEY_PATH" \
        -C "cert-deploy-key" \
        -N ""
    echo "[OK] SSH key generated"
else
    echo "[SKIP] SSH key already exists"
fi

# 4. Fix permissions
chmod 600 "$KEY_PATH"
chmod 644 "$KEY_PATH.pub"
chown "$CERTMASTER_USER:$CERTMASTER_USER" "$KEY_PATH" "$KEY_PATH.pub"

echo "=== CERTMASTER PUBLIC KEY ==="
cat "$KEY_PATH.pub"
echo "=== Copy this public key to each node ==="
