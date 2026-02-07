# moarcode

You design, Claude writes, Codex reviews, and Gemini doesn't get installed

## Why

I have found Claude to be _pretty good_ at writing code, but it's not as conscientious as I'd like. I've found Codex to be _excellent_ at reviewing code, but a fussy and not particularly inspired writer.

I like to discuss an idea with Claude until we've got a decent implementation plan, get Codex to weigh in on that plan, and then just let them go at it, Claude writing, Codex reviewing.

I would like to weigh in only when absolutely needed after that point, so we sandbox this into a Docker container, and let them go at it. This is my workflow for doing that.

## Get it running

Conceptually, you add a moarcode directory to your project, and then run ./develop.sh

```bash
cd your-project
.../path/to/moarcode/install.sh
cd ./moarcode
./develop.sh
```

`install.sh` copies moarcode to your project, adds it to `.gitignore`, and prepends some information about it to your `CLAUDE.md`. You will also need to confirm the project name at this point: it's used to name Docker images and volumes, so you can run moarcode in multiple projects simultaneously.

When you run `./develop.sh` it'll get you to log in to Codex and then Claude, caching your session credentials in `./moarcode/.credentials/`.

Claude starts in fully autonomous mode. It reads `IMPLEMENTATION.md` for its plan. The default plan starts with M0: understand the codebase and draft milestones with you.

## Customizing

- `moarcode/CODEX-REVIEW-PROMPT.md` — change what Codex focuses on during review
- `moarcode/CLAUDE.md` — change Claude's workflow rules (commit frequency, diary format, etc.)
- `sudo /usr/local/bin/init-firewall.sh` inside the container — restrict network to HTTP/HTTPS/DNS only

## Advice

* After compaction, I'd consider just restarting the container. You should have enough state, and if you don't, Claude likes to play a bit faster and looser with what you've asked it
* You may need to remind Claude it needs to take code reviews from Codex. It knows it's meant to, but it can be a little over enthusiastic

## Requirements

Docker, Git, a Claude account, an OpenAI account.

## Details

See [docs/architecture.md](docs/architecture.md) for how the container, entrypoint, and scripts work.
