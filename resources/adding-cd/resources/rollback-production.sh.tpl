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
DEPLOYED_AT=$(grep -E "^DEPLOYED_AT=" "$STATE_FILE" | cut -d'=' -f2-)
GITHUB_SHA=$(grep -E "^GITHUB_SHA=" "$STATE_FILE" | cut -d'=' -f2-)

if [ -z "${{{APP_NAME_UPPERCASE}}_API_TAG}" ] || [ -z "${{{APP_NAME_UPPERCASE}}_WEB_TAG}" ]; then
  echo "Error: Missing {{APP_NAME_UPPERCASE}}_API_TAG or {{APP_NAME_UPPERCASE}}_WEB_TAG in $STATE_FILE." >&2
  exit 1
fi

log "Found state:"
log "  API Version: ${{{APP_NAME_UPPERCASE}}_API_TAG}"
log "  Web Version: ${{{APP_NAME_UPPERCASE}}_WEB_TAG}"
log "  Deployed At: ${DEPLOYED_AT}"
log "  Git Commit:  ${GITHUB_SHA}"

export {{APP_NAME_UPPERCASE}}_API_TAG
export {{APP_NAME_UPPERCASE}}_WEB_TAG

on_err() {
  echo "" >&2
  echo "==> Rollback failed." >&2
}
trap on_err ERR

log "Pulling target rollback images..."
docker compose -f docker-compose.yml -f docker-compose.prod.yml pull api worker web

log "Stopping current services..."
docker compose stop web api worker

log "Recreating services with target tags..."
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --no-build api worker web

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
