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
- Only record-level Dynamic DNS key used
- Idempotent setup script
- Fully unattended renew + deploy
- Docker-isolated certbot environment

---

## 1. Configure environment

Copy:

```bash
cp env.example .env
nano .env

## 2. Run setup
