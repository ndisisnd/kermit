---
name: kermit
description: Format and run git commits with emoji summaries, point-form file bodies, and BREAKING notation. Manages CHANGELOG.md via hooks. Use --init to initialize changelog.
model: claude-sonnet-4-6
allowed_tools:
  - Bash
  - AskUserQuestion
---

## Usage

**Invoke**: `/kermit [--init]` — "commit this", "make a commit", "commit my changes"

- `--init`: initialize CHANGELOG.md if absent, then exit

## Inputs

| Name | Format | Source |
|------|--------|--------|
| staged diff | text | `git diff --staged` (rtk-prefixed if available) |
| changelog flag | bool | `/tmp/commit_cl_cache` (PreToolUse hook) |

## Outputs

| Name | Format | Destination |
|------|--------|-------------|
| commit message | text | shown inline for approval |
| CHANGELOG.md entry | prose | appended on confirmed commit |
| git commit / push | shell | run on user confirmation |

## Protocol

If `--init`: `[ -f CHANGELOG.md ] || printf '# Changelog\n\nAll notable changes documented here.\n' > CHANGELOG.md`. Emit result. END.
1. Detect rtk: `which rtk >/dev/null 2>&1 && RTK=rtk || RTK=`. Emit `(1) Reading latest git diff...` Run `$RTK git diff --staged`.

2. Emit `(2) Writing commit message...` Produce:
   - Line 1: emoji + ≤72-char imperative summary
   - Line 2: one-sentence elaboration (omit if summary is self-contained)
   - Body: `- <file> — <descriptor>` per changed file; keep terse unless the change is large or impactful
   - BREAKING: prepend `BREAKING CHANGE: <description>` before file list — mandatory, never omit

3. Emit `(3) Proposed commit message:` in a code block. Use `AskUserQuestion` — question: `Approve or revise?`, options: `approve`, `revise`. On revise: apply correction and return to 2.
4. Use `AskUserQuestion` — question: `(4) Run git commit on your behalf?`, options: `yes`, `no`. On no: terminate — no git, no changelog.
5. Emit `(5) Updating changelog and committing...`
   - If `CHANGELOG_EXISTS=1` in cache: append — date header, prose summary, BREAKING note if any, files in order (terse unless large/impactful)
   - If `CHANGELOG_EXISTS=0`: Stop hook initializes after session
   Run `$RTK git commit -m "<approved message>"`
6. Use `AskUserQuestion` — question: `(6) Push to remote?`, options: `yes`, `no`. On yes: run `$RTK git push`.
