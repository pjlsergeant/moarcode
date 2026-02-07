#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

PROJECT_ROOT=$(cd .. && pwd)

# Read project name set during install
if [ -f .project-name ]; then
  PROJECT_NAME=$(cat .project-name)
else
  echo "Warning: .project-name not found. Run install.sh first."
  echo "Falling back to directory name."
  PROJECT_NAME=$(basename "$PROJECT_ROOT" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]-_' '-' | sed 's/[-_][-_]*/-/g; s/^[-_]*//; s/[-_]*$//')
fi

if [ -z "$PROJECT_NAME" ]; then
  echo "Error: could not determine a valid project name."
  echo "Run install.sh first, or create .project-name manually."
  exit 1
fi

IMAGE_NAME="moarcode-${PROJECT_NAME}"

echo "Building ${IMAGE_NAME} image..."
docker build -t "$IMAGE_NAME" .

echo "Creating node_modules volume..."
docker volume create "${PROJECT_NAME}-node_modules" >/dev/null 2>&1 || true

mkdir -p .credentials/claude .credentials/codex

# Pull host git identity so commits are attributed to the developer
GIT_ENV_FLAGS=()
HOST_GIT_NAME=$(git config user.name 2>/dev/null || true)
HOST_GIT_EMAIL=$(git config user.email 2>/dev/null || true)
if [ -n "$HOST_GIT_NAME" ]; then
  GIT_ENV_FLAGS+=(-e "GIT_AUTHOR_NAME=${HOST_GIT_NAME}" -e "GIT_COMMITTER_NAME=${HOST_GIT_NAME}")
fi
if [ -n "$HOST_GIT_EMAIL" ]; then
  GIT_ENV_FLAGS+=(-e "GIT_AUTHOR_EMAIL=${HOST_GIT_EMAIL}" -e "GIT_COMMITTER_EMAIL=${HOST_GIT_EMAIL}")
fi

echo "Starting container..."
docker run -it --rm \
    --hostname moarcode \
    -v "${PROJECT_ROOT}:/workspace" \
    -v "${PROJECT_NAME}-node_modules:/workspace/node_modules" \
    -v "$(pwd)/.credentials/claude:/home/node/.claude" \
    -v "$(pwd)/.credentials/codex:/home/node/.codex" \
    -e HOST_UID="$(id -u)" \
    -e HOST_GID="$(id -g)" \
    ${GIT_ENV_FLAGS[@]+"${GIT_ENV_FLAGS[@]}"} \
    --cap-add=NET_ADMIN \
    --cap-add=NET_RAW \
    "$IMAGE_NAME"
