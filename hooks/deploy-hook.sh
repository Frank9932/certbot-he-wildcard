#!/bin/sh
set -e
echo "[HOOK] Certbot renewal completed. Triggering node deployment..."
/bin/bash /node-deploy/node-deploy.sh
