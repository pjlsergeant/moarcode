# moarcode

Unsupervised AI development in a Docker container. Claude Code writes the code, Codex reviews it.

## Install

```bash
cd your-project
/path/to/moarcode/install.sh
cd moarcode
./develop.sh
```

The install script copies moarcode into your project, adds it to `.gitignore`, and sets up `CLAUDE.md`. First run will prompt you to log in to both Claude and Codex via the browser. After that, credentials are cached.

## What happens

`develop.sh` builds a Docker image and drops you into a container with your project mounted at `/workspace`. Claude starts in fully autonomous mode (`--dangerously-skip-permissions`).

Claude follows `moarcode/IMPLEMENTATION.md` milestone by milestone. After each milestone, it runs `codereview.sh`, which invokes Codex to review the changes. Claude fixes what Codex flags, commits, and moves on.

```
You (host)                    Docker container
    |                              |
    |  cd moarcode && ./develop.sh |
    |----------------------------->|
    |                              |  Claude writes code
    |                              |  Claude runs codereview.sh
    |                              |    -> Codex reviews, writes findings
    |                              |  Claude fixes issues
    |                              |  Claude commits
    |                              |  ...next milestone
```

Everything lives in `moarcode/` which is gitignored. Your project stays clean.

## Files

| File | What it does |
|------|-------------|
| `develop.sh` | Builds image, launches container (run from host) |
| `codereview.sh` | Runs Codex code review (run from inside container) |
| `install.sh` | Copies moarcode into a project (source repo only) |
| `reset.sh` | Clears saved credentials |
| `CLAUDE.md` | Workflow rules Claude follows |
| `IMPLEMENTATION.md` | Milestone plan (Claude helps you write this) |
| `DIARY.md` | Claude's progress log |
| `CODEX-DIARY.md` | Codex's review history |
| `CODEX-REVIEW-PROMPT.md` | The prompt sent to Codex (editable) |
| `.credentials/` | OAuth tokens (gitignored) |

## How the first session works

The default `IMPLEMENTATION.md` starts with M0: "Understand the Project." Claude reads your codebase, asks what you want to build, and drafts the milestones with you. You confirm the plan, and it gets to work.

## Customizing

- Edit `CODEX-REVIEW-PROMPT.md` to change what Codex focuses on during review.
- Edit `moarcode/CLAUDE.md` to change Claude's workflow rules.
- Run `sudo /usr/local/bin/init-firewall.sh` inside the container to restrict network to HTTP/HTTPS/DNS only.

## Requirements

- Docker
- Git
- A Claude account (for Claude Code)
- An OpenAI account (for Codex)

## Details

See [docs/architecture.md](docs/architecture.md) for the full Dockerfile, entrypoint, and script source with annotations.
