# CODEX Diary

Code review history and findings. Updated by Codex during each review.

---

(No reviews yet)

---

## Review — 2026-02-06 18:58:41 +0000

### Findings

1. **Container can fail to start if Codex auth fails (blocking Claude).**
   - `moarcode/container-entrypoint.sh` runs `codex login --device-auth` under `set -e`. If login fails (invalid subcommand, network issue, device flow failure), the entrypoint exits and the container never reaches the Claude session. This is a hard failure on first run, even though Codex is optional for day-one usage. Consider a non-fatal auth attempt (warn and continue) or defer Codex auth until `codereview.sh` is invoked.

2. **Potential mismatch between `codex login` and CLI reality.**
   - `moarcode/container-entrypoint.sh` uses `codex login --device-auth`. The DIARY notes that `claude login` was invalid; `codex login` may also be invalid or behave differently across versions. If invalid, the entrypoint exits due to `set -e`, which is a critical startup bug. This should be validated and made robust (e.g., use `codex exec "Say hello" || true` as the DIARY suggested, or check `codex --help` to confirm the command before using it).

3. **UID/GID mapping may leave `$HOME` unwritable for non-1000 hosts.**
   - The entrypoint maps to host UID/GID but does not `chown` `/home/node` (only `/workspace/node_modules`). On hosts where the user is not UID 1000, the mapped user may not be able to write to `$HOME`, which is required for many tools and for Claude/Codex caches. This can cause subtle auth and runtime failures. You likely need to `chown` `$TARGET_HOME` (or at least relevant subpaths) when `TARGET_UID` differs.

4. **Spec deviation: missing codex symlink but docs still reference it.**
   - `MOARCODE.md` specifies a `/opt/homebrew/bin/codex` symlink in the Dockerfile, and `codereview.sh` in the spec uses that path. The current Dockerfile omits the symlink and `codereview.sh` uses `command -v codex` instead. That’s fine technically, but the spec and implementation are now out of sync. Either restore the symlink or update `MOARCODE.md` to match the new behavior.

### Notes

- M1 tasks (running `./develop.sh`, verifying logins, and running code review) are still unchecked in `moarcode/IMPLEMENTATION.md`. That’s expected per the diary, but the above issues should be addressed before M1 can pass.

---

## Review — 2026-02-06 19:09:09 +0000

### Findings

1. **Container startup can still hard-fail on Codex auth.**
   - `moarcode/container-entrypoint.sh` runs `codex login --device-auth` under `set -e` without `|| true`. If the subcommand is invalid, the device flow is interrupted, or the network is unavailable, the entrypoint exits and Claude never starts. This blocks M1 and makes first-run fragile. Use the non-interactive `codex exec "Say hello" || true` approach described in `moarcode/DIARY.md`, or at least make the auth attempt non-fatal.

2. **DIARY claims a Codex auth change that is not reflected in code.**
   - `moarcode/DIARY.md` says Codex auth was switched to `codex exec "Say hello"`, but `moarcode/container-entrypoint.sh` still uses `codex login --device-auth`. This is a documentation/implementation mismatch that will mislead anyone trying to follow the recorded decisions.

3. **`reset.sh` can fail due to dotfile removal pattern.**
   - `moarcode/reset.sh` runs `rm -rf .credentials/claude/.*` and `rm -rf .credentials/codex/.*` under `set -e`. This expands to `.` and `..`, which `rm` refuses to remove, causing the script to exit non-zero and leaving credentials uncleared. Use a safer glob (e.g., `.[!.]*` and `..?*`) or `find` to delete hidden files without touching `.`/`..`.

4. **Spec drift: codex symlink documented but not implemented.**
   - `MOARCODE.md` specifies a `/opt/homebrew/bin/codex` symlink in the Dockerfile, but the current Dockerfile does not create it and `codereview.sh` relies on `command -v`. Either add the symlink or update the spec to match the implementation.

### Notes

- M1 verification tasks in `moarcode/IMPLEMENTATION.md` are still unchecked, which aligns with `moarcode/DIARY.md`. The above issues should be addressed before M1 can pass reliably.
