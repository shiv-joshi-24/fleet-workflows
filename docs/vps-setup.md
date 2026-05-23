# VPS Setup Guide

Complete guide to preparing your VPS for Agent Fleet GitHub trigger workflows.

---

## Prerequisites

A fresh Ubuntu 22.04 or 24.04 VPS. Minimum spec: 1 vCPU, 1GB RAM.
Recommended: Hetzner CX22 (2 vCPU, 4GB, €4/mo).

---

## Step 1 — Install Agent Fleet

```bash
# Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs git

# Claude Code CLI
npm install -g @anthropic-ai/claude-code

# Log in with your Pro/Max account (one time)
claude login

# PM2 process manager
npm install -g pm2

# Clone and start fleet
git clone https://github.com/YOUR_ORG/agent-fleet.git ~/agent-fleet
cd ~/agent-fleet
npm install
cp .env.example .env
nano .env    # add NTFY_TOPIC etc.
mkdir -p logs data

pm2 start pm2.config.cjs
pm2 save
pm2 startup   # follow the printed command
```

---

## Step 2 — Add CLI commands

Copy the three cases from `scripts/cli-additions.js` into your `cli.js`:
- `add-raw`
- `pipeline-raw`
- `task-json`

Or use `cli-additions.js` as a standalone script by adding it to your fleet directory.

---

## Step 3 — Run the VPS setup script

```bash
sudo bash ~/fleet-workflows/scripts/setup-vps-for-github.sh
```

This creates a `fleet-runner` user with a locked-down SSH key.
Copy the printed private key — you need it for GitHub Secrets.

---

## Step 4 — Add GitHub Secrets

In each repo (or at org level for all repos):

**Settings → Secrets and variables → Actions → New repository secret**

| Secret | Value |
|--------|-------|
| `VPS_SSH_KEY` | Private key from step 3 |
| `VPS_HOST` | Your VPS IP |
| `VPS_USER` | `fleet-runner` |
| `FLEET_DIR` | `/home/ubuntu/agent-fleet` |

**Tip:** Set these as Organisation secrets if all your repos are in one org.
Then you never touch secrets again when adding a new project.

---

## Step 5 — Keep Claude session alive

```bash
# Add to crontab (crontab -e):
0 8 * * * claude -p "ping" --print >> /tmp/claude-keepalive.log 2>&1
```

---

## Firewall recommendations

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh          # your SSH access
sudo ufw enable
```

Port 3100 (supervisor) and 3101 (triggers) stay closed to the internet.
GitHub Actions accesses the VPS via SSH only — no open ports needed.
