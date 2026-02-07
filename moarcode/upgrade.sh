#!/usr/bin/env bash
set -euo pipefail

# Upgrade an existing moarcode installation with latest infrastructure files.
# Usage: cd ~/myproject && ~/path/to/moarcode-repo/moarcode/upgrade.sh [--yes]

AUTO_YES=false
for arg in "$@"; do
  case "$arg" in
    --yes|-y) AUTO_YES=true ;;
    *) echo "Unknown option: $arg"; echo "Usage: $0 [--yes]"; exit 1 ;;
  esac
done

# Auto-yes when stdin is not a TTY (CI/scripted use)
if [ ! -t 0 ]; then
  AUTO_YES=true
fi

SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="$(pwd)/moarcode"

# --- Guards ---

if [ "$SOURCE_DIR" = "$TARGET_DIR" ]; then
  echo "Error: You're already inside a moarcode directory."
  echo "Run this from your project root: cd ~/myproject && $0"
  exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: moarcode/ not found in the current directory."
  echo "Use install.sh for first-time setup: $SOURCE_DIR/install.sh"
  exit 1
fi

for marker in develop.sh Dockerfile CLAUDE.md; do
  if [ ! -f "$TARGET_DIR/$marker" ]; then
    echo "Error: $TARGET_DIR/$marker not found — doesn't look like a moarcode installation."
    exit 1
  fi
done

# --- Version info ---

SOURCE_VERSION="unknown"
TARGET_VERSION="unknown"
if [ -f "$SOURCE_DIR/VERSION" ]; then
  SOURCE_VERSION=$(cat "$SOURCE_DIR/VERSION" | tr -d '[:space:]')
fi
if [ -f "$TARGET_DIR/VERSION" ]; then
  TARGET_VERSION=$(cat "$TARGET_DIR/VERSION" | tr -d '[:space:]')
fi

echo ""
if [ "$SOURCE_VERSION" = "$TARGET_VERSION" ]; then
  echo "Upgrading moarcode in $(pwd)/moarcode (v${TARGET_VERSION}, already current)..."
else
  echo "Upgrading moarcode in $(pwd)/moarcode (v${TARGET_VERSION} → v${SOURCE_VERSION})..."
fi
echo ""

# --- Infrastructure files (always overwrite) ---

INFRA_FILES=(
  Dockerfile
  container-entrypoint.sh
  develop.sh
  codereview.sh
  reset.sh
  init-firewall.sh
  .dockerignore
  .gitignore
  VERSION
)

updated=0
skipped=0
added=0
cleaned=0

for f in "${INFRA_FILES[@]}"; do
  if [ ! -f "$SOURCE_DIR/$f" ]; then
    echo "  warn: $f not found in source, skipping"
    skipped=$((skipped + 1))
    continue
  fi
  if [ -f "$TARGET_DIR/$f" ] && diff -q "$SOURCE_DIR/$f" "$TARGET_DIR/$f" >/dev/null 2>&1; then
    skipped=$((skipped + 1))
    continue
  fi
  if [ -f "$TARGET_DIR/$f" ]; then
    cp "$SOURCE_DIR/$f" "$TARGET_DIR/$f"
    echo "  updated: $f"
    updated=$((updated + 1))
  else
    cp "$SOURCE_DIR/$f" "$TARGET_DIR/$f"
    echo "  added:   $f"
    added=$((added + 1))
  fi
done

# --- Template files (diff + prompt if modified) ---

TEMPLATE_FILES=(
  CLAUDE.md
  CODEX-REVIEW-PROMPT.md
)

for f in "${TEMPLATE_FILES[@]}"; do
  if [ ! -f "$SOURCE_DIR/$f" ]; then
    echo "  warn: $f not found in source, skipping"
    skipped=$((skipped + 1))
    continue
  fi

  if [ ! -f "$TARGET_DIR/$f" ]; then
    cp "$SOURCE_DIR/$f" "$TARGET_DIR/$f"
    echo "  added:   $f"
    added=$((added + 1))
    continue
  fi

  if diff -q "$SOURCE_DIR/$f" "$TARGET_DIR/$f" >/dev/null 2>&1; then
    skipped=$((skipped + 1))
    continue
  fi

  # Files differ
  if [ "$AUTO_YES" = true ]; then
    cp "$SOURCE_DIR/$f" "$TARGET_DIR/$f"
    echo "  updated: $f (auto-overwritten)"
    updated=$((updated + 1))
  else
    echo ""
    echo "  $f differs from the latest version:"
    diff -u "$TARGET_DIR/$f" "$SOURCE_DIR/$f" || true
    echo ""
    printf "  Overwrite %s? [Y/n] " "$f"
    read -r answer
    case "${answer:-Y}" in
      [Yy]*|"")
        cp "$SOURCE_DIR/$f" "$TARGET_DIR/$f"
        echo "  updated: $f"
        updated=$((updated + 1))
        ;;
      *)
        echo "  kept:    $f (local version)"
        skipped=$((skipped + 1))
        ;;
    esac
  fi
done

# --- Clean up stale files ---

STALE_FILES=(install.sh upgrade.sh)

for f in "${STALE_FILES[@]}"; do
  if [ -f "$TARGET_DIR/$f" ]; then
    rm "$TARGET_DIR/$f"
    echo "  removed: $f (source-repo only)"
    cleaned=$((cleaned + 1))
  fi
done

# --- Summary ---

echo ""
echo "Done! ${updated} updated, ${added} added, ${skipped} unchanged, ${cleaned} cleaned up."
