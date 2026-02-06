# Architecture

How moarcode works under the hood. You don't need to read this to use it — this is for understanding or modifying the internals.

## Container setup

The Dockerfile installs Claude Code and Codex via npm, plus tools they need (git, ripgrep, jq, etc.). Key environment variables:

- `DEVCONTAINER=true` — makes Claude skip some interactive prompts
- `CLAUDE_CONFIG_DIR=/home/node/.claude` — where credentials are bind-mounted
- `gosu` — maps container user to host UID/GID so bind-mounted files have correct ownership

The full Dockerfile is at `moarcode/Dockerfile`.

## Entrypoint (`container-entrypoint.sh`)

Runs as root, then drops to the host user's UID/GID via `gosu`.

1. Creates passwd/group entries for the host UID if needed
2. Fixes ownership on `/home/node` and `node_modules` if UID differs
3. If Codex credentials are missing, runs `codex login --device-auth`
4. Execs into `claude --dangerously-skip-permissions` (or whatever command was passed)

Claude handles its own auth on first launch — there's no separate login step for it.

## develop.sh

Runs on the host. Builds the Docker image, creates a named volume for `node_modules`, and starts the container with:

- Project root mounted at `/workspace`
- Credentials mounted from `moarcode/.credentials/`
- Host git identity forwarded via environment variables
- `NET_ADMIN` and `NET_RAW` capabilities (for the optional firewall)

The project name (used for the Docker image and volume) is read from `moarcode/.project-name`, which is set during `install.sh`. Falls back to the parent directory name if missing.

## codereview.sh

Runs inside the container. Reads `CODEX-REVIEW-PROMPT.md` and passes it to `codex exec`. Codex reads the codebase, writes findings to `CODEX-DIARY.md`, and returns a report. Temp files go to `moarcode/tmp/` (gitignored).

## Network sandbox (optional)

`init-firewall.sh` uses iptables to restrict outbound traffic to DNS (53), HTTP (80), and HTTPS (443). IPv4 only — IPv6 is not covered. Run it manually inside the container:

```bash
sudo /usr/local/bin/init-firewall.sh
```

## install.sh

Runs on the host from the source repo — it is not copied into the target project. Prompts for a project name (saved to `moarcode/.project-name`), copies moarcode files excluding credentials, `.git`, `node_modules`, `tmp`, and session-specific files. Creates fresh templates for `DIARY.md`, `CODEX-DIARY.md`, and `IMPLEMENTATION.md`. Prepends a moarcode pointer to the top of the project's `CLAUDE.md` (or creates one).

## Credential flow

First run:
1. Codex: `codex login --device-auth` in the entrypoint. Opens browser for OAuth.
2. Claude: handled automatically by Claude Code on launch.

Credentials are stored in `moarcode/.credentials/claude/` and `moarcode/.credentials/codex/`, which are bind-mounted into the container. They persist across container restarts. Run `reset.sh` to clear them.

## Git identity

`develop.sh` reads `git config user.name` and `git config user.email` from the host and passes them into the container as `GIT_AUTHOR_NAME`, `GIT_COMMITTER_NAME`, `GIT_AUTHOR_EMAIL`, `GIT_COMMITTER_EMAIL`. This means commits made by Claude inside the container are attributed to the developer, not to the generic "AI Developer" configured in the Dockerfile.

## Templates

The workflow templates (`moarcode/CLAUDE.md`, `CODEX-REVIEW-PROMPT.md`) are installed into each project and can be edited freely. The `CLAUDE.md` template controls how Claude behaves — commit frequency, code review rules, diary updates. The `CODEX-REVIEW-PROMPT.md` controls what Codex focuses on during review.
