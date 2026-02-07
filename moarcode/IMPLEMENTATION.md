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

