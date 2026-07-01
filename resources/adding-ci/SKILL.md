---
name: adding-ci
description: Add GitHub Actions CI (PR validation). Use when the user asks for CI, continuous integration, GitHub Actions, or testing/linting pipelines.
---

# Add CI (GitHub Actions)

Use this skill when the user asks to set up CI, continuous integration, or PR validation using GitHub Actions.

**Default layout:** A single workflow file `.github/workflows/ci.yml` that validates code on Pull Requests (PRs). No repository secrets should be required, keeping it fork-friendly.

## 1. Detect project structure

Inspect the repo before writing workflows:

| Signal | Stack | CI steps |
|--------|-------|----------|
| `go.mod` | Go | `go test ./...`, `go build` |
| `package.json` + lockfile | Node.js | `npm ci`, lint/typecheck/test/build (use what exists) |
| `requirements.txt` / `pyproject.toml` | Python | install, lint, test |
| Multiple top-level apps | Monorepo | one job per service, `working-directory` + `cache-dependency-path` |

Check existing scripts in `package.json` (`lint`, `typecheck`, `test`, `build`) — only run scripts that exist. Add `"typecheck": "tsc --noEmit"` if TypeScript but no script.

## 2. Create `.github/workflows/ci.yml`

**Triggers:** `pull_request` to `main` only — not `push`. No repository secrets required.

**Concurrency:** cancel in-progress runs for the same PR.

```yaml
# CI: validate on every pull request targeting main.
# No repository secrets required (public fork–friendly).
name: CI

on:
  pull_request:
    branches:
      - main

concurrency:
  group: ci-${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: true
```

### Single-package Node.js

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    timeout-minutes: 20
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-node@v6
        with:
          node-version: "22"
          cache: npm
      - run: npm ci
      - run: npm run lint
      - run: npm run typecheck
      - run: npm test
      - run: npm run build
```

Use `npm ci` (not `npm install`). Run lint, typecheck, test, and build in parallel jobs if the pipeline is slow.

### Single-package Go

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-go@v6
        with:
          go-version: "1.22"
          cache-dependency-path: go.sum
      - run: go test ./...
      - run: go build -o /tmp/app ./cmd/api
```

Adjust `go-version` and build path to match the project.

### Monorepo (one job per service)

Each service gets its own job with `working-directory` and scoped cache:

```yaml
jobs:
  api:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-go@v6
        with:
          go-version: "1.22"
          cache-dependency-path: api/go.sum
      - working-directory: api
        run: |
          go test ./...
          go build -o /tmp/api ./cmd/api

  web:
    runs-on: ubuntu-latest
    timeout-minutes: 20
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-node@v6
        with:
          node-version: "22"
          cache: npm
          cache-dependency-path: web/package-lock.json
      - working-directory: web
        run: npm ci
      - working-directory: web
        run: npm run lint && npm test && npm run build

  worker:
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-node@v6
        with:
          node-version: "22"
          cache: npm
          cache-dependency-path: worker/package-lock.json
      - working-directory: worker
        run: npm ci
      - working-directory: worker
        run: node --check src/server.js
```

For small Node scripts without a test suite, `node --check` is enough.

### Optional: matrix testing

Add only when the user needs multiple Node or Go versions:

```yaml
strategy:
  matrix:
    node-version: [20, 22]
```

## 3. Workflow conventions

Apply these consistently:

| Concern | CI |
|---------|----|
| Trigger | `pull_request` → `main` |
| Secrets | None |
| Concurrency | cancel in-progress |
| Timeout | 10–20 min per job |
| Action versions | `checkout@v6`, `setup-node@v6`, `setup-go@v6` |

**Monorepo caching:** always set `cache-dependency-path` to the service's lockfile (`web/package-lock.json`, `api/go.sum`).

**Turborepo:** add remote caching or `actions/cache` for `.turbo` if used.

## 4. Add status badge (optional)

```markdown
![CI](https://github.com/OWNER/REPO/actions/workflows/ci.yml/badge.svg)
```

Replace `OWNER/REPO` with the actual repository.

## Checklist before finishing

- [ ] CI runs on PR only
- [ ] Each monorepo service has its own job with correct `working-directory`
- [ ] No secrets required or committed to workflow files
- [ ] Timeouts set on jobs
