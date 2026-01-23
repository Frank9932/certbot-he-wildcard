#!/bin/sh
# This hook is called by certbot after successful renewal

echo "[HOOK] Certbot renewal completed. Triggering node deployment..."

/bin/bash ./node-deploy/node-deploy.sh
