#!/usr/bin/env bash
set -euo pipefail

NODE_USER="node"
NODE_MODULES_DIR="/workspace/node_modules"
DEFAULT_UID=$(id -u "$NODE_USER")
DEFAULT_GID=$(id -g "$NODE_USER")

TARGET_UID=${HOST_UID:-$DEFAULT_UID}
TARGET_GID=${HOST_GID:-$DEFAULT_GID}
TARGET_USER_SPEC="${TARGET_UID}:${TARGET_GID}"
TARGET_HOME="/home/node"

# Add host UID/GID to passwd/group if needed
if ! getent group "$TARGET_GID" > /dev/null 2>&1; then
  echo "hostgroup:x:${TARGET_GID}:" >> /etc/group
fi
if ! getent passwd "$TARGET_UID" > /dev/null 2>&1; then
  echo "developer:x:${TARGET_UID}:${TARGET_GID}:Developer:${TARGET_HOME}:/bin/bash" >> /etc/passwd
fi

# Ensure node_modules exists and is owned correctly
if [ ! -d "$NODE_MODULES_DIR" ]; then
  mkdir -p "$NODE_MODULES_DIR"
fi

# Only chown if ownership differs (avoids slow recursive chown on large trees)
CURRENT_UID=$(stat -c %u "$NODE_MODULES_DIR" 2>/dev/null || stat -f %u "$NODE_MODULES_DIR" 2>/dev/null || echo "")
if [ -n "$CURRENT_UID" ] && [ "$CURRENT_UID" != "$TARGET_UID" ]; then
  chown -R "$TARGET_UID":"$TARGET_GID" "$NODE_MODULES_DIR"
fi

# Ensure home directory is owned correctly for credential writes
CURRENT_HOME_UID=$(stat -c %u "$TARGET_HOME" 2>/dev/null || stat -f %u "$TARGET_HOME" 2>/dev/null || echo "")
if [ -n "$CURRENT_HOME_UID" ] && [ "$CURRENT_HOME_UID" != "$TARGET_UID" ]; then
  chown -R "$TARGET_UID":"$TARGET_GID" "$TARGET_HOME"
fi

export HOME="$TARGET_HOME"

# First-run credential setup
# Codex is checked FIRST because it can be triggered non-interactively.
# Claude is checked second — its login flow is interactive and launches
# the main session, so it must come last to avoid stdin leakage.
CLAUDE_CREDS="/home/node/.claude/.credentials.json"
CODEX_CREDS="/home/node/.codex/auth.json"

if [ ! -f "$CODEX_CREDS" ]; then
  echo ""
  echo "=== First-run setup: Codex ==="
  echo "Codex credentials not found. Running Codex to trigger login..."
  echo ""
  gosu "$TARGET_USER_SPEC" codex login --device-auth
  echo ""
  if [ -f "$CODEX_CREDS" ]; then
    echo "Codex credentials saved."
  else
    echo "Warning: Codex credentials not found after login attempt."
    echo "Code review (codereview.sh) will not work until Codex is authenticated."
  fi
  echo ""
fi

# NOTE: No separate Claude login step needed. "claude login" doesn't exist
# as a subcommand — it just starts Claude with "login" as a prompt.
# If Claude creds are missing, the main `claude` launch below will handle
# the auth flow itself (DEVCONTAINER=true helps skip interactive prompts).

# Default to Claude in fully autonomous mode
if [ $# -eq 0 ]; then
  set -- claude --dangerously-skip-permissions
fi

exec gosu "$TARGET_USER_SPEC" "$@"
