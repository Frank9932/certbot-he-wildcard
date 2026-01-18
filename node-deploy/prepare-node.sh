#!/bin/sh
# prepare-node.sh
# Run locally on each node once.
# Requires root privileges.

set -e

DOMAIN_NAME="$1"
REMOTE_CERT_BASE="/etc/ssl/certs-by-domain"

if [ -z "$DOMAIN_NAME" ]; then
  echo "Usage: sudo ./prepare-node.sh <domain>"
  exit 1
fi

TARGET="$REMOTE_CERT_BASE/$DOMAIN_NAME"

echo "Preparing certificate directory:"
echo "  $TARGET"

# Create directory
mkdir -p "$TARGET"

# Secure permissions
chown root:root "$TARGET"
chmod 700 "$TARGET"

echo "Directory ready:"
ls -ld "$TARGET"

echo "Node preparation complete."
