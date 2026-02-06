# Implementation Plan: moarcode v1.0

## Overview

Build the moarcode template — a bolt-on AI development environment that enables
Claude Code + Codex code review in a Docker container.

**Reference spec:** `/workspace/MOARCODE.md`

## Milestones

### M1: Verify Core Scripts Work

**Goal:** Confirm the bootstrapped scripts actually function.

**Tasks:**
- [ ] Run `./develop.sh` and verify container builds and starts
- [ ] Complete Claude and Codex login flows
- [ ] Verify credentials persist in `.credentials/`
- [ ] Run `claude --dangerously-skip-permissions` and confirm it starts
- [ ] Run `/workspace/moarcode/codereview.sh` and verify Codex executes

**Acceptance Criteria:**
- Container starts without errors
- Credentials survive container restart
- Both Claude and Codex are functional inside container
- Code review outputs to stdout

---

### M2: Test the Workflow Loop

**Goal:** Verify the full Claude → Codex → Claude feedback loop works.

**Tasks:**
- [ ] Make a small change to any file
- [ ] Commit it
- [ ] Run code review
- [ ] Verify CODEX-DIARY.md gets updated with findings
- [ ] Address or document findings
- [ ] Update DIARY.md

**Acceptance Criteria:**
- Codex successfully writes to CODEX-DIARY.md
- Claude can read the review output
- The iterative loop is functional

---

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

---

## Future Milestones (Post v1.0)

- M5: Add CI integration examples
- M6: Support for non-Codex reviewers (e.g., second Claude instance)
- M7: Pre-built Docker image on GHCR
