# Implementation Plan: moarcode v1.0

## Overview

Build the moarcode template — a bolt-on AI development environment that enables
Claude Code + Codex code review in a Docker container.

**Reference spec:** `/workspace/MOARCODE.md`

## Milestones

### M3: Polish for Distribution

**Goal:** Make the template ready to clone into other projects.

**Tasks:**
- [ ] Ensure all scripts are executable (`chmod +x`)
- [ ] Add `.gitignore` to moarcode/ (ignore `.credentials/`)
- [ ] Verify paths work when moarcode/ is cloned into a different project
- [ ] Test with a fresh `.credentials/` directory (new login flow)
- [ ] Update MOARCODE.md if any discrepancies found

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

