name: Deploy

on:
  workflow_dispatch:

concurrency:
  group: deploy-{{APP_NAME}}
  cancel-in-progress: false

jobs:
  build-api:
    if: ${{ !startsWith(github.event.head_commit.message || '', '[ci]') }}
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    outputs:
      version: ${{ steps.ver.outputs.version }}
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Get API Version
        id: ver
        run: |
          version=$(tr -d '[:space:]' < api/VERSION)
          echo "version=${version}" >> "$GITHUB_OUTPUT"

      - name: Downcase owner name
        id: repo
        run: |
          owner=$(echo "${{ github.repository_owner }}" | tr '[:upper:]' '[:lower:]')
          echo "owner=${owner}" >> "$GITHUB_OUTPUT"

      - name: Build and Push API Image
        uses: docker/build-push-action@v6
        with:
          context: ./api
          file: ./api/Dockerfile
          push: true
          tags: |
            ghcr.io/${{ steps.repo.outputs.owner }}/{{APP_NAME}}-api:${{ steps.ver.outputs.version }}
            ghcr.io/${{ steps.repo.outputs.owner }}/{{APP_NAME}}-api:sha-${{ github.sha }}
            ghcr.io/${{ steps.repo.outputs.owner }}/{{APP_NAME}}-api:main
          cache-from: type=gha
          cache-to: type=gha,mode=max

  build-web:
    if: ${{ !startsWith(github.event.head_commit.message || '', '[ci]') }}
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    outputs:
      version: ${{ steps.ver.outputs.version }}
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Set up QEMU
        uses: docker/setup-qemu-action@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Get Web Version
        id: ver
        run: |
          version=$(tr -d '[:space:]' < web/VERSION)
          echo "version=${version}" >> "$GITHUB_OUTPUT"

      - name: Downcase owner name
        id: repo
        run: |
          owner=$(echo "${{ github.repository_owner }}" | tr '[:upper:]' '[:lower:]')
          echo "owner=${owner}" >> "$GITHUB_OUTPUT"

      - name: Build and Push Web Image
        uses: docker/build-push-action@v6
        with:
          context: ./web
          file: ./web/Dockerfile
          push: true
          build-args: |
            VITE_USE_REAL_API=true
            VITE_API_BASE_URL=/api/v1
            VITE_APP_NAME=${{ vars.VITE_APP_NAME || '{{APP_NAME}}' }}
            VITE_APP_VERSION=${{ steps.ver.outputs.version }}
          tags: |
            ghcr.io/${{ steps.repo.outputs.owner }}/{{APP_NAME}}-web:${{ steps.ver.outputs.version }}
            ghcr.io/${{ steps.repo.outputs.owner }}/{{APP_NAME}}-web:sha-${{ github.sha }}
            ghcr.io/${{ steps.repo.outputs.owner }}/{{APP_NAME}}-web:main
          cache-from: type=gha
          cache-to: type=gha,mode=max

  deploy:
    needs: [build-api, build-web]
    runs-on: ubuntu-latest
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
            DEPLOY_DIR='${{ vars.DEPLOY_PATH != '' && vars.DEPLOY_PATH || '{{DEPLOY_PATH}}' }}'
            cd "$DEPLOY_DIR"
            git fetch origin
            git reset --hard origin/main
            owner=$(echo "${{ github.repository_owner }}" | tr '[:upper:]' '[:lower:]')
            ./scripts/deploy-production.sh "${{ needs.build-api.outputs.version }}" "${{ needs.build-web.outputs.version }}" "${{ secrets.GHCR_PULL_TOKEN }}" "${{ github.actor }}" "${{ github.sha }}" "$owner"
