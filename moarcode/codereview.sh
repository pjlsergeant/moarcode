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

SESSION_FILE="${TEMP_DIR}/.last-review-session"

# --- Parse arguments ---

CONTINUE=false
FOCUS_ARGS=()

for arg in "$@"; do
  case "$arg" in
    --continue) CONTINUE=true ;;
    *) FOCUS_ARGS+=("$arg") ;;
  esac
done

OUTPUT_FILE=$(mktemp "${TEMP_DIR}/codereview-output.XXXXXX")
DEBUG_FILE=$(mktemp "${TEMP_DIR}/codereview-debug.XXXXXX")

# Run from project root so paths in the prompt work correctly
cd /workspace

# --- Helper: extract and save session ID from --json output ---

save_session_id() {
  local session_id
  session_id=$(grep -m1 '"type":"thread.started"' "$DEBUG_FILE" 2>/dev/null | jq -r '.thread_id' 2>/dev/null || true)
  if [[ -n "$session_id" && "$session_id" != "null" ]]; then
    echo "$session_id" > "$SESSION_FILE"
  else
    echo "  (warning: could not extract session ID for future --continue use)"
    rm -f "$SESSION_FILE"
  fi
}

# --- Helper: run a fresh review ---

run_fresh_review() {
  local prompt
  prompt=$(cat /workspace/moarcode/CODEX-REVIEW-PROMPT.md)

  if [[ ${#FOCUS_ARGS[@]} -gt 0 ]]; then
    prompt="${prompt}

You have been asked to pay particular attention in this review to: ${FOCUS_ARGS[*]}"
  fi

  if codex exec \
      --json \
      --dangerously-bypass-approvals-and-sandbox \
      "$prompt" \
      --output-last-message "$OUTPUT_FILE" > "$DEBUG_FILE" 2>&1; then
    save_session_id
    cat "$OUTPUT_FILE"
    rm -f "$OUTPUT_FILE" "$DEBUG_FILE"
  else
    echo ""
    echo "Code review failed. Output preserved for inspection:"
    echo "  Debug log: $DEBUG_FILE"
    echo "  Output:    $OUTPUT_FILE"
    rm -f "$SESSION_FILE"
    exit 1
  fi
}

# --- Helper: run a resumed review ---

run_resumed_review() {
  local session_id="$1"
  # Preserve existing session ID — on resume, only overwrite if we get a new one
  local preserve_session_id="$session_id"
  local prompt="You are continuing a previous code review session.

Re-read moarcode/CODEX-DIARY.md, moarcode/IMPLEMENTATION.md, moarcode/DIARY.md,
and the root CLAUDE.md for current state. Then run git status, git diff,
git diff --cached, and git log --oneline -5 to see what changed since your
last review. Focus on whether your previous findings were addressed and flag
any new issues. Update moarcode/CODEX-DIARY.md with your findings.
Give a full report as your final message."

  if [[ ${#FOCUS_ARGS[@]} -gt 0 ]]; then
    prompt="${prompt}

Pay particular attention to: ${FOCUS_ARGS[*]}"
  fi

  # Note: codex exec resume does not support --output-last-message,
  # so we extract the last agent_message from the JSON stream instead.
  if codex exec resume \
      --json \
      --dangerously-bypass-approvals-and-sandbox \
      "$session_id" \
      "$prompt" > "$DEBUG_FILE" 2>&1; then
    # Save session ID, preserving the existing one if extraction fails
    local new_id
    new_id=$(grep -m1 '"type":"thread.started"' "$DEBUG_FILE" 2>/dev/null | jq -r '.thread_id' 2>/dev/null || true)
    if [[ -n "$new_id" && "$new_id" != "null" ]]; then
      echo "$new_id" > "$SESSION_FILE"
    else
      echo "$preserve_session_id" > "$SESSION_FILE"
    fi
    # Extract the last agent/assistant message text from the JSONL output
    grep '"type":"item.completed"' "$DEBUG_FILE" \
      | grep -E '"type":"(agent_message|assistant_message)"' \
      | tail -1 \
      | jq -r '.item.text // .item.output_text // (.item.content[]?.text // empty)' > "$OUTPUT_FILE" 2>/dev/null || true
    if [[ -s "$OUTPUT_FILE" ]]; then
      cat "$OUTPUT_FILE"
    else
      echo "(warning: could not extract final message from resumed review)"
      echo "Raw output is in: $DEBUG_FILE"
    fi
    rm -f "$OUTPUT_FILE" "$DEBUG_FILE"
  else
    echo ""
    echo "Resumed review failed — falling back to fresh review..."
    rm -f "$SESSION_FILE" "$OUTPUT_FILE" "$DEBUG_FILE"
    OUTPUT_FILE=$(mktemp "${TEMP_DIR}/codereview-output.XXXXXX")
    DEBUG_FILE=$(mktemp "${TEMP_DIR}/codereview-debug.XXXXXX")
    run_fresh_review
  fi
}

# --- Main ---

if [[ "$CONTINUE" = true ]]; then
  # Attempt to resume the last review session
  if [[ -f "$SESSION_FILE" ]]; then
    SESSION_ID=$(cat "$SESSION_FILE")
    # Validate UUID pattern
    SESSION_ID=$(echo "$SESSION_ID" | tr '[:upper:]' '[:lower:]')
    if [[ "$SESSION_ID" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]; then
      echo "Continuing previous review session (this may take several minutes)..."
      run_resumed_review "$SESSION_ID"
    else
      echo "Warning: invalid session ID in $SESSION_FILE — starting fresh review."
      rm -f "$SESSION_FILE"
      echo "Running code review (this may take several minutes)..."
      run_fresh_review
    fi
  else
    echo "Warning: no previous review session found — starting fresh review."
    echo "Running code review (this may take several minutes)..."
    run_fresh_review
  fi
else
  # Fresh review
  if [[ ${#FOCUS_ARGS[@]} -gt 0 ]]; then
    echo "Running code review with focus: ${FOCUS_ARGS[*]} (this may take several minutes)..."
  else
    echo "Running code review (this may take several minutes)..."
  fi
  run_fresh_review
fi
