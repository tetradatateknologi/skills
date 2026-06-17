---
name: push
description: >-
  Commit local changes if needed, then push to the remote branch. Follows
  conventional commit rules when committing. Use when the user asks to push,
  commit and push, or sync changes to remote — e.g. "push", "push ke remote",
  "commit dan push".
user-invocable: true
---

# Push

End-to-end workflow: inspect state, commit if there are local changes, push to remote, verify.

## When to Run

Run when the user explicitly asks to push — e.g. "push", "commit and push", "push ke origin", "sync ke remote".

**Do not push** unless the user asked. If intent is unclear, ask first.

## Workflow

### 1. Inspect (run in parallel)

```bash
git status
git diff          # unstaged
git diff --staged # staged
git log -5 --oneline
git rev-parse --abbrev-ref HEAD
git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "no upstream"
```

Use `git log` to match the repo's existing commit style.

### 2. Decide path

| State | Action |
|-------|--------|
| Uncommitted or staged changes | Commit first (steps 3–4), then push (step 5) |
| Clean working tree, branch ahead of remote | Push only (step 5) |
| Clean working tree, up to date with remote | Report: nothing to push |
| No commits yet / detached HEAD | Stop; explain and ask user |

If changes span multiple logical units, split into multiple commits (preferred) or ask which scope to include now.

Never stage files that likely contain secrets (`.env`, credentials, keys).

### 3. Draft the message (only when committing)

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

**Body:** explain *why*, not *what*.

**Breaking changes:** `feat(api)!: ...` plus `BREAKING CHANGE:` footer.

**Footer:** `Closes #123`, `Co-authored-by: Name <email>` when relevant.

For full commit examples and anti-patterns, see [`commit`](../commit/SKILL.md).

### 4. Stage and commit (only when needed)

```bash
git add path/to/file1 path/to/file2
```

Use HEREDOC for multi-line messages:

```bash
git commit -m "$(cat <<'EOF'
feat(auth): add OAuth2 login flow

Users can sign in with Google and GitHub.

Closes #456
EOF
)"
```

Single-line subject only:

```bash
git commit -m "fix(api): handle null payment response"
```

After commit:

```bash
git status
git log -1 --stat
```

### 5. Push

If branch has no upstream, set it on first push:

```bash
git push -u origin HEAD
```

If upstream exists:

```bash
git push
```

### 6. Verify

```bash
git status
git log -1 --oneline
git rev-list --left-right --count @{u}...HEAD 2>/dev/null || true
```

Confirm: working tree clean, branch not ahead of remote, intended commits were pushed.

## Safety Rules

- **Never** update git config.
- **Never** run `push --force` / `push --force-with-lease` unless the user explicitly requests it.
- **Never** skip hooks (`--no-verify`, `--no-gpg-sign`) unless the user explicitly requests it.
- **Never** commit when there are no changes.
- **Never** use interactive git (`git add -i`, `git rebase -i`).
- **Never** push secrets — warn and exclude from staging if found in diff.

### Amend policy

Same as [`commit`](../commit/SKILL.md): amend only when user requested it (or hook auto-modified files), HEAD was created this session, and commit has **not** been pushed. If push already happened, do not amend without explicit user request.

## Handling Failures

| Situation | Action |
|-----------|--------|
| Pre-commit hook failed | Fix files, stage, **new** commit, then push |
| Nothing to commit and nothing ahead | Report clearly |
| Push rejected (non-fast-forward) | Explain; suggest `git pull --rebase` or merge — do not force push unless asked |
| No upstream / wrong remote | Use `git push -u origin HEAD` or ask user which remote/branch |
| Mixed unrelated changes | Split commits or ask user |
| Secrets in diff | Warn user; exclude from staging |

## Related Skills

- [`commit`](../commit/SKILL.md) — commit only, no push
- [`creating-pr`](../creating-pr/SKILL.md) — after branch is pushed
- [`babysit`](../babysit/SKILL.md) — push fixups during PR loops
