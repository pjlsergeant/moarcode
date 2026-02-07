# Implementation Plan: moarcode v1.0

## Overview

Build the moarcode template — a bolt-on AI development environment that enables
Claude Code + Codex code review in a Docker container.

**Reference:** `/workspace/README.md` and `/workspace/docs/architecture.md`

## Milestones

### M3: Polish for Distribution

**Goal:** Make the template ready to clone into other projects.

**Tasks:**
- [x] Ensure all scripts are executable (`chmod +x`)
- [x] Add `.gitignore` to moarcode/ (ignore `.credentials/`)
- [x] Add `.dockerignore` to exclude credentials from Docker build context
- [x] Verify paths work when moarcode/ is cloned into a different project
- [x] Fix `reset.sh` dotfile glob (use rm -rf + mkdir instead of `.*` expansion)
- [x] Test with a fresh `.credentials/` directory (new login flow)
- [x] Update docs if any discrepancies found

**Acceptance Criteria:**
- `git clone <repo> moarcode && cd moarcode && ./develop.sh` works
- No hardcoded paths that break in other projects
- Documentation matches implementation

---

### M4: Documentation Pass

**Goal:** Ensure documentation is complete and accurate.

**Tasks:**
- [ ] Review README.md and docs/architecture.md against actual implementation
- [ ] Add any missing instructions
- [ ] Create example root CLAUDE.md template
- [ ] Document known limitations

**Acceptance Criteria:**
- A new user can follow README.md to set up a project
- docs/architecture.md matches implementation
- No undocumented gotchas

---

### M5: Pre-ship Polish

**Goal:** Address final code review findings before v1 ship.

**Tasks:**
- [x] Tighten project name sanitizer: collapse repeated separators, trim all
      trailing separators (not just single trailing `-`). Apply in both
      `install.sh` and the `develop.sh` fallback.
- [x] Fix IMPLEMENTATION.md plan drift: update M4 tasks and acceptance criteria
      to reference current doc files instead of the removed legacy spec.

**Acceptance Criteria:**
- `install.sh` with inputs like `my--project`, `foo_`, `--bar` all produce
  clean Docker-valid names
- `develop.sh` fallback applies the same sanitization
- Plan and docs reference only current files (README.md, docs/architecture.md)

---

### M6: Resumable Code Review Sessions

**Goal:** Allow the driving agent to continue a previous Codex review session
instead of starting from scratch every time, reducing redundant file reads in
the common "fix and re-check" loop.

**Background:** We tested `codex exec resume` inside the container and confirmed:
- Resumed sessions carry the full conversation transcript (file contents, command
  outputs) — Codex can answer from memory without re-reading
- Token costs accumulate (~90% cached) but are manageable for a few rounds
- Session ID is a UUID from the `thread.started` JSON event
- `--json` and `--dangerously-bypass-approvals-and-sandbox` work with resume
- `--output-last-message` does NOT work with resume (extract from JSON instead)

**Tasks:**
- [x] Add `--continue` flag to `codereview.sh`
- [x] Capture session ID (via `--json` + `grep`/`jq`) after every successful review
- [x] Save session ID to `moarcode/tmp/.last-review-session`
- [x] On `--continue`: read session ID, validate as UUID, attempt
      `codex exec resume <id>` with a shorter follow-up prompt
- [x] Resume prompt: re-read diaries/plan/CLAUDE.md, run `git status` + `git diff`
      + `git diff --cached` + `git log --oneline -5`, then review changes
- [x] If resume fails (bad ID, expired session): clear session file, warn, and
      automatically fall back to a fresh review
- [x] Preserve existing session ID on resume if extraction fails
- [x] Extract final message from JSON stream (no `--output-last-message` on resume)
- [x] Update `moarcode/CLAUDE.md` to mention `--continue` for the fix-and-recheck loop
- [x] Update `docs/architecture.md` codereview.sh section

**Acceptance Criteria:**
- Fresh reviews work exactly as before (no behavioural change without `--continue`)
- `--continue` resumes the last session and Codex references previous context
- `--continue` with no saved session falls back to fresh with a warning
- `--continue` with an invalid/expired session falls back to fresh automatically
- Session ID file is in `tmp/` (already gitignored)
- Code review clean

