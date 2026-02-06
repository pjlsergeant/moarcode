# Implementation Plan: moarcode v1.0

## Overview

Build the moarcode template — a bolt-on AI development environment that enables
Claude Code + Codex code review in a Docker container.

**Reference spec:** `/workspace/MOARCODE.md`

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
- [x] Update MOARCODE.md if any discrepancies found

**Acceptance Criteria:**
- `git clone <repo> moarcode && cd moarcode && ./develop.sh` works
- No hardcoded paths that break in other projects
- Documentation matches implementation

---

### M4: Documentation Pass

**Goal:** Ensure documentation is complete and accurate.

**Tasks:**
- [ ] Review MOARCODE.md against actual implementation
- [ ] Add any missing instructions
- [ ] Create example root CLAUDE.md template
- [ ] Document known limitations

**Acceptance Criteria:**
- A new user can follow MOARCODE.md to set up a project
- No undocumented gotchas

