#!/usr/bin/env bash
# Production rollback script.
# Reads .deploy-state to find previous tags, pulls them, and recreates services.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

STATE_FILE=".deploy-state"

if [ ! -f "$STATE_FILE" ]; then
  echo "Error: $STATE_FILE not found. Cannot rollback automatically." >&2
  exit 1
fi

log() {
  echo "==> $*"
}

# Source the state file to get variables
log "Reading current deployment state..."
{{APP_NAME_UPPERCASE}}_API_TAG=$(grep -E "^{{APP_NAME_UPPERCASE}}_API_TAG=" "$STATE_FILE" | cut -d'=' -f2-)
{{APP_NAME_UPPERCASE}}_WEB_TAG=$(grep -E "^{{APP_NAME_UPPERCASE}}_WEB_TAG=" "$STATE_FILE" | cut -d'=' -f2-)
DOCKER_IMAGE_PREFIX=$(grep -E "^DOCKER_IMAGE_PREFIX=" "$STATE_FILE" | cut -d'=' -f2-)
DEPLOYED_AT=$(grep -E "^DEPLOYED_AT=" "$STATE_FILE" | cut -d'=' -f2-)
GITHUB_SHA=$(grep -E "^GITHUB_SHA=" "$STATE_FILE" | cut -d'=' -f2-)

if [ -z "${{{APP_NAME_UPPERCASE}}_API_TAG}" ] || [ -z "${{{APP_NAME_UPPERCASE}}_WEB_TAG}" ] || [ -z "${DOCKER_IMAGE_PREFIX}" ]; then
  echo "Error: Missing {{APP_NAME_UPPERCASE}}_API_TAG, {{APP_NAME_UPPERCASE}}_WEB_TAG, or DOCKER_IMAGE_PREFIX in $STATE_FILE." >&2
  exit 1
fi

log "Found state:"
log "  API Version: ${{{APP_NAME_UPPERCASE}}_API_TAG}"
log "  Web Version: ${{{APP_NAME_UPPERCASE}}_WEB_TAG}"
log "  Deployed At: ${DEPLOYED_AT}"
log "  Git Commit:  ${GITHUB_SHA}"

export {{APP_NAME_UPPERCASE}}_API_TAG
export {{APP_NAME_UPPERCASE}}_WEB_TAG
export DOCKER_IMAGE_PREFIX

# Set target images for docker-compose.yml substitution
export {{APP_NAME_UPPERCASE}}_API_IMAGE="ghcr.io/${DOCKER_IMAGE_PREFIX}/{{APP_NAME}}-api:${{{APP_NAME_UPPERCASE}}_API_TAG}"
export {{APP_NAME_UPPERCASE}}_WEB_IMAGE="ghcr.io/${DOCKER_IMAGE_PREFIX}/{{APP_NAME}}-web:${{{APP_NAME_UPPERCASE}}_WEB_TAG}"
export POSTGRES_PORT_BINDING="127.0.0.1:5432:5432" # Keep DB local-only in production

on_err() {
  echo "" >&2
  echo "==> Rollback failed." >&2
}
trap on_err ERR

log "Pulling target rollback images..."
docker compose pull api worker web

log "Updating services with target tags..."
docker compose up -d --no-build api worker web

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

trap - ERR
log "Rollback completed successfully."
