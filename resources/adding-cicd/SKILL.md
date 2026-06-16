---
name: adding-cicd
description: Add GitHub Actions CI (PR validation) and deploy (SSH + Docker, or platform deploy). Use when the user asks for CI, CD, continuous integration, GitHub Actions, deploy pipeline, or production deployment.
---

# Add CI/CD (GitHub Actions)

Use this skill when the user asks to set up CI, continuous integration, deployment, or GitHub Actions.

**Default layout:** two workflows — `ci.yml` (validate on PRs) and `deploy.yml` (deploy on push to `main`). Keep them separate so CI needs no secrets and stays fork-friendly.

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

## 3. Create `.github/workflows/deploy.yml`

**Triggers:** `push` to `main` only.

**Concurrency:** one deploy at a time; do not cancel in-progress deploys.

Choose deploy target based on project:

| Target | When |
|--------|------|
| **SSH + Docker** (default for VPS/self-hosted) | Server has git clone + `docker-compose.yml` |
| **Vercel / Netlify / Fly** | Serverless or platform-managed hosting |

### SSH + Docker deploy (preferred for VPS)

Add a header comment documenting required secrets and variables:

```yaml
# Deploy: SSH to the production host, update main, run migrations, rebuild containers.
#
# Required repository secrets (Settings → Secrets and variables → Actions):
#   SSH_HOST         — server hostname or IP
#   SSH_USER         — SSH login user (must be able to run git + docker: typically `docker` group or equivalent)
#   SSH_PRIVATE_KEY  — private key for that user (PEM, no passphrase recommended for CI; protect key scope)
# Optional:
#   SSH_PORT         — if not 22, set this
#   SSH_FINGERPRINT  — pins the server host key (like a known_hosts entry); SHA256; see:
#     ssh-keygen -lf <(ssh-keyscan -t ed25519,rsa "$SSH_HOST" 2>/dev/null) or your host's panel
# Optional repository variable (Settings → Variables):
#   DEPLOY_PATH      — app root on server (default in workflow: /home/user/app) — must contain git clone + docker-compose.yml
#
# The server's clone must be able to `git fetch` from GitHub (deploy key, HTTPS credential, etc.).
# Skip deploy for commits that only exist to align with bump-version automation ([ci] message prefix on push).

name: Deploy

on:
  push:
    branches:
      - main

concurrency:
  group: deploy-main
  cancel-in-progress: false

jobs:
  deploy:
    if: ${{ !startsWith(github.event.head_commit.message || '', '[ci]') }}
    runs-on: ubuntu-latest
    timeout-minutes: 30
    steps:
      - name: Run remote deploy
        uses: appleboy/ssh-action@v1.2.1
        with:
          host: ${{ secrets.SSH_HOST }}
          username: ${{ secrets.SSH_USER }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          port: ${{ secrets.SSH_PORT && secrets.SSH_PORT || 22 }}
          fingerprint: ${{ secrets.SSH_FINGERPRINT }}
          command_timeout: 25m
          script: |
            set -euo pipefail
            DEPLOY_DIR='${{ vars.DEPLOY_PATH != '' && vars.DEPLOY_PATH || '/home/user/app' }}'
            cd "$DEPLOY_DIR"
            git fetch origin
            git reset --hard origin/main
            docker compose --profile migrate run --rm migrate
            docker compose up -d --build
```

Adapt the remote script to the project:

- **No migrations:** drop the `docker compose --profile migrate` line.
- **Plain Docker (no compose):** replace with `docker build` + `docker run` or project-specific commands.
- **Default `DEPLOY_PATH`:** set to the user's actual server path.

Server prerequisites the user must have in place:

1. Git clone of the repo at `DEPLOY_PATH`
2. SSH user in `docker` group (or equivalent)
3. GitHub access from server (deploy key or credential)
4. `docker-compose.yml` (and migrate profile if used)

### Platform deploy (Vercel example)

Use when the app is hosted on a platform, not a VPS:

```yaml
jobs:
  deploy:
    needs: []  # or gate behind a CI job if combined
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-node@v6
        with:
          node-version: "22"
          cache: npm
      - run: npm ci && npm run build
      - run: npx vercel deploy --prod --token=${{ secrets.VERCEL_TOKEN }}
```

Store `VERCEL_TOKEN` (and similar) in repository secrets — never in the workflow file.

## 4. Workflow conventions

Apply these consistently:

| Concern | CI | Deploy |
|---------|----|--------|
| Trigger | `pull_request` → `main` | `push` → `main` |
| Secrets | None | SSH or platform tokens |
| Concurrency | cancel in-progress | one at a time, no cancel |
| Timeout | 10–20 min per job | 30 min job, 25 min SSH command |
| Action versions | `checkout@v6`, `setup-node@v6`, `setup-go@v6` | `appleboy/ssh-action@v1.2.1` |

**Skip deploy for automation commits:** use `if: ${{ !startsWith(github.event.head_commit.message || '', '[ci]') }}` when bump-version or similar bots push to `main`.

**Monorepo caching:** always set `cache-dependency-path` to the service's lockfile (`web/package-lock.json`, `api/go.sum`).

**Turborepo:** add remote caching or `actions/cache` for `.turbo` if used.

## 5. Add status badge (optional)

```markdown
![CI](https://github.com/OWNER/REPO/actions/workflows/ci.yml/badge.svg)
```

Replace `OWNER/REPO` with the actual repository.

## Checklist before finishing

- [ ] CI runs on PR only; deploy runs on push to `main` only
- [ ] Each monorepo service has its own job with correct `working-directory`
- [ ] Deploy workflow header documents all required secrets/variables
- [ ] Remote deploy script matches server's layout (compose profile, path, migrate step)
- [ ] No secrets committed to workflow files
- [ ] Timeouts set on jobs (and `command_timeout` for SSH)
