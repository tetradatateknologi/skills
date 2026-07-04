#!/usr/bin/env bash
# Production pull-only deploy script.
# Pulls images from GHCR, switches to maintenance, migrates, and recreates services.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [ "$#" -lt 6 ]; then
  echo "Usage: $0 <API_TAG> <WEB_TAG> <GHCR_PULL_TOKEN> <GITHUB_ACTOR> <GITHUB_SHA> <DOCKER_IMAGE_PREFIX>" >&2
  exit 1
fi

export {{APP_NAME_UPPERCASE}}_API_TAG="$1"
export {{APP_NAME_UPPERCASE}}_WEB_TAG="$2"
GHCR_PULL_TOKEN="$3"
GITHUB_ACTOR="$4"
GITHUB_SHA="$5"
export DOCKER_IMAGE_PREFIX="$6"

# Set target images for docker-compose.yml substitution
export {{APP_NAME_UPPERCASE}}_API_IMAGE="ghcr.io/${DOCKER_IMAGE_PREFIX}/{{APP_NAME}}-api:${{{APP_NAME_UPPERCASE}}_API_TAG}"
export {{APP_NAME_UPPERCASE}}_WEB_IMAGE="ghcr.io/${DOCKER_IMAGE_PREFIX}/{{APP_NAME}}-web:${{{APP_NAME_UPPERCASE}}_WEB_TAG}"
export POSTGRES_PORT_BINDING="127.0.0.1:5432:5432" # Keep DB local-only in production

on_err() {
  echo "" >&2
  echo "==> Deploy failed. Showing api logs for troubleshooting:" >&2
  docker compose logs --tail=100 api || true
  echo "" >&2
  echo "    To recover manually:" >&2
  echo "      docker compose up -d api worker web" >&2
}

trap on_err ERR

log() {
  echo "==> $*"
}

log "Logging in to GHCR..."
echo "${GHCR_PULL_TOKEN}" | docker login ghcr.io -u "${GITHUB_ACTOR}" --password-stdin

log "Pulling new images from GHCR (app services stay online)..."
docker compose pull api worker web

log "Updating api and worker (runs migrations on startup)..."
docker compose up -d --force-recreate api worker

log "Waiting for api to be healthy..."
deadline=$((SECONDS + 300))
until docker compose ps api | grep -q "healthy"; do
  if (( SECONDS >= deadline )); then
    echo "Timed out waiting for api to become healthy" >&2
    exit 1
  fi
  sleep 3
done

log "Updating web..."
docker compose up -d --force-recreate web

web_port="${WEB_HOST_PORT:-{{WEB_HOST_PORT}}}"
web_port="${web_port##*:}"
log "Waiting for web on port ${web_port}..."
deadline=$((SECONDS + 120))
until curl -fsS -o /dev/null "http://127.0.0.1:${web_port}/"; do
  if (( SECONDS >= deadline )); then
    echo "Timed out waiting for web on port ${web_port}" >&2
    exit 1
  fi
  sleep 2
done

log "Saving deploy state to .deploy-state..."
cat <<EOF > .deploy-state
{{APP_NAME_UPPERCASE}}_API_TAG=${{{APP_NAME_UPPERCASE}}_API_TAG}
{{APP_NAME_UPPERCASE}}_WEB_TAG=${{{APP_NAME_UPPERCASE}}_WEB_TAG}
DOCKER_IMAGE_PREFIX=${DOCKER_IMAGE_PREFIX}
DEPLOYED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
GITHUB_SHA=${GITHUB_SHA}
EOF

log "Cleaning up old Docker images..."
docker image prune -f --filter "until=72h"

trap - ERR
log "Deploy complete successfully."
