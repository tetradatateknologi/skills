---
name: adding-cd
description: Setup a Zero-Downtime Docker-Compose deployment flow with GitHub Actions, maintenance mode, database migrations, and rollback support on a new project.
user-invocable: true
---

# Add CD (Zero-Downtime Deployment)

Use this skill to quickly install a production-ready, zero-downtime deployment flow using Docker Compose, GitHub Actions, a custom VPS maintenance page, database migrations, and rollback scripts.

## Workflow

### 1. Collect Project Information
Before copying the templates, ask the user or analyze the codebase to determine:
- **APP_NAME**: Name of the application (e.g., `one`, `my-app`).
- **DOCKER_IMAGE_PREFIX**: Docker repository owner downcased (e.g., `tetradatateknologi`, `my-github-username`).
- **WEB_HOST_PORT**: The port exposed on the host VPS for the Web service (default: `3000`).
- **DEPLOY_PATH**: The deployment path on the VPS (default: `/home/apps/{{APP_NAME}}`).
- **DATABASE_NAME**: Name of the Postgres database (default: `{{APP_NAME}}`).
- **DATABASE_USER**: Name of the Postgres user (default: `{{APP_NAME}}`).

### 2. Copy and Parametrize Templates
For each template in `resources/`, copy it to the target path in the user's workspace, replace the placeholders `{{VARIABLE}}` with the collected values, and remove the `.tpl` suffix:

| Source Template | Target Workspace File | Description |
|-----------------|-----------------------|-------------|
| `resources/deploy.yml.tpl` | `.github/workflows/deploy.yml` | GitHub Actions workflow for building parallel images and triggering SSH deploy. |
| `resources/deploy-production.sh.tpl` | `scripts/deploy-production.sh` | Main pull-only deployment script. Must be marked executable (`chmod +x`). |
| `resources/rollback-production.sh.tpl` | `scripts/rollback-production.sh` | Rollback script based on `.deploy-state`. Must be marked executable. |
| `resources/nginx.conf.tpl` | `web/nginx.conf` | Web Nginx configuration acting as reverse proxy for `/api/v1/`. |

### 3. Update Existing Configuration Files
Update the project's existing `docker-compose.yml` file to be production-ready and support dynamic deployments:
- Add dynamic image tags using environment variables with fallback defaults:
  - `image: ${WMS_API_IMAGE:-{{APP_NAME}}-api:latest}`
  - `image: ${WMS_WEB_IMAGE:-{{APP_NAME}}-web:latest}`
- Bind ports dynamically:
  - `ports: - "${POSTGRES_PORT_BINDING:-5432:5432}"` (keep database local-only in production by setting to 127.0.0.1:5432:5432)
  - `ports: - "${WEB_PORT_BINDING:-3000:3000}"`
- Add persistent volumes for database data to avoid data loss:
  - Add `postgres-data:/var/lib/postgresql/data` under the postgres service volumes.
  - Define `postgres-data:` in the top-level `volumes` block.
- Change the dependency condition of the web container on the API container from `service_healthy` to `service_started` to prevent deadlock startup blocks.
- Ensure the following version files are present:
  - `api/VERSION` (contains initial version, e.g., `1.0.0`)
  - `web/VERSION` (contains initial version, e.g., `1.0.0`)

### 4. Provide Instructions for GitHub Secrets
After installing the files, instruct the user to configure the following in their GitHub Repository settings:
- **Secrets (Settings -> Secrets and variables -> Actions -> Repository secrets)**:
  - `SSH_HOST`: IP address or domain name of the production VPS.
  - `SSH_USER`: The SSH user allowed to run Docker commands (must be in the `docker` group).
  - `SSH_PRIVATE_KEY`: The PEM-formatted private key.
  - `SSH_FINGERPRINT`: SHA256 host key fingerprint (e.g., from `ssh-keyscan`).
  - `GHCR_PULL_TOKEN`: A GitHub Personal Access Token (PAT) with `read:packages` permissions.
- **Variables (Settings -> Secrets and variables -> Actions -> Repository variables)**:
  - `DEPLOY_PATH`: Target path on the server (e.g., `/home/apps/{{APP_NAME}}`).
  - `VITE_APP_NAME`: Branding name for build-time compilation.
