#!/usr/bin/env bash
# =============================================================================
# setup-vps-for-github.sh
# Run ONCE on your VPS to prepare it for GitHub Actions SSH dispatch.
#
# Usage:
#   sudo bash setup-vps-for-github.sh
#
# What it does:
#   1. Creates a locked-down deploy user (fleet-runner)
#   2. Generates an ED25519 SSH keypair
#   3. Installs the public key with a forced command (CLI-only access)
#   4. Prints the private key to add to GitHub Secrets
#   5. Runs a self-test
# =============================================================================

set -euo pipefail

FLEET_USER="${FLEET_USER:-fleet-runner}"
FLEET_DIR="${FLEET_DIR:-/home/$(logname 2>/dev/null || echo ubuntu)/agent-fleet}"

GRN='\033[0;32m'; YLW='\033[1;33m'; RED='\033[0;31m'; BLD='\033[1m'; NC='\033[0m'
ok()   { echo -e "${GRN}✓${NC} $1"; }
warn() { echo -e "${YLW}!${NC} $1"; }
err()  { echo -e "${RED}✗${NC} $1"; exit 1; }
hdr()  { echo -e "\n${BLD}$1${NC}"; }

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║       Agent Fleet — VPS GitHub SSH Setup             ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# ── Validate ──────────────────────────────────────────────────────────────────
[ "$(id -u)" -eq 0 ] || err "Run with sudo"

if [ ! -d "$FLEET_DIR" ]; then
  warn "Fleet dir not found: $FLEET_DIR"
  read -rp "  Enter fleet directory path: " FLEET_DIR
  [ -d "$FLEET_DIR" ] || err "Directory does not exist: $FLEET_DIR"
fi
ok "Fleet directory: $FLEET_DIR"

# ── Generate SSH keypair ──────────────────────────────────────────────────────
hdr "Generating SSH keypair"
KEY_DIR="/tmp/fleet-ssh-$$"
mkdir -p "$KEY_DIR"
KEY_FILE="$KEY_DIR/fleet_deploy_key"

ssh-keygen -t ed25519 -C "github-actions-fleet" -f "$KEY_FILE" -N "" -q
ok "ED25519 keypair generated"

PUBKEY=$(cat "${KEY_FILE}.pub")

# ── Create deploy user ────────────────────────────────────────────────────────
hdr "Creating deploy user: $FLEET_USER"
if ! id "$FLEET_USER" &>/dev/null; then
  useradd --system --create-home --shell /bin/bash "$FLEET_USER" 2>/dev/null || \
  adduser --disabled-password --gecos "" "$FLEET_USER" 2>/dev/null
  ok "User created: $FLEET_USER"
else
  warn "User already exists: $FLEET_USER"
fi

USER_HOME=$(getent passwd "$FLEET_USER" | cut -d: -f6)
mkdir -p "$USER_HOME/.ssh"
chmod 700 "$USER_HOME/.ssh"

# ── Install authorized_keys with forced command ───────────────────────────────
hdr "Installing authorized key (CLI-only, no shell access)"

# The forced command means this key can ONLY run fleet CLI commands
FORCED="command=\"cd ${FLEET_DIR} && exec node cli.js \$SSH_ORIGINAL_COMMAND\",no-agent-forwarding,no-port-forwarding,no-X11-forwarding,no-pty"
AUTH_KEYS="$USER_HOME/.ssh/authorized_keys"

# Remove any stale entry then add fresh
grep -v "github-actions-fleet" "$AUTH_KEYS" 2>/dev/null > /tmp/ak_clean || touch /tmp/ak_clean
echo "${FORCED} ${PUBKEY}" >> /tmp/ak_clean
mv /tmp/ak_clean "$AUTH_KEYS"
chmod 600 "$AUTH_KEYS"
chown -R "$FLEET_USER:$FLEET_USER" "$USER_HOME/.ssh"
ok "authorized_keys installed with forced command"

# ── Sudoers (optional — for pm2 restarts) ────────────────────────────────────
SUDOERS_FILE="/etc/sudoers.d/fleet-runner"
NODE_PATH=$(command -v node || echo "/usr/local/bin/node")
PM2_PATH=$(command -v pm2 || echo "/usr/local/bin/pm2")
echo "${FLEET_USER} ALL=(ALL) NOPASSWD: ${NODE_PATH}, ${PM2_PATH}" > "$SUDOERS_FILE"
chmod 440 "$SUDOERS_FILE"
ok "Sudoers entry created"

# ── Fleet directory access ────────────────────────────────────────────────────
FLEET_OWNER=$(stat -c '%U' "$FLEET_DIR")
FLEET_GROUP=$(stat -c '%G' "$FLEET_DIR")
if [ "$FLEET_OWNER" != "$FLEET_USER" ]; then
  usermod -aG "$FLEET_GROUP" "$FLEET_USER" 2>/dev/null || true
  chmod -R g+rX "$FLEET_DIR"
fi
# Allow writing to data/ and logs/ for the fleet user
chmod -R g+w "$FLEET_DIR/data" 2>/dev/null || mkdir -p "$FLEET_DIR/data" && chown "$FLEET_USER" "$FLEET_DIR/data"
chmod -R g+w "$FLEET_DIR/logs" 2>/dev/null || mkdir -p "$FLEET_DIR/logs" && chown "$FLEET_USER" "$FLEET_DIR/logs"
ok "Directory access configured"

# ── Print private key ─────────────────────────────────────────────────────────
VPS_IP=$(curl -s --max-time 5 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  PRIVATE KEY — Add to GitHub Secrets as VPS_SSH_KEY         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
cat "$KEY_FILE"
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  GitHub Secrets to set (repo or org level)                  ║"
echo "╠══════════════════════════════════════════════════════════════╣"
printf "║  %-16s  %-40s  ║\n" "Secret" "Value"
echo "╠══════════════════════════════════════════════════════════════╣"
printf "║  %-16s  %-40s  ║\n" "VPS_SSH_KEY"  "(private key above)"
printf "║  %-16s  %-40s  ║\n" "VPS_HOST"     "$VPS_IP"
printf "║  %-16s  %-40s  ║\n" "VPS_USER"     "$FLEET_USER"
printf "║  %-16s  %-40s  ║\n" "FLEET_DIR"    "$FLEET_DIR"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# ── Self-test ─────────────────────────────────────────────────────────────────
hdr "Self-test"
if su - "$FLEET_USER" -s /bin/bash -c "cd $FLEET_DIR && node cli.js status" &>/dev/null; then
  ok "Fleet CLI accessible as $FLEET_USER"
else
  warn "CLI test failed. Start the supervisor first: pm2 start pm2.config.cjs"
fi

# Save keypair for reference
cp "$KEY_FILE" "/root/fleet_deploy_key.pem" 2>/dev/null || true
cp "${KEY_FILE}.pub" "/root/fleet_deploy_key.pub" 2>/dev/null || true
echo ""
ok "Keys saved to /root/fleet_deploy_key.pem (private) and .pub (public)"
rm -rf "$KEY_DIR"
echo ""
