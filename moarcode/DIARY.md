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
