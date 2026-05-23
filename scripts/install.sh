#!/usr/bin/env bash
# =============================================================================
# install.sh — Add Agent Fleet to any project in one command
#
# Usage (run from inside your project directory):
#   curl -fsSL https://raw.githubusercontent.com/YOUR_ORG/fleet-workflows/main/scripts/install.sh | bash
#
# Or locally:
#   bash /path/to/fleet-workflows/scripts/install.sh
#
# What it does:
#   1. Creates .github/workflows/fleet-trigger.yml
#   2. Creates .fleet.yml (project config)
#   3. Creates CLAUDE.md (agent instructions)
#   4. Creates GitHub labels (if gh CLI available)
#   5. Prints the secrets you need to add
# =============================================================================

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
WORKFLOWS_REPO="${FLEET_WORKFLOWS_REPO:-https://raw.githubusercontent.com/shiv-joshi-24/fleet-workflows/main}"
GRN='\033[0;32m'; YLW='\033[1;33m'; CYN='\033[0;36m'; NC='\033[0m'; BLD='\033[1m'

ok()   { echo -e "${GRN}✓${NC} $1"; }
info() { echo -e "${CYN}→${NC} $1"; }
warn() { echo -e "${YLW}!${NC} $1"; }
hdr()  { echo -e "\n${BLD}$1${NC}"; echo "$(echo "$1" | sed 's/./-/g')"; }

# ── Detect project root ───────────────────────────────────────────────────────
if [ ! -d ".git" ] && [ ! -f "package.json" ] && [ ! -f "pyproject.toml" ]; then
  warn "Not in a project directory. cd into your project first."
  exit 1
fi

PROJECT_NAME=$(basename "$(pwd)")

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║          Agent Fleet — Project Setup                 ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
info "Setting up fleet for: ${PROJECT_NAME}"
echo ""

# ── 1. Create workflow directory ──────────────────────────────────────────────
hdr "1. Workflow file"
mkdir -p .github/workflows

if [ -f ".github/workflows/fleet-trigger.yml" ]; then
  warn "Workflow file already exists — skipping (delete it first to reinstall)"
else
  if command -v curl &>/dev/null; then
    curl -fsSL "${WORKFLOWS_REPO}/.github/workflows/fleet-trigger.yml" \
      -o .github/workflows/fleet-trigger.yml
  else
    # Fallback: copy from local if running locally
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    cp "${SCRIPT_DIR}/../.github/workflows/fleet-trigger.yml" \
       .github/workflows/fleet-trigger.yml
  fi
  ok "Created .github/workflows/fleet-trigger.yml"
fi

# ── 2. Create .fleet.yml ──────────────────────────────────────────────────────
hdr "2. Project config (.fleet.yml)"

if [ -f ".fleet.yml" ]; then
  warn ".fleet.yml already exists — skipping"
else
  # Detect tech stack for sensible defaults
  TEST_CMD="npm test"
  LINT_CMD="npm run lint"
  BUILD_CMD="npm run build"
  STACK="Node.js"

  if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
    TEST_CMD="pytest"
    LINT_CMD="ruff check ."
    BUILD_CMD="python -m build"
    STACK="Python"
  elif [ -f "go.mod" ]; then
    TEST_CMD="go test ./..."
    LINT_CMD="golangci-lint run"
    BUILD_CMD="go build ./..."
    STACK="Go"
  elif [ -f "Cargo.toml" ]; then
    TEST_CMD="cargo test"
    LINT_CMD="cargo clippy"
    BUILD_CMD="cargo build"
    STACK="Rust"
  fi

  cat > .fleet.yml << FLEETYML
# .fleet.yml — Agent Fleet project configuration
# See: https://github.com/YOUR_ORG/fleet-workflows/docs/fleet-yml-reference.md

workdir: ~/projects/${PROJECT_NAME}
branch_strategy: new-branch
base_branch: main

agents:
  default: senior
  security: expert
  frontend: junior
  architecture: expert

test_command: ${TEST_CMD}
lint_command: ${LINT_CMD}
build_command: ${BUILD_CMD}

auto_close_issues: true

notify_on:
  - complete
  - failed

project_context: |
  Tech stack: ${STACK}
  Project: ${PROJECT_NAME}
  # Add more context about your project here
FLEETYML

  ok "Created .fleet.yml (stack detected: ${STACK})"
fi

# ── 3. Create CLAUDE.md ───────────────────────────────────────────────────────
hdr "3. Agent instructions (CLAUDE.md)"

if [ -f "CLAUDE.md" ]; then
  warn "CLAUDE.md already exists — skipping"
else
  if command -v curl &>/dev/null; then
    curl -fsSL "${WORKFLOWS_REPO}/templates/CLAUDE.md" -o CLAUDE.md
  else
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    cp "${SCRIPT_DIR}/../templates/CLAUDE.md" CLAUDE.md
  fi
  ok "Created CLAUDE.md"
  info "Edit CLAUDE.md to describe your project's conventions"
fi

# ── 4. GitHub labels ──────────────────────────────────────────────────────────
hdr "4. GitHub labels"

if command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1; then
  REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")
  if [ -n "$REPO" ]; then
    create_label() {
      gh label create "$1" --color "$2" --description "$3" \
        --repo "$REPO" --force &>/dev/null && echo -e "  ${GRN}✓${NC} $1" || true
    }
    create_label "claude:run"      "22c55e" "Auto-route to best agent"
    create_label "claude:junior"   "4ade80" "Assign to Junior Dev"
    create_label "claude:senior"   "60a5fa" "Assign to Senior Dev"
    create_label "claude:expert"   "f472b6" "Assign to Expert Architect"
    create_label "claude:pipeline" "a78bfa" "Full Junior→Senior→Expert pipeline"
    create_label "claude:review"   "93c5fd" "Code review by Senior"
    create_label "claude:priority" "ef4444" "High priority task"
    ok "Labels created in ${REPO}"
  else
    warn "Not in a GitHub repo — run setup-github-labels.sh manually"
  fi
else
  warn "GitHub CLI not found or not authenticated"
  info "Run scripts/setup-github-labels.sh after installing gh CLI"
fi

# ── 5. Print secrets checklist ────────────────────────────────────────────────
hdr "5. GitHub Secrets required"

echo ""
echo "  Add these to your repo → Settings → Secrets → Actions:"
echo ""
echo "  ┌─────────────────────────────────────────────────────────┐"
echo "  │  Secret name    │  Value                                │"
echo "  ├─────────────────────────────────────────────────────────┤"
echo "  │  VPS_SSH_KEY    │  Private key from setup-vps script    │"
echo "  │  VPS_HOST       │  Your VPS IP address                  │"
echo "  │  VPS_USER       │  fleet-runner                         │"
echo "  │  FLEET_DIR      │  /home/ubuntu/agent-fleet             │"
echo "  └─────────────────────────────────────────────────────────┘"
echo ""
echo "  If all your repos are in one org, set these as Organisation"
echo "  secrets once — they'll be available to all repos automatically."
echo ""

# ── 6. Git status ─────────────────────────────────────────────────────────────
hdr "6. Next steps"

echo ""
echo "  Files added:"
echo "    .github/workflows/fleet-trigger.yml"
echo "    .fleet.yml"
echo "    CLAUDE.md"
echo ""
echo "  1. Edit .fleet.yml → set workdir to match your VPS project path"
echo "  2. Edit CLAUDE.md  → describe your project's tech stack and conventions"
echo "  3. Commit and push:"
echo ""
echo "     git add .github/workflows/fleet-trigger.yml .fleet.yml CLAUDE.md"
echo "     git commit -m 'chore: add Agent Fleet workflow'"
echo "     git push"
echo ""
echo "  4. Create a GitHub issue, add label 'claude:run', watch it run"
echo ""
ok "Setup complete for ${PROJECT_NAME}"
echo ""
