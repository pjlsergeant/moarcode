# moarcode

Unsupervised AI development in a Docker container. Claude Code writes the code, Codex reviews it.

## Why

Claude Code and Codex are both more useful when you let them run without asking permission for every file edit and shell command. The tradeoff is trust — you need to be comfortable with what they're doing.

moarcode solves this by running everything in a disposable Docker container. Your project is bind-mounted in, but the AI tools run sandboxed — they can't touch anything outside the container. So you give them full autonomy (`--dangerously-skip-permissions`) without actually being dangerous.

The other thing moarcode does is pair them up. Claude writes code, then calls Codex to review it. Codex flags issues, Claude fixes them, and the loop continues. You come back to committed, reviewed code.

## Install

```bash
cd your-project
/path/to/moarcode/install.sh
```

This copies the template into `moarcode/`, adds it to `.gitignore`, and sets up your `CLAUDE.md`.

## Usage

```bash
cd moarcode
./develop.sh
```

First run prompts you to log in to Claude and Codex via the browser. After that, credentials are cached in `moarcode/.credentials/`.

Claude starts in fully autonomous mode. It reads `IMPLEMENTATION.md` for its plan. The default plan starts with M0: understand the codebase and draft milestones with you.

## Customizing

- `moarcode/CODEX-REVIEW-PROMPT.md` — change what Codex focuses on during review
- `moarcode/CLAUDE.md` — change Claude's workflow rules (commit frequency, diary format, etc.)
- `sudo /usr/local/bin/init-firewall.sh` inside the container — restrict network to HTTP/HTTPS/DNS only

## Requirements

Docker, Git, a Claude account, an OpenAI account.

## Details

See [docs/architecture.md](docs/architecture.md) for how the container, entrypoint, and scripts work.
