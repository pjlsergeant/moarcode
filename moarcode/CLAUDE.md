# moarcode/CLAUDE.md

> **IMPORTANT: After any context compaction or new session, STOP and re-read:**
> 1. The root `/workspace/CLAUDE.md`
> 2. This file (`moarcode/CLAUDE.md`)
> 3. `moarcode/IMPLEMENTATION.md`
> 4. `moarcode/DIARY.md` (your previous progress)

## Development Flow

### Autonomy

You have permission to keep going. Don't stop to ask "should I continue?" after
each step — proceed through the milestones.

However, **ask yourself: "Am I going in circles?"** Stop and ask for help if:
- You've tried the same fix 2-3 times without success
- You're unsure which approach is correct
- A test keeps failing and you don't understand why

### Code Review (MANDATORY)

**STOP. After completing ANY feature, fix, or milestone:**

```bash
/workspace/moarcode/codereview.sh
```

**DO NOT proceed until code review passes.**

The code review loop:
1. Run `/workspace/moarcode/codereview.sh`
2. Read ALL findings from the script output (do NOT read CODEX-DIARY.md directly — that is Codex's persistent memory)
3. For each finding: fix it OR document why you're ignoring it in CODEX-DIARY.md
4. If you made ANY fixes → go back to step 1
5. Only proceed when clean or all remaining issues are documented

### Commit Frequently

> **Before writing more code: "Do I have uncommitted work?"**
> If yes, COMMIT IT NOW.

If `git status` shows more than ~5 changed files, you've waited too long.

Commit after each coherent unit:
- After implementing a function and its tests — COMMIT
- After fixing a bug — COMMIT
- After refactoring that keeps tests green — COMMIT
- Before trying a risky change — COMMIT

Commit message format: `M<N>: Description` where N is the milestone number.

### Diary Updates

Update `moarcode/DIARY.md` after each session:
- What was implemented
- Discoveries or surprises
- Decisions made and why
- Code review feedback addressed
- What's next

### Before Moving to Next Milestone

1. Commit all work
2. Run code review loop until clean
3. Commit any fixes
4. Update DIARY.md
5. THEN start next milestone
