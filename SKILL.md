---
name: kermit
description: Format and run git commits using Conventional Commits style with emoji prefix, point-form file bodies, and BREAKING CHANGE footer. Manages CHANGELOG.md via hooks. Use --init to initialize changelog.
model: claude-sonnet-4-6
allowed_tools:
  - Bash
  - AskUserQuestion
refs:
  - refs/init.md
  - refs/changelog-protocol.md
---

## Usage

**Invoke**: `/kermit [--init]` — "commit this", "make a commit", "commit my changes"

- `--init`: re-run the full init block regardless of prior initialization, then exit

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

### Init check (runs before everything else)

Read `.claude/kermit/pref.json`. If the file is absent, create it with
`{"initialized":false}`. If `initialized` is `false` **or** `--init` was passed:
read `refs/init.md` and follow it end-to-end, then continue as it directs.
Otherwise skip straight to step 1.

---
1. Detect rtk: `which rtk >/dev/null 2>&1 && RTK=rtk || RTK=`. If rtk is absent, `$RTK` is empty and all commands run as plain `git` — no rtk required. Emit `(1) Reading latest git diff...` Run `$RTK git diff --staged`.

2. Emit `(2) Writing commit message...` Produce a Conventional Commits message:
   - Line 1: `<emoji> <type>[(<scope>)][!]: <description>` — ≤72 chars total; description is lowercase imperative; `!` and `BREAKING CHANGE` footer are both required for breaking changes. Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`. Pick an emoji matching the type (e.g. ✨ feat, 🐛 fix, 📝 docs, ♻️ refactor, 🚀 perf, ✅ test, 🔧 chore).
   - Blank line
   - Body: `- <file> — <descriptor>` per changed file; keep terse unless the change is large or impactful
   - Footer (if breaking): `BREAKING CHANGE: <description>` — mandatory for any breaking change, never omit

3. Emit `(3) Proposed commit message:` in a code block. If `auto_approve` is `true` in pref.json, skip the question and proceed as approved. Otherwise use `AskUserQuestion` — question: `Approve or revise?`, options: `approve`, `revise`. On revise: use `AskUserQuestion` — question: `What would you like to revise?`, options: `more explicit changes`, `less vague title`, `fix linting / formatting`, `other (I'll describe)`. Incorporate the feedback, rewrite the message, and return to 3.
   After the message is approved, emit: `💡 If you commit this manually or close the session before step 5 completes, run \`/log-it\` afterward to sync the changelog.`
4. If `auto_commit` is `true` in pref.json, skip the question and proceed as `yes`. Otherwise use `AskUserQuestion` — question: `(4) Run git commit on your behalf?`, options: `yes`, `no`. On no: emit `Tip: if you commit manually later, run \`/log-it\` to update the changelog.` and terminate.
5. Emit `(5) Updating changelog and committing...`
   - If `CHANGELOG_EXISTS=1` in cache: append an entry following the user's changelog format — read `changelog.protocol` from pref.json; if it is an object, honour its `summary`/`fields`/`show_files`/`flag_breaking` (or free-text `description`) when writing the entry. Only if `changelog.protocol` is `null`, read `refs/changelog-protocol.md` now and follow it. After writing the changelog, update `.claude/kermit/pref.json`: set `"last_logged_commit"` to the current HEAD SHA (`git log -1 --format="%H"`), preserving all other keys.
   - If `CHANGELOG_EXISTS=0`: Stop hook initializes after session
   Run `$RTK git commit -m "<approved message>"`
6. If `auto_merge` is `true` in pref.json, skip the question and proceed as `yes`. Otherwise use `AskUserQuestion` — question: `(6) Push to remote?`, options: `yes`, `no`. On yes: run `$RTK git push`.

---

Dedicated to JC 💕