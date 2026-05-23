#!/usr/bin/env bash
# =============================================================================
# setup-github-labels.sh
# Creates Agent Fleet labels in a GitHub repository.
#
# Requirements: GitHub CLI — https://cli.github.com
#   brew install gh && gh auth login
#
# Usage:
#   bash setup-github-labels.sh                  # current repo
#   bash setup-github-labels.sh owner/repo       # specific repo
#   bash setup-github-labels.sh --all-repos      # all repos in current org
# =============================================================================

set -euo pipefail

GRN='\033[0;32m'; YLW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "${GRN}✓${NC} $1"; }
warn() { echo -e "${YLW}!${NC} $1"; }

command -v gh &>/dev/null || { echo "GitHub CLI not found. Install: https://cli.github.com"; exit 1; }
gh auth status &>/dev/null || { echo "Not authenticated. Run: gh auth login"; exit 1; }

create_labels() {
  local repo="$1"
  echo "  $repo"

  gh label create "claude:run"      --color "22c55e" --description "Auto-route to best agent"            --repo "$repo" --force 2>/dev/null && echo "    ✓ claude:run"      || true
  gh label create "claude:junior"   --color "4ade80" --description "Assign to Junior Dev agent"          --repo "$repo" --force 2>/dev/null && echo "    ✓ claude:junior"   || true
  gh label create "claude:senior"   --color "60a5fa" --description "Assign to Senior Dev agent"          --repo "$repo" --force 2>/dev/null && echo "    ✓ claude:senior"   || true
  gh label create "claude:expert"   --color "f472b6" --description "Assign to Expert Architect agent"    --repo "$repo" --force 2>/dev/null && echo "    ✓ claude:expert"   || true
  gh label create "claude:pipeline" --color "a78bfa" --description "Junior → Senior → Expert pipeline"   --repo "$repo" --force 2>/dev/null && echo "    ✓ claude:pipeline" || true
  gh label create "claude:review"   --color "93c5fd" --description "Code review by Senior agent"         --repo "$repo" --force 2>/dev/null && echo "    ✓ claude:review"   || true
  gh label create "claude:priority" --color "ef4444" --description "High priority — processed first"     --repo "$repo" --force 2>/dev/null && echo "    ✓ claude:priority" || true
  gh label create "fleet:done"      --color "dcfce7" --description "Task completed by Agent Fleet"       --repo "$repo" --force 2>/dev/null && echo "    ✓ fleet:done"      || true
  gh label create "fleet:failed"    --color "fee2e2" --description "Task failed — needs human review"    --repo "$repo" --force 2>/dev/null && echo "    ✓ fleet:failed"    || true
}

echo ""
echo "Agent Fleet — GitHub Label Setup"
echo "─────────────────────────────────"
echo ""

if [ "${1:-}" = "--all-repos" ]; then
  ORG=$(gh repo view --json owner -q .owner.login 2>/dev/null || gh org list | head -1)
  echo "Creating labels in all repos for org: $ORG"
  echo ""
  gh repo list "$ORG" --limit 100 --json nameWithOwner -q '.[].nameWithOwner' | while read -r repo; do
    create_labels "$repo"
  done
else
  REPO="${1:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}"
  [ -n "$REPO" ] || { echo "Usage: bash setup-github-labels.sh [owner/repo]"; exit 1; }
  echo "Creating labels in: $REPO"
  echo ""
  create_labels "$REPO"
fi

echo ""
ok "Done."
echo ""
echo "Label usage:"
echo "  claude:run      → auto-route to best agent"
echo "  claude:junior   → Junior Dev (fast, simple tasks)"
echo "  claude:senior   → Senior Dev (feature work, reviews)"
echo "  claude:expert   → Expert Architect (security, architecture)"
echo "  claude:pipeline → Full 3-agent pipeline"
echo "  claude:review   → Code review on PR description"
echo "  claude:priority → Jump the queue"
echo ""
