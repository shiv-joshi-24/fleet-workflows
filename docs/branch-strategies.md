# Branch Strategies

How Agent Fleet handles file changes in your project.

---

## new-branch (recommended)

Claude creates a branch per task, makes changes, and commits.
You review the branch and merge manually (or the HITL system can open a PR).

**Branch naming:** `fleet/issue-{number}-{short-slug}`  
**Example:** `fleet/issue-42-add-rate-limiting`

**Good for:**
- Any shared or production codebase
- When you want a review gate before changes land
- Teams

**CLAUDE.md instructions Claude follows:**
```
Create branch: fleet/issue-{issue_number}-{short-description}
Make your changes, stage files, commit with conventional message.
Do NOT push or open a PR.
```

---

## report-only

Claude analyses the codebase and describes what it would do, but never
writes any files. Output is posted as an issue comment.

**Good for:**
- Security audits
- Architecture reviews
- Any repo where you want advice, not automation
- First time using fleet on an existing codebase

**CLAUDE.md instructions:**
```
Do NOT write or modify any files.
Analyse and describe what you would do.
Show code snippets inline but do not apply them.
End with a clear summary and recommendation.
```

---

## work-on-main

Claude commits directly to whatever branch is currently checked out.

**Good for:**
- Personal projects
- Throwaway repos
- When you trust the agent completely

**Not recommended for:**
- Shared repos
- Anything in production
- Repos with protected branches

---

## Choosing a strategy

| Situation | Strategy |
|-----------|----------|
| Production app, team | `new-branch` |
| Personal project | `work-on-main` |
| Code review / audit | `report-only` |
| First run on new codebase | `report-only` → then `new-branch` |
| Security-sensitive code | `report-only` always |
