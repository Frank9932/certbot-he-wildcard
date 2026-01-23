# Certbot + Hurricane Electric Wildcard TLS Automation

This repository deploys:

- Let's Encrypt wildcard certificate (*.example.com)
- DNS-01 validation via Hurricane Electric Dynamic DNS record key
- Certbot running in Docker
- Automatic renewal
- Automatic certificate distribution to multiple nodes
- Automatic service reload

Designed for AlmaLinux / RHEL / Debian / Ubuntu hosts.

---

## Features

- No Hurricane Electric account password stored
- Uses only the record-level Dynamic DNS key
- Idempotent setup script
- Fully unattended renew + deploy
- Docker-isolated certbot environment

---

## Prerequisites

- Certbot host has Docker installed and can reach the internet.
- `certmaster` SSH keypair exists at `/home/certmaster/.ssh/certdeploy_ed25519`.
- Remote nodes allow SSH for user `certdeploy` with that key and have `sudo` for the allowed commands in `access-setup/setup-certdeploy-node.sh`.

## Usage

1. On the certbot host, create the certmaster user and SSH key (keep the public key to distribute).  
   ```bash
   sudo ./access-setup/setup-certmaster-user.sh
   ```
2. On each node, create the `certdeploy` user and install the certmaster public key.  
   ```bash
   sudo ./access-setup/setup-certdeploy-node.sh <domain> "<certmaster_pubkey>"
   ```
3. On each node, prepare the certificate directory (one-time).  
   ```bash
   sudo ./node-deploy/prepare-node.sh <domain>
   ```
4. On the certbot host, prepare environment files from the samples.  
   ```bash
   cp env.certbot.sample env.certbot
   cp env.nodes.sample env.nodes
   # Also prepare .env for setup.sh (contains DOMAIN_NAME/ADMIN_EMAIL/HE_DDNS_* etc.)
   cp env.example .env
   ```
5. On the certbot host, run the main setup (starts container, issues cert, installs renewal cron).  
   ```bash
   ./setup.sh
   ```
6. Test the deploy script (pushes certs from the container to all nodes).  
   ```bash
   docker exec certbot-he /bin/bash /node-deploy/node-deploy.sh
   ```
7. Automatic renewals: certbot runs with `--deploy-hook /deploy-hook.sh`, which triggers the same distribution script after each renewal.
