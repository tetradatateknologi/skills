---
name: upgrade-version
description: >-
  Bump api/VERSION and web/VERSION based on changed files and conversation
  context. Syncs web/package.json when web version changes. Use when the user
  invokes /upgrade-version, asks to bump or update version, or says upgrade
  version after making api/ or web/ changes.
user-invocable: true
---

# Upgrade Version

mengupdate ini sesuai dengan contextnya: `api/VERSION` dan `web/VERSION`.

## When to Run

Run when the user invokes `/upgrade-version` or asks to bump/update app version after work in this monorepo.

**Do not bump** unless the user asked or invoked this skill.

## Version Files

| File | Current role | Also update |
|------|--------------|-------------|
| `api/VERSION` | Docker tag for `one-api` (`deploy.yml`) | — |
| `web/VERSION` | UI version (`VITE_APP_VERSION`), Docker tag for `one-web` | `web/package.json` `"version"` |

Format: semver `X.Y.Z` on a single line, no extra text. Match `.github/workflows/bump-version.yml`.

## Workflow

### 1. Gather context (parallel)

```bash
cat api/VERSION
cat web/VERSION
git status
git diff --name-only
git diff --cached --name-only
```

If comparing against main:

```bash
git diff --name-only main...HEAD
git diff --name-only main
```

Combine **uncommitted**, **staged**, and **recent branch** changes. Use conversation context when the user names what changed.

### 2. Decide what to bump

Exclude paths ending in `/VERSION` from change detection (same as CI).

| Changed paths | Bump |
|---------------|------|
| Under `api/` (not only `api/VERSION`) | `api/VERSION` |
| Under `web/` (not only `web/VERSION`) | `web/VERSION` + `web/package.json` |
| Both areas | Both |
| Only root/docs/infra, no `api/` or `web/` | Ask user or skip — do not guess |
| Only `*/VERSION` or version-only edits | Skip unless user explicitly set a target version |

If the user names a bump level or exact version, follow that instead of auto-detect.

### 3. Choose bump level

Default: **patch** (increment `Z` in `X.Y.Z`) — same as `bump-version.yml`.

| User intent / change type | Bump |
|---------------------------|------|
| Bug fix, small feature, routine change | patch |
| New feature, notable API/UI behavior | minor (`Y+1`, reset `Z=0`) |
| Breaking change | major (`X+1`, reset `Y=0`, `Z=0`) |
| Exact version given (e.g. `2.1.0`) | Set that value |

Validate result matches `^[0-9]+\.[0-9]+\.[0-9]+$`.

### 4. Apply updates

**api/VERSION** — write new semver only:

```
1.0.29
→
1.0.30
```

**web/VERSION** — same, then sync package.json:

```bash
WEB_VER=$(tr -d '[:space:]' < web/VERSION)
(cd web && npm pkg set "version=$WEB_VER")
```

Or edit `web/package.json` `"version"` to match `web/VERSION` exactly.

Do not edit `vite.config.ts`, `vitest.config.ts`, or deploy workflows — they already read `VERSION` at build time.

### 5. Verify

```bash
cat api/VERSION
cat web/VERSION
node -p "require('./web/package.json').version"
```

Confirm:
- Both VERSION files are valid semver
- `web/package.json` version equals `web/VERSION` when web was bumped
- Only intended files changed

### 6. Report

Summarize in one line per component:

```
one-api  1.0.29 → 1.0.30
one-web  2.0.1 → 2.0.2 (web/package.json synced)
```

Mention if nothing was bumped and why.

## Examples

**After fixing a bug in `api/internal/...`**

- Bump `api/VERSION` patch only.

**After UI work in `web/src/...`**

- Bump `web/VERSION` patch and sync `web/package.json`.

**Full-stack PR touching `api/` and `web/`**

- Bump both VERSION files (patch each) and sync `web/package.json`.

**User: `/upgrade-version minor for web`** 

- Bump `web/VERSION` minor; sync `web/package.json`; leave `api/VERSION` unless api changes exist.

## Safety

- Minimize scope — only touch VERSION files and `web/package.json` when web bumps.
- Do not commit unless the user asks (use [`commit`](../commit/SKILL.md) or [`push`](../push/SKILL.md)).
- Do not bump version for changes confined to `.github/`, `docs/`, or repo root unless the user requests it.

## Related

- `.github/workflows/bump-version.yml` — CI auto-bump on merge (patch, directory-based)
- `.github/workflows/deploy.yml` — reads VERSION for image tags
