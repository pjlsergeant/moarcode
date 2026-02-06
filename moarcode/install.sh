#!/usr/bin/env bash
set -euo pipefail

# Install moarcode into the current project directory.
# Usage: cd ~/myproject && ~/path/to/moarcode-repo/moarcode/install.sh

SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="$(pwd)/moarcode"

if [ "$SOURCE_DIR" = "$TARGET_DIR" ]; then
  echo "Error: You're already inside a moarcode directory."
  echo "Run this from your project root: cd ~/myproject && $0"
  exit 1
fi

if [ -d "$TARGET_DIR" ]; then
  echo "Error: moarcode/ already exists in this directory."
  echo "Remove it first if you want to reinstall: rm -rf moarcode/"
  exit 1
fi

echo "Installing moarcode into $(pwd)..."

# Copy template files, then remove project-specific and transient content
cp -R "$SOURCE_DIR" "$TARGET_DIR"
rm -rf "$TARGET_DIR/.credentials" \
       "$TARGET_DIR/.git" \
       "$TARGET_DIR/node_modules" \
       "$TARGET_DIR/tmp" \
       "$TARGET_DIR/DIARY.md" \
       "$TARGET_DIR/CODEX-DIARY.md" \
       "$TARGET_DIR/IMPLEMENTATION.md" \
       "$TARGET_DIR/install.sh"

# Create fresh template files
cat > "$TARGET_DIR/DIARY.md" << 'DIARY_EOF'
# Development Diary

Progress log for development. Updated after each session.

---
DIARY_EOF

cat > "$TARGET_DIR/CODEX-DIARY.md" << 'CODEX_EOF'
# CODEX Diary

Code review history and findings. Updated by Codex during each review.

---

## Accepted / Won't Fix

These findings have been reviewed by the developer and are intentional:

(none yet)

---
CODEX_EOF

cat > "$TARGET_DIR/IMPLEMENTATION.md" << 'IMPL_EOF'
# Implementation Plan

## Overview

[What we're building and why]

## Milestones

### M1: [First Milestone Name]

**Goal:** [What this achieves]

**Tasks:**
- [ ] [Specific task]
- [ ] [Another task]

**Acceptance Criteria:**
- [ ] [Specific testable requirement]
- [ ] All tests pass
- [ ] Code review clean

---

### M2: [Second Milestone Name]

**Goal:** [What this achieves]

**Tasks:**
- [ ] [Specific task]

**Acceptance Criteria:**
- [ ] [Specific testable requirement]
- [ ] All tests pass
- [ ] Code review clean
IMPL_EOF

# Add moarcode/ to project .gitignore if not already there
if [ -f .gitignore ]; then
  if ! grep -qxF 'moarcode/' .gitignore; then
    echo 'moarcode/' >> .gitignore
    echo "Added moarcode/ to .gitignore"
  fi
else
  echo 'moarcode/' > .gitignore
  echo "Created .gitignore with moarcode/"
fi

# Patch or create root CLAUDE.md
MOARCODE_BLOCK='## AI Development Environment

> **If you are running inside the moarcode container, you MUST read
> `moarcode/CLAUDE.md` BEFORE doing anything else.** It contains the
> workflow rules (commits, code review, diaries) you must follow.

Key files in moarcode/:
| File | Purpose |
|------|---------|
| `CLAUDE.md` | Workflow rules (commits, code review, diaries) |
| `IMPLEMENTATION.md` | Milestones and detailed build plan |
| `DIARY.md` | Your progress log — update after each session |
| `CODEX-DIARY.md` | Code review history from Codex |
| `codereview.sh` | Run this for code review: `/workspace/moarcode/codereview.sh` |

**Start each session by reading these files. Update DIARY.md when you finish.**'

if [ -f CLAUDE.md ]; then
  # Prepend moarcode block to existing CLAUDE.md
  {
    echo "$MOARCODE_BLOCK"
    echo ""
    echo "---"
    echo ""
    cat CLAUDE.md
  } > CLAUDE.md.tmp
  mv CLAUDE.md.tmp CLAUDE.md
  echo "Patched CLAUDE.md (prepended moarcode section)"
else
  cat > CLAUDE.md << CLAUDE_EOF
# CLAUDE.md

$MOARCODE_BLOCK

## Project Overview

[Brief description of what this project does]

## Tech Stack

- [Languages, frameworks, etc.]

## Coding Conventions

- [Style guides, patterns, etc.]
CLAUDE_EOF
  echo "Created CLAUDE.md with moarcode section"
fi

echo ""
echo "Done! Next steps:"
echo "  1. Edit moarcode/IMPLEMENTATION.md with your milestones"
echo "  2. Review CLAUDE.md and fill in project details"
echo "  3. cd moarcode && ./develop.sh"
