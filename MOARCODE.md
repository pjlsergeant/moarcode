# Moarcode: Dual-AI Development Workflow

A bolt-on AI development environment using Claude Code as the implementer and OpenAI Codex as an autonomous code reviewer. Lives in a gitignored subdirectory, keeps your project clean.

---

## Directory Structure

```
dev/myproject/                        # Your project - versioned
├── .gitignore                        # includes "moarcode/"
├── CLAUDE.md                         # Project context + pointer to moarcode/
├── src/
├── package.json
└── moarcode/                         # gitignored - AI machinery
    ├── .credentials/                 # Auth tokens (first-run setup)
    │   ├── claude/
    │   └── codex/
    ├── CLAUDE.md                     # Detailed workflow instructions
    ├── IMPLEMENTATION.md             # Milestones and build plan
    ├── DIARY.md                      # Claude's progress log
    ├── CODEX-DIARY.md                # Codex's review memory
    ├── CODEX-REVIEW-PROMPT.md        # Editable prompt for code review
    ├── Dockerfile
    ├── container-entrypoint.sh
    ├── develop.sh                    # Launch script
    ├── codereview.sh                 # Code review script
    ├── init-firewall.sh
    ├── install.sh                   # Install moarcode into a project
    └── reset.sh                     # Clear credentials for fresh start
```

> **Note:** The directory MUST be named `moarcode/`. The code review prompt references
> this path. If you need a different name, update `CODEX-REVIEW-PROMPT.md` accordingly.

---

## Quick Start

```bash
# Install moarcode into your project
cd dev/myproject
/path/to/moarcode-repo/moarcode/install.sh

# install.sh will:
#   - Copy template files into moarcode/ (excluding credentials, tmp, .git)
#   - Create fresh DIARY.md, CODEX-DIARY.md, IMPLEMENTATION.md templates
#   - Add moarcode/ to .gitignore
#   - Create or patch CLAUDE.md with moarcode instructions

# Edit moarcode/IMPLEMENTATION.md with your milestones
# Review CLAUDE.md and fill in project details

# Launch
cd moarcode
./develop.sh

# First run: complete Codex login flow in the browser
# Credentials saved to .credentials/ for future runs
# Then Claude starts automatically in fully autonomous mode

# When Claude needs a code review:
./moarcode/codereview.sh
```

---

## Core Components

### 1. Dockerfile

The Dockerfile enables fully unsupervised operation. Key elements explained:

```dockerfile
FROM node:20

# Full tool suite for AI agents
RUN apt-get update && apt-get install -y --no-install-recommends \
    less \
    git \
    procps \
    sudo \
    fzf \
    zsh \
    unzip \
    jq \
    nano \
    vim \
    ripgrep \
    iptables \
    gosu \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Firewall script for network sandboxing (optional)
COPY init-firewall.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init-firewall.sh && \
    echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/node-firewall && \
    chmod 0440 /etc/sudoers.d/node-firewall

# CRITICAL: Helps Claude skip interactive prompts
ENV DEVCONTAINER=true
ENV COLORTERM=truecolor

# Directory setup
RUN mkdir -p /workspace /home/node/.claude /home/node/.codex /usr/local/share/npm-global && \
    chown -R node:node /workspace /home/node/.claude /home/node/.codex /usr/local/share/npm-global

WORKDIR /workspace

# npm global path
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin
ENV CLAUDE_CONFIG_DIR=/home/node/.claude

USER node

# CRITICAL: Both AI tools installed
RUN npm install -g @anthropic-ai/claude-code @openai/codex

# Git config for commits
RUN git config --global --add safe.directory /workspace \
    && git config --global user.email "ai@localhost" \
    && git config --global user.name "AI Developer"

USER root
COPY container-entrypoint.sh /usr/local/bin/dev-entrypoint.sh
RUN chmod +x /usr/local/bin/dev-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/dev-entrypoint.sh"]
```

#### Why Each Part Matters

| Element | Purpose |
|---------|---------|
| `DEVCONTAINER=true` | Claude detects this, skips some interactive prompts |
| `gosu` | Proper UID/GID mapping so bind-mounted files have correct ownership |
| `iptables` + `sudo` | Optional network sandboxing (HTTP/HTTPS/DNS only) |
| Both tools installed | Claude can invoke Codex via `codereview.sh` |
| Git pre-configured | Claude can commit without user.name/email prompts |
| `COLORTERM=truecolor` | Richer terminal colors for AI tools |

---

### 2. Container Entrypoint

Handles UID mapping and first-run credential setup:

```bash
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
```

#### Launch Behavior

The entrypoint defaults to `claude --dangerously-skip-permissions` for fully autonomous operation.

To override, pass a different command to develop.sh (or modify the docker run):
- `bash` for a shell
- `claude` for interactive mode with permission prompts

---

### 3. develop.sh

Launch script. Run from inside `moarcode/`:

```bash
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

# Sanitize project name for use as Docker volume name (replace non-alphanumeric with -)
PROJECT_NAME=$(basename "$(cd .. && pwd)" | tr -cs '[:alnum:]-_' '-')
PROJECT_ROOT=$(cd .. && pwd)

echo "Building moarcode-sandbox image..."
docker build -t moarcode-sandbox .

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
    moarcode-sandbox
```

---

### 4. CODEX-REVIEW-PROMPT.md

The Codex review prompt lives in its own file so you can customize it:

```markdown
You are PURELY a code-review agent. You may write to moarcode/CODEX-DIARY.md only.
Do not modify any other file. Do not run tests or builds.

Your review process:
1. Read moarcode/CODEX-DIARY.md (if exists) for prior context
2. Read moarcode/IMPLEMENTATION.md for the build plan
3. Read moarcode/DIARY.md for developer progress
4. Read the root CLAUDE.md for project context
5. Check recent git history
6. Review the implementation so far

Provide a comprehensive code review. Focus on:
- Bugs and logic errors
- Missing edge cases
- Deviations from IMPLEMENTATION.md
- Security issues
- Code quality concerns

Update moarcode/CODEX-DIARY.md with your findings (include timestamp).
Give a full report as your final message.
```

---

### 5. codereview.sh

Runs Codex with the prompt. **Must be run from inside the container** (after `./develop.sh`):

```bash
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
```

#### Key Details

- `develop.sh` runs from host, launches the container
- `develop.sh` forwards the host's `git config user.name` and `user.email` into the container so commits are attributed to the developer
- `codereview.sh` runs from inside the container
- Prompt is in a separate `.md` file for easy editing
- Project name derived automatically from parent directory
- Credentials persist in `.credentials/` between runs
- `reset.sh` clears credentials for a fresh login flow

---

### 4. Network Sandbox (Optional)

Restricts container to HTTP/HTTPS/DNS only:

```bash
#!/bin/bash
# init-firewall.sh

set -e

iptables -F OUTPUT
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT
iptables -A OUTPUT -j DROP

echo "Firewall configured: allowing only DNS (53), HTTP (80), HTTPS (443)"
```

Run inside container: `sudo /usr/local/bin/init-firewall.sh`

---

### 5. Root CLAUDE.md Template

Place in your project root (versioned):

```markdown
# CLAUDE.md

## Project Overview

[Brief description of what this project does]

## Tech Stack

- [Languages, frameworks, etc.]

## Coding Conventions

- [Style guides, patterns, etc.]

## AI Development Environment

This project uses **moarcode/** for AI-assisted development.

> **REQUIRED:** Before starting any work, you MUST read `moarcode/CLAUDE.md`
> for workflow instructions, then `moarcode/IMPLEMENTATION.md` for the build plan.

Key files in moarcode/:
| File | Purpose |
|------|---------|
| `CLAUDE.md` | Workflow rules (commits, code review, diaries) |
| `IMPLEMENTATION.md` | Milestones and detailed build plan |
| `DIARY.md` | Your progress log — update after each session |
| `CODEX-DIARY.md` | Code review history from Codex |

**Start each session by reading these files. Update DIARY.md when you finish.**
```

---

### 6. moarcode/CLAUDE.md Template

Detailed workflow instructions (gitignored with the rest of moarcode/):

```markdown
# moarcode/CLAUDE.md

> **IMPORTANT: After any context compaction or new session, STOP and re-read:**
> 1. The root `/workspace/CLAUDE.md`
> 2. This file (`moarcode/CLAUDE.md`)
> 3. `moarcode/IMPLEMENTATION.md`
> 4. `moarcode/DIARY.md` (your previous progress)

## Development Flow

### Autonomy

You have permission to keep going. Don't stop to ask "should I continue?" after
each step — proceed through the milestones. This includes code review: run it
yourself, address the findings yourself, and keep moving. Never ask the user
whether you should run code review or continue — just do it.

The only reasons to stop and ask for help:
- You've tried the same fix 2-3 times without success
- You're unsure which approach is correct
- A test keeps failing and you don't understand why

### Code Review (MANDATORY — run it yourself, don't ask)

After completing ANY feature, fix, or milestone, run code review immediately:

```bash
/workspace/moarcode/codereview.sh
```

Do NOT ask the user "should I run code review?" — the answer is always yes.
Do NOT proceed to the next milestone until code review passes.

The code review loop:
1. Run `/workspace/moarcode/codereview.sh`
2. Read ALL findings from the script output (do NOT read CODEX-DIARY.md directly — that is Codex's persistent memory)
3. For each finding: fix it OR document why you're ignoring it in CODEX-DIARY.md
4. If you made ANY fixes → go back to step 1
5. Only proceed when clean or all remaining issues are documented

### Commit Frequently

> **Before writing more code: "Do I have uncommitted work?"**
> If yes, COMMIT IT NOW.

If `git status` shows more than ~5 changed files, you've waited too long.

Commit after each coherent unit:
- After implementing a function and its tests — COMMIT
- After fixing a bug — COMMIT
- After refactoring that keeps tests green — COMMIT
- Before trying a risky change — COMMIT

Commit message format: `M<N>: Description` where N is the milestone number.

**Do NOT add `Co-Authored-By`, `Signed-off-by`, or any other trailer to commits
unless the developer has explicitly asked you to.** Commits are attributed to
the developer via their git identity (passed in from the host). Adding
co-sign trailers without permission misrepresents the authorship arrangement.

### Diary Updates

Update `moarcode/DIARY.md` after each session:
- What was implemented
- Discoveries or surprises
- Decisions made and why
- Code review feedback addressed
- What's next

### Before Moving to Next Milestone

1. Commit all work
2. Run code review loop until clean
3. Commit any fixes
4. Update DIARY.md
5. THEN start next milestone
```

---

### 7. moarcode/IMPLEMENTATION.md Template

```markdown
# Implementation Plan

## Overview

[What we're building and why]

## Milestones

### M1: [First Milestone Name]

**Goal:** [What this achieves]

**Files:**
- `src/lib/something.ts` — [purpose]
- `src/lib/something.spec.ts` — [tests]

**Acceptance Criteria:**
- [ ] [Specific testable requirement]
- [ ] [Another requirement]
- [ ] All tests pass
- [ ] Code review clean

---

### M2: [Second Milestone Name]

...
```

---

### 8. .gitignore for Project Root

```gitignore
moarcode/
node_modules/
dist/
.env
```

---

## How It Works

```
┌─────────────────────────────────────────────────────────────────────┐
│  Host: dev/myproject/                                               │
│                                                                     │
│    cd moarcode && ./develop.sh                                      │
│         │                                                           │
│         ▼                                                           │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  Docker Container                                            │   │
│  │                                                              │   │
│  │  /workspace (mounted from dev/myproject/)                    │   │
│  │  ├── CLAUDE.md          ◄── Claude reads this first         │   │
│  │  ├── src/                                                    │   │
│  │  └── moarcode/                                               │   │
│  │      ├── CLAUDE.md      ◄── Then this (detailed workflow)   │   │
│  │      ├── IMPLEMENTATION.md                                   │   │
│  │      ├── DIARY.md       ◄── Claude updates                  │   │
│  │      └── CODEX-DIARY.md ◄── Codex updates                   │   │
│  │                                                              │   │
│  │  Claude ──codereview.sh──► Codex                              │   │
│  │    │                             │                           │   │
│  │    │                             ▼                           │   │
│  │    │                      Reviews code,                      │   │
│  │    │                      writes CODEX-DIARY.md,             │   │
│  │    │                      returns findings                   │   │
│  │    │                             │                           │   │
│  │    ◄─────────────────────────────┘                           │   │
│  │    │                                                         │   │
│  │    ▼                                                         │   │
│  │  Fixes issues or documents why ignored                       │   │
│  │  Commits, updates DIARY.md                                   │   │
│  │  Proceeds to next milestone                                  │   │
│  │                                                              │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

---

## First-Run Experience

```
$ cd dev/myproject/moarcode
$ ./develop.sh

Building moarcode-sandbox image...
Creating node_modules volume...
Starting container...

=== First-run setup: Codex ===
Codex credentials not found. Running Codex to trigger login...
[Browser opens for OpenAI OAuth — device auth flow]
Codex credentials saved.

[Claude starts in autonomous mode]
[If Claude credentials are missing, Claude handles its own OAuth on first launch]
```

Next time: straight to Claude, no login prompts.

---

## Bootstrapping a New Project

```bash
# Use the install script from a local clone of the moarcode repo
cd dev/newproject
/path/to/moarcode-repo/moarcode/install.sh

# This copies template files, creates fresh diaries/milestones,
# patches CLAUDE.md, and adds moarcode/ to .gitignore.

# Then customize:
# - Edit moarcode/IMPLEMENTATION.md with your milestones
# - Review CLAUDE.md and fill in project details

cd moarcode
./develop.sh
```

---

## Files Reference

| File | Location | Versioned | Purpose |
|------|----------|-----------|---------|
| `CLAUDE.md` | project root | Yes | Project context, points to moarcode/ |
| `CLAUDE.md` | moarcode/ | No | Detailed AI workflow rules |
| `IMPLEMENTATION.md` | moarcode/ | No | Build plan with milestones |
| `DIARY.md` | moarcode/ | No | Claude's session log |
| `CODEX-DIARY.md` | moarcode/ | No | Codex's review memory |
| `CODEX-REVIEW-PROMPT.md` | moarcode/ | No | Editable prompt for code review |
| `Dockerfile` | moarcode/ | No | Container definition |
| `container-entrypoint.sh` | moarcode/ | No | Startup + credential check |
| `develop.sh` | moarcode/ | No | Launch script (run from host) |
| `codereview.sh` | moarcode/ | No | Code review script (run from container) |
| `init-firewall.sh` | moarcode/ | No | Network sandbox script |
| `install.sh` | moarcode/ | No | Install moarcode into a project |
| `reset.sh` | moarcode/ | No | Clear credentials for fresh start |
| `.credentials/` | moarcode/ | No | OAuth tokens |
