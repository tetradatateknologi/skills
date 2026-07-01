#!/usr/bin/env bash
# Production pull-only deploy script.
# Pulls images from GHCR, switches to maintenance, migrates, and recreates services.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [ "$#" -lt 5 ]; then
  echo "Usage: $0 <API_TAG> <WEB_TAG> <GHCR_PULL_TOKEN> <GITHUB_ACTOR> <GITHUB_SHA>" >&2
  exit 1
fi

export {{APP_NAME_UPPERCASE}}_API_TAG="$1"
export {{APP_NAME_UPPERCASE}}_WEB_TAG="$2"
GHCR_PULL_TOKEN="$3"
GITHUB_ACTOR="$4"
GITHUB_SHA="$5"

on_err() {
  echo "" >&2
  echo "==> Deploy failed. Maintenance page may still be serving on WEB_HOST_PORT." >&2
  echo "    To recover manually:" >&2
  echo "      docker compose --profile maintenance stop maintenance" >&2
  echo "      docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d api worker web" >&2
}

trap on_err ERR

log() {
  echo "==> $*"
}

log "Logging in to GHCR..."
echo "${GHCR_PULL_TOKEN}" | docker login ghcr.io -u "${GITHUB_ACTOR}" --password-stdin

log "Pulling new images from GHCR (app services stay online)..."
docker compose -f docker-compose.yml -f docker-compose.prod.yml pull api worker web

log "Stopping app services (web, api, worker)..."
docker compose stop web api worker

log "Starting maintenance page..."
docker compose --profile maintenance up -d maintenance

log "Running database migrations..."
docker compose -f docker-compose.yml -f docker-compose.prod.yml --profile migrate run --rm migrate

log "Starting api and worker (maintenance still on WEB_HOST_PORT)..."
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --force-recreate api worker

log "Stopping maintenance page..."
docker compose --profile maintenance stop maintenance

log "Starting web..."
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --force-recreate web

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
DEPLOYED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
GITHUB_SHA=${GITHUB_SHA}
EOF

log "Cleaning up old Docker images..."
docker image prune -f --filter "until=72h"

trap - ERR
log "Deploy complete successfully."
