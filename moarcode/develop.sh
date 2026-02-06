#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

PROJECT_NAME=$(basename "$(cd .. && pwd)")
PROJECT_ROOT=$(cd .. && pwd)

echo "Building moarcode-sandbox image..."
docker build -t moarcode-sandbox .

echo "Creating node_modules volume..."
docker volume create "${PROJECT_NAME}-node_modules" >/dev/null 2>&1 || true

mkdir -p .credentials/claude .credentials/codex

echo "Starting container..."
docker run -it --rm \
    --hostname moarcode \
    -v "${PROJECT_ROOT}:/workspace" \
    -v "${PROJECT_NAME}-node_modules:/workspace/node_modules" \
    -v "$(pwd)/.credentials/claude:/home/node/.claude" \
    -v "$(pwd)/.credentials/codex:/home/node/.codex" \
    -e HOST_UID="$(id -u)" \
    -e HOST_GID="$(id -g)" \
    --cap-add=NET_ADMIN \
    --cap-add=NET_RAW \
    moarcode-sandbox
