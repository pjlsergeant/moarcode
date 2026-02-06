# CLAUDE.md

## Project Overview

This project builds **moarcode** — a bolt-on AI development environment that enables
unsupervised development using Claude Code with Codex as an autonomous code reviewer.

## What We're Building

The `moarcode/` directory in this repo IS the distributable template. When complete,
users will clone it into their projects and use it to run AI-assisted development
in a Docker container.

## AI Development Environment

> **REQUIRED:** Before starting any work, you MUST read:
> 1. `moarcode/CLAUDE.md` for workflow instructions
> 2. `moarcode/IMPLEMENTATION.md` for the build plan
> 3. `README.md` for how it all fits together

Key files in moarcode/:
| File | Purpose |
|------|---------|
| `CLAUDE.md` | Workflow rules (commits, code review, diaries) |
| `IMPLEMENTATION.md` | Milestones and detailed build plan |
| `DIARY.md` | Your progress log — update after each session |
| `CODEX-DIARY.md` | Code review history from Codex |
| `codereview.sh` | Run this for code review: `/workspace/moarcode/codereview.sh` |

**Start each session by reading these files. Update DIARY.md when you finish.**

## Bootstrapping Note

We are building moarcode using moarcode. The `moarcode/` directory contains both:
1. The actual scripts/config we're developing
2. The workflow instructions for developing them

This is intentional — it proves the system works.
