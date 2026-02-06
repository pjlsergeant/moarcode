#!/usr/bin/env bash
set -euo pipefail

# Codex must be on PATH (installed via npm in the container)
if ! command -v codex &>/dev/null; then
    echo "Error: codex not found on PATH."
    echo "This script must be run inside the moarcode container."
    echo "First run ./develop.sh, then run this from the container shell."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMP_DIR="${SCRIPT_DIR}/tmp"
mkdir -p "$TEMP_DIR"

OUTPUT_FILE=$(mktemp "${TEMP_DIR}/codereview-output.XXXXXX")
DEBUG_FILE=$(mktemp "${TEMP_DIR}/codereview-debug.XXXXXX")

echo "Running code review (this may take several minutes)..."

# Run from project root so paths in the prompt work correctly
cd /workspace

# Read prompt from file
PROMPT=$(cat /workspace/moarcode/CODEX-REVIEW-PROMPT.md)

if codex exec \
    --dangerously-bypass-approvals-and-sandbox \
    "$PROMPT" \
    --output-last-message "$OUTPUT_FILE" > "$DEBUG_FILE" 2>&1; then
  cat "$OUTPUT_FILE"
  rm -f "$OUTPUT_FILE" "$DEBUG_FILE"
else
  echo ""
  echo "Code review failed. Output preserved for inspection:"
  echo "  Debug log: $DEBUG_FILE"
  echo "  Output:    $OUTPUT_FILE"
  exit 1
fi
