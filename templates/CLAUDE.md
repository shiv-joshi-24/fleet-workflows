# Agent Fleet — Project Instructions

This file is read by Claude Code CLI at the start of every task in this project.
Customise it to reflect your project's standards and conventions.

---

## Project Context

<!-- Describe your project briefly -->
This is a [Node.js / Python / React / etc.] project that does [brief description].

**Tech stack:**
- Runtime: [Node.js 20 / Python 3.11 / etc.]
- Framework: [Express / FastAPI / Next.js / etc.]
- Database: [PostgreSQL / SQLite / MongoDB / etc.]
- Testing: [Jest / Pytest / Vitest / etc.]

---

## Coding Standards

- Follow existing code style — match surrounding code, not personal preference
- Always handle errors explicitly — no silent catches
- Add JSDoc / docstring comments to any new functions
- Keep functions small and focused — one responsibility each
- Never use `any` in TypeScript without a comment explaining why

---

## What You Must Always Do

- Run `{{ test_command }}` after making any changes
- If tests fail, fix them before marking the task complete
- Check for linting errors: `{{ lint_command }}`
- Read existing code in the affected area before writing new code
- Keep changes minimal and focused — don't refactor unrelated code

---

## What You Must Never Do

- Modify `.env`, `.env.*`, or any secrets files
- Change database migration files without explicit instruction
- Push or commit directly — the branch strategy handles this
- Install new dependencies without mentioning it in your output
- Delete files without being explicitly asked to

---

## Branch Strategy

Follow the `branch_strategy` set in `.fleet.yml`:

**new-branch (default):**
- Create a branch: `fleet/issue-{number}-{short-description}`
- Make your changes
- Stage and commit with a conventional commit message: `feat:`, `fix:`, `chore:`
- Do NOT push or open a PR — the workflow handles that

**report-only:**
- Analyse and describe what you would do
- Show code snippets but do not write files
- End with a clear summary of recommended changes

**work-on-main:**
- Work directly, commit when done
- Do NOT push — the workflow handles that

---

## Output Format

End every task response with this block so the orchestrator can parse it:

```
TASK_STATUS: complete | needs_review | failed
CONFIDENCE: high | medium | low
FILES_CHANGED: comma-separated list or "none"
TESTS: pass | fail | skipped
NEEDS_HUMAN: yes | no
REASON: one sentence explaining the outcome
```

---

## When to Set NEEDS_HUMAN: yes

- Changes touch authentication, payments, or security-critical code
- You're uncertain about the correct approach
- The task requires information not available in the codebase
- Tests are failing after two fix attempts
- More than 15 files would be affected
