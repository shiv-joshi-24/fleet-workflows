# fleet-workflows

GitHub Actions workflow templates for Agent Fleet.
Add autonomous AI agents to any project in one command.

---

## What this is

A template repo containing:
- A GitHub Actions workflow that triggers on issue labels, PRs, and schedule
- Project config template (`.fleet.yml`)
- Agent instructions template (`CLAUDE.md`)
- Setup scripts for VPS and GitHub labels

When you label a GitHub issue `claude:run`, the workflow SSHes into your VPS,
runs the Claude Code CLI on your project, and posts results back as comments.

---

## Prerequisites

- Agent Fleet running on a VPS ([setup guide](docs/vps-setup.md))
- GitHub Secrets configured (`VPS_SSH_KEY`, `VPS_HOST`, `VPS_USER`, `FLEET_DIR`)
- GitHub CLI installed locally (`brew install gh`)

---

## Add fleet to a project

Run this from inside your project directory:

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_ORG/fleet-workflows/main/scripts/install.sh | bash
```

This adds three files to your project:
- `.github/workflows/fleet-trigger.yml` — the workflow
- `.fleet.yml` — project config (edit this)
- `CLAUDE.md` — agent instructions (edit this)

Then commit and push:

```bash
git add .github/workflows/fleet-trigger.yml .fleet.yml CLAUDE.md
git commit -m "chore: add Agent Fleet workflow"
git push
```

---

## Using fleet

### Create an issue and add a label

| Label | Agent | Use when |
|-------|-------|----------|
| `claude:run` | auto | You're not sure which agent to use |
| `claude:junior` | Junior | Simple tasks, boilerplate, quick fixes |
| `claude:senior` | Senior | Feature work, refactoring, code review |
| `claude:expert` | Expert | Security, architecture, complex decisions |
| `claude:pipeline` | All three | High-stakes features needing full review |
| `claude:review` | Senior | PR review (use on issues describing a PR) |
| `claude:priority` | — | Bump task to front of queue |

### What happens after labeling

1. GitHub Actions fires within seconds
2. Comment posted: "🤖 Task received"
3. VPS picks up the task, runs Claude Code CLI in your project directory
4. Comment posted: task ID
5. Every 30 seconds: workflow polls VPS for completion
6. Comment posted: agent output (collapsed)
7. Issue closed automatically on success

### Manual trigger

Go to **Actions → Agent Fleet Trigger → Run workflow** in your repo.
Fill in title, body, agent, and optional pipeline.

### PR trigger

Opening or updating a non-draft PR automatically triggers a Senior code review.
Result posted as a PR comment.

### Nightly maintenance

Every day at 2 AM UTC, a maintenance task runs automatically.
Customise it in `.fleet.yml` under `nightly_task`.

---

## First-time VPS setup

```bash
# On your VPS:
sudo bash scripts/setup-vps-for-github.sh
# Prints private key → add to GitHub Secrets as VPS_SSH_KEY

# Create labels in a repo:
bash scripts/setup-github-labels.sh owner/repo

# Create labels in all repos in an org:
bash scripts/setup-github-labels.sh --all-repos
```

---

## Repo structure

```
fleet-workflows/
├── .github/workflows/
│   └── fleet-trigger.yml        ← copy into any project
├── templates/
│   ├── .fleet.yml               ← project config template
│   └── CLAUDE.md                ← agent instructions template
├── scripts/
│   ├── install.sh               ← one-command project setup
│   ├── setup-vps-for-github.sh  ← VPS SSH preparation
│   ├── setup-github-labels.sh   ← GitHub label creation
│   └── cli-additions.js         ← new CLI commands for fleet
└── docs/
    ├── vps-setup.md
    ├── fleet-yml-reference.md
    └── branch-strategies.md
```

---

## GitHub Secrets

Set once at **org level** (Settings → Secrets → Actions) to apply to all repos.
Or set per-repo under repo Settings → Secrets → Actions.

| Secret | Description |
|--------|-------------|
| `VPS_SSH_KEY` | ED25519 private key for SSH into VPS (from setup script) |
| `VPS_HOST` | VPS IP address or hostname |
| `VPS_USER` | SSH user (`fleet-runner` created by setup script) |
| `FLEET_DIR` | Path to agent-fleet on VPS (e.g. `/home/ubuntu/agent-fleet`) |

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Workflow doesn't trigger | Label must be exactly `claude:run` (lowercase, colon) |
| SSH connection refused | Check `VPS_HOST` and `VPS_USER` secrets |
| Task ID not returned | Supervisor not running — SSH in and check `pm2 status` |
| Poll times out after 30 min | Task still running — check dashboard |
| Issue not closed | Only closes on `complete` — check task output for errors |
| Auto-clone fails | Repo must be public, or add a `GITHUB_TOKEN` with repo read access |

---

## Security

- SSH key is **scope-limited**: the `fleet-runner` user can only run fleet CLI commands, not a shell
- VPS firewall stays fully closed — only outbound SSH from GitHub's IPs needed
- Tokens are single-use and expire
- Private key lives in GitHub Secrets only
