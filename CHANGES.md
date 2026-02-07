# Changes

## 1.0.0 — 2026-02-07

First release.

### Features

- Docker-based development environment with Claude Code + Codex code review
- `install.sh` — one-command setup for new projects (copies template, prompts
  for project name, patches CLAUDE.md)
- `upgrade.sh` — update existing installations without losing project state;
  supports `--yes` for batch/CI upgrades; shows diffs for customized templates
- `develop.sh` — builds image, mounts project + credentials, forwards host git
  identity, starts Claude in autonomous mode
- `codereview.sh` — runs Codex code review with directed focus support
- `codereview.sh --continue` — resumes the previous review session for faster
  fix-and-recheck loops (session ID captured from `codex exec --json`)
- `reset.sh` — clears cached credentials for a fresh login
- `init-firewall.sh` — optional iptables sandbox (DNS/HTTP/HTTPS only)
- Workflow templates: `CLAUDE.md` (commit rules, review loop, diary updates),
  `CODEX-REVIEW-PROMPT.md` (review focus areas)
- `IMPLEMENTATION.md` template with M0 plan-first orientation step
- Credential caching across container restarts via bind-mounted `.credentials/`
