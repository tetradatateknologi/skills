services:
  postgres:
    ports: !reset []
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 1024M

  redis:
    ports: !reset []
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 256M

  api:
    image: ghcr.io/{{DOCKER_IMAGE_PREFIX}}/{{APP_NAME}}-api:${{{APP_NAME_UPPERCASE}}_API_TAG}
    build: !reset null
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:8080/health"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 5s
    deploy:
      resources:
        limits:
          memory: 512M

  worker:
    image: ghcr.io/{{DOCKER_IMAGE_PREFIX}}/{{APP_NAME}}-api:${{{APP_NAME_UPPERCASE}}_API_TAG}
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:${WORKER_PORT:-8081}/"]
      interval: 10s
      timeout: 5s
      retries: 3
      start_period: 5s
    deploy:
      resources:
        limits:
          memory: 256M

  web:
    image: ghcr.io/{{DOCKER_IMAGE_PREFIX}}/{{APP_NAME}}-web:${{{APP_NAME_UPPERCASE}}_WEB_TAG}
    build: !reset null
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 128M
