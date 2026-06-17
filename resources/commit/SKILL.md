---
name: commit
description: >-
  Analyze staged and unstaged changes, write conventional commit messages,
  stage relevant files, and create git commits. Use when the user asks to
  commit, create a commit, stage and commit, or write and apply a commit message.
user-invocable: true
---

# Commit

End-to-end git commit workflow: inspect changes, draft a conventional message, stage files, commit, verify.

## When to Run

Run this skill when the user explicitly asks to commit — e.g. "commit", "buat commit", "commit perubahan ini".

**Do not commit** unless the user asked. If intent is unclear, ask first.

## Workflow

### 1. Inspect (run in parallel)

```bash
git status
git diff          # unstaged
git diff --staged # staged
git log -5 --oneline
```

Use `git log` to match the repo's existing commit style.

### 2. Decide scope

- One logical change per commit.
- Do not mix unrelated work (e.g. feature + refactor) in one commit.
- If changes span multiple logical units, either:
  - split into multiple commits (preferred), or
  - ask the user which scope to commit now.
- Never stage files that likely contain secrets (`.env`, credentials, keys).

### 3. Draft the message

```
<type>(<optional scope>): <subject>

<optional body>

<optional footer>
```

**Subject rules:** ≤50 chars, imperative mood, lowercase after prefix, no trailing period.

| Type | When |
|------|------|
| `feat` | New user-facing feature |
| `fix` | Bug fix |
| `refactor` | Restructure without behavior change |
| `docs` | Documentation only |
| `test` | Tests added or updated |
| `chore` | Build, tooling, deps |
| `perf` | Performance improvement |
| `style` | Formatting only (not CSS) |
| `ci` | CI/CD pipeline |
| `revert` | Revert a previous commit |

**Body:** explain *why*, not *what* (the diff shows what).

**Breaking changes:** `feat(api)!: ...` plus `BREAKING CHANGE:` footer with migration notes.

**Footer:** `Closes #123`, `Co-authored-by: Name <email>` when relevant.

### 4. Stage and commit

Stage only files that belong to this logical change:

```bash
git add path/to/file1 path/to/file2
```

Use HEREDOC for multi-line messages:

```bash
git commit -m "$(cat <<'EOF'
feat(auth): add OAuth2 login flow

Users can sign in with Google and GitHub. Session is stored
in httpOnly cookies to reduce XSS risk.

Closes #456
EOF
)"
```

Single-line subject only:

```bash
git commit -m "fix(api): handle null payment response"
```

### 5. Verify

```bash
git status
git log -1 --stat
```

Confirm the commit succeeded and only intended files were included.

## Safety Rules

- **Never** update git config.
- **Never** run destructive commands (`push --force`, `reset --hard`) unless the user explicitly requests them.
- **Never** skip hooks (`--no-verify`, `--no-gpg-sign`) unless the user explicitly requests it.
- **Never** commit when there are no changes.
- **Never** use interactive git (`git add -i`, `git rebase -i`).
- **Do not push** unless the user explicitly asks.

### Amend policy

Use `git commit --amend` only when **all** are true:
1. User explicitly requested amend, **or** commit succeeded but a pre-commit hook auto-modified files
2. HEAD commit was created in this session
3. Commit has **not** been pushed to remote

If a commit **failed** or was **rejected by a hook**, fix the issue and create a **new** commit — do not amend.

## Handling Failures

| Situation | Action |
|-----------|--------|
| Pre-commit hook failed | Read error, fix files, stage fixes, **new** commit |
| Nothing to commit | Report clearly; do not create empty commit |
| Mixed unrelated changes | Split commits or ask user |
| Secrets in diff | Warn user; exclude from staging |

## Examples

Good:
```
feat(dashboard): add real-time notification bell
fix: resolve race condition in WebSocket reconnect
refactor(api): consolidate error handling middleware
test: add integration tests for payment webhook
chore: upgrade TypeScript to 5.4
```

Bad:
```
fixed stuff
WIP
update
changes
asdf
```

## Related Skills

- [`push`](../push/SKILL.md) — commit and push to remote in one step
- [`creating-pr`](../creating-pr/SKILL.md) — after commits are ready on a feature branch
- [`babysit`](../babysit/SKILL.md) — commit fixups during PR CI/review loops
