#!/usr/bin/env bash
set -euo pipefail

# Must run from inside container where /opt/homebrew/bin/codex exists
if [ ! -x /opt/homebrew/bin/codex ]; then
    echo "Error: This script must be run inside the moarcode container."
    echo "First run ./develop.sh, then run this from the container shell."
    exit 1
fi

OUTPUT_FILE=$(mktemp /tmp/codereview-output.XXXXXX)
DEBUG_FILE=$(mktemp /tmp/codereview-debug.XXXXXX)
trap "rm -f $OUTPUT_FILE $DEBUG_FILE" EXIT

echo "Running code review (this may take several minutes)..."

# Run from project root so paths in the prompt work correctly
cd /workspace

# Read prompt from file
PROMPT=$(cat /workspace/moarcode/CODEX-REVIEW-PROMPT.md)

/opt/homebrew/bin/codex exec \
    --dangerously-bypass-approvals-and-sandbox \
    "$PROMPT" \
    --output-last-message "$OUTPUT_FILE" > "$DEBUG_FILE" 2>&1

cat "$OUTPUT_FILE"
