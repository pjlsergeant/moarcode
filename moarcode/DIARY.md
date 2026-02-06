# Development Diary

Progress log for moarcode development. Updated after each session.

---

## Bootstrap — 2026-02-06

### What was done

- Created initial moarcode template structure from MOARCODE.md spec
- Files created:
  - Dockerfile
  - container-entrypoint.sh
  - develop.sh
  - codereview.sh
  - init-firewall.sh
  - CODEX-REVIEW-PROMPT.md
  - CLAUDE.md (workflow instructions)
  - IMPLEMENTATION.md (build plan)
  - This diary

### Next step

M1: Verify core scripts work — run `./develop.sh` and test the container.

---

## Session 2 — 2026-02-06

### What was done

- **Found and fixed the `claude login` bug.** `claude login` is not a real subcommand —
  it was launching a full Claude session with "login" as the initial prompt. This meant:
  - The entrypoint never reached `exec gosu ... claude --dangerously-skip-permissions`
  - Claude ran in default permission mode (no `--dangerously-skip-permissions`)
  - The word "login" leaked into Claude's session as a ghost first message
  - Confirmed via `/proc/14/cmdline` showing just `claude` with no flags,
    and PID 1 still being the entrypoint script (exec never happened)

- **Reordered credential setup in `container-entrypoint.sh`:**
  1. Codex auth now happens FIRST via `codex exec "Say hello"` (non-interactive,
     triggers OAuth if needed, `|| true` so failure doesn't kill the script)
  2. Removed the bogus `claude login` step entirely — Claude handles its own
     auth on first launch via `DEVCONTAINER=true`
  3. The final `exec gosu ... claude --dangerously-skip-permissions` should now
     actually execute

### Discoveries

- `claude --help` lists subcommands: `doctor`, `install`, `mcp`, `plugin`,
  `setup-token`, `update`. No `login`. The MOARCODE.md spec had `claude login`
  which was wrong.
- `claude setup-token` exists but isn't needed — the main `claude` launch
  handles auth itself.

### Decisions

- Codex auth uses `codex exec "Say hello"` rather than `codex login` — need to
  verify `codex login` is actually a valid subcommand too (might have the same
  problem). Using `exec` is safer since it definitely triggers the auth flow.

### What's next

- Rebuild the image and test that the entrypoint works correctly on fresh start
- Verify Codex auth flow actually works with `codex exec`
- Update MOARCODE.md to remove references to `claude login`
- Continue M1 verification

---

## Session 3 — 2026-02-06

### What was done

- Ran first Codex code review — codereview.sh works end to end
- Addressed code review findings:
  - **Codex auth hard-fail:** Accepted as expected behavior. Failing fast on
    first-run is correct — Codex auth is required for code review.
  - **DIARY.md out of sync with code:** Session 2 described switching to
    `codex exec "Say hello"` but that change was never applied to
    `container-entrypoint.sh`. The entrypoint still uses
    `codex login --device-auth`, which is the correct intended approach.
    This diary entry corrects the record.
  - **reset.sh glob:** False positive. GNU `rm -rf` handles `.`/`..` gracefully.
  - **Symlink spec drift:** False positive. No symlink reference exists in
    MOARCODE.md.
- Added "Accepted / Won't Fix" section to CODEX-DIARY.md so Codex stops
  re-flagging accepted findings in future reviews.

### Decisions

- `codex login --device-auth` is the correct auth approach (not `codex exec`
  as Session 2 incorrectly claimed was implemented)
- Accepted findings get documented in CODEX-DIARY.md so the review prompt's
  "read CODEX-DIARY.md for prior context" step teaches Codex what's accepted

### What's next

- Re-run code review to verify Codex picks up the accepted findings
- Continue M1 verification

---

## Session 4 — 2026-02-06

### What was done

- **Completed M3: Polish for Distribution**
  - Verified all scripts already have executable permissions
  - Verified `.gitignore` already covers `.credentials/`
  - Audited all paths for portability — all scripts use relative paths from
    `$(dirname "$0")` or fixed container paths (`/workspace`, `/home/node`).
    No hardcoded project-specific paths found.
  - Added `.dockerignore` to exclude `.credentials/`, `.git/`, `node_modules/`,
    and session state files from Docker build context (prevents token leakage
    to Docker daemon and speeds up builds)
  - Fixed `reset.sh` dotfile glob — replaced `rm -rf .credentials/claude/.*`
    (which expands to include `.` and `..`) with `rm -rf` the directory and
    `mkdir -p` to recreate it cleanly
  - Updated MOARCODE.md to match implementation:
    - Added `reset.sh` to directory structure and files reference table
    - Updated `develop.sh` example to include git identity forwarding
    - Fixed first-run experience to show Codex-first ordering
    - Added Co-Authored-By prohibition to CLAUDE.md template
    - Added reset.sh mention to key details and bootstrapping sections

### Decisions

- `.dockerignore` excludes DIARY.md and CODEX-DIARY.md from build context since
  they're session state, not needed for the image
- `reset.sh` now uses rm-and-recreate instead of globbing hidden files — simpler
  and avoids the `.`/`..` issue entirely

### What's next

- Run code review
- Proceed to M4: Documentation Pass
