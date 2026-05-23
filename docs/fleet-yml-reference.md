# .fleet.yml Reference

Full reference for every field in the `.fleet.yml` project config file.

---

## workdir

```yaml
workdir: ~/projects/my-project
```

Where on the VPS this project lives. Supports `~` for home directory.
The workflow auto-clones your repo here if the directory doesn't exist.
If omitted, defaults to `~/projects/<repo-name>`.

---

## branch_strategy

```yaml
branch_strategy: new-branch   # default
```

How the agent handles file changes:

| Value | Behaviour |
|-------|-----------|
| `new-branch` | Creates `fleet/issue-{n}-{slug}`, commits changes, does not push |
| `report-only` | Analyses and describes changes, never writes files |
| `work-on-main` | Commits directly to current branch |

Recommended: `new-branch` for any shared or production codebase.

---

## base_branch

```yaml
base_branch: main
```

Branch to create task branches from. Default: `main`.

---

## agents

```yaml
agents:
  default: senior
  security: expert
  frontend: junior
  architecture: expert
```

Override auto-routing for specific task types. Keywords are matched against
the issue title and body. Supported keys: `default`, `security`, `frontend`,
`architecture`, `testing`, `documentation`, `performance`, `database`.

---

## test_command / lint_command / build_command

```yaml
test_command: npm test
lint_command: npm run lint
build_command: npm run build
```

Commands Claude runs after making changes. Injected into CLAUDE.md context.
Auto-detected from project files if omitted (package.json, pyproject.toml, etc).

---

## auto_close_issues

```yaml
auto_close_issues: true   # default
```

Whether to close the GitHub issue automatically when a task completes.
Set to `false` if you want to review before closing.

---

## notify_on

```yaml
notify_on:
  - complete
  - failed
```

Which events trigger ntfy push notification to your phone.
Options: `complete`, `failed`, `cancelled`, `started`.

---

## nightly_task

```yaml
nightly_task: |
  Run the following checks:
  1. npm audit
  2. Verify tests pass
  3. Summarise findings
```

Custom instructions for the nightly scheduled task.
If omitted, a default maintenance task runs.

---

## project_context

```yaml
project_context: |
  Tech stack: Node.js, Express, PostgreSQL
  Code style: ESLint + Prettier
  Never modify: .env files, migrations
```

Extra context injected into every task for this project.
Use this to describe conventions, restrictions, and tech stack.
Claude reads this before starting any task.

---

## Full example

```yaml
workdir: ~/projects/my-saas-app
branch_strategy: new-branch
base_branch: develop

agents:
  default: senior
  security: expert
  frontend: junior

test_command: npm test
lint_command: npm run lint
build_command: npm run build

auto_close_issues: true

notify_on:
  - complete
  - failed

nightly_task: |
  1. npm audit — flag high/critical only
  2. npm test — report results
  3. Check recent commits for TODO/FIXME

project_context: |
  Stack: Next.js 14, Prisma, PostgreSQL, Tailwind
  Auth: NextAuth.js — never modify src/auth/ without explicit instruction
  Tests: Vitest + Testing Library
  Branch naming: feat/*, fix/*, chore/*
  Deploy: Vercel — changes to vercel.json need review
```
