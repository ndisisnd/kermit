---
name: kermit
description: Format and run git commits using Conventional Commits style with emoji prefix, point-form file bodies, and BREAKING CHANGE footer. Manages CHANGELOG.md via hooks. Use --init to initialize changelog.
model: claude-sonnet-4-6
allowed_tools:
  - Bash
  - AskUserQuestion
refs:
  - refs/commit-protocol.md
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

Read `.claude/kermit/pref.json`. If the file is absent, create it with `{"initialized":false}`.

If `initialized` is `false` **or** `--init` was passed:
1. Use `AskUserQuestion` — question: `Set up your changelog`, options: `Create a new changelog`, `I already have a changelog`, `I have a CHANGELOG.md but I want to customise how it's written`.
   - **"Create a new changelog"**: create `CHANGELOG.md` with header `# Changelog\n\nAll notable changes to this project will be documented here.\n`. Emit `Changelog created at CHANGELOG.md.` → proceed to **backfill check** below.
   - **"I already have a changelog"**: search the repo for a changelog file — `find . -maxdepth 3 -iname 'changelog*' -o -iname 'history*' -o -iname 'releases*' 2>/dev/null | grep -v node_modules | head -5`. If a file is found, emit the path and use it — **skip backfill check**, go to step 2. If **no file is found**, use `AskUserQuestion` — question: `No changelog file found. What would you like to do?`, options: `Initialise one for me`, `I'll give you the path`. On **"Initialise one for me"**: create `CHANGELOG.md` as above → proceed to **backfill check**. On **"I'll give you the path"**: prompt the user for the path via `AskUserQuestion` (free-text) — **skip backfill check**, go to step 2.
   - **"I have a CHANGELOG.md but I want to customise how it's written"**: locate the changelog with the same `find` as above (if none is found, fall back to the *"No changelog file found"* prompt from the previous option). Then run the **custom protocol sub-flow** below. When it completes, **skip backfill check** and go to step 2.

   **Custom protocol sub-flow** (only runs on the customise option):
   Use `AskUserQuestion` — question: `How do you want to define your changelog format?`, options: `I'll describe it`, `Interview me`.
   - **"I'll describe it"**: use `AskUserQuestion` (free-text) — question: `Describe how entries should be written (summary style, fields, files, breaking changes):`. Store the answer as `{"description":"<free-text>"}`.
   - **"Interview me"**: use a single `AskUserQuestion` call carrying these four questions together:
     1. header `Summary` — question: `How should the summary be written?`, options: `Product goal / outcome`, `Technical description`, `One-line prose`.
     2. header `Fields` (multiSelect) — question: `What should each entry record?`, options: `Commit SHA`, `Date`, `Author`.
     3. header `Files` — question: `Show the touched files in each entry?`, options: `Yes`, `No`.
     4. header `Breaking` — question: `Flag breaking changes prominently?`, options: `Yes`, `No`.
     Store the answers as `{"summary":"<product-goal|technical|prose>","fields":["sha","date","author"],"show_files":<bool>,"flag_breaking":<bool>}`.
   Set `changelog.protocol` in pref.json to the resulting object (create the `"changelog"` object if absent). Emit `Custom changelog format saved to pref.json.`

   **Backfill check** (only runs after a fresh changelog file is created):
   Run `git log --oneline 2>/dev/null | wc -l` to count existing commits. If count > 0:
   Use `AskUserQuestion` — question: `This repo has existing commits. Add them to the changelog?`, options: `Yes, populate it automatically`, `No, ignore past commits`.
   - **"Yes, populate it automatically"**: append a `## History` section to the changelog: `printf '\n## History\n\n' >> <changelog>` then `git log --format="- %ad — %s" --date=short --reverse >> <changelog>`. Emit `Changelog populated with <n> past commits.` Set `backfill` to `"done"` in pref.json.
   - **"No, ignore past commits"**: Set `backfill` to `"skipped"` in pref.json. Emit `Past commits will not appear in the changelog.`
   Either way: record the current HEAD SHA via `git log -1 --format="%H" 2>/dev/null` as `init_commit` in pref.json. Returns empty string on a zero-commit repo — store as `null` in that case.

2. Ask the user their automation preferences sequentially:
   - Use `AskUserQuestion` — question: `Auto-approve commit messages?`, options: `Yes`, `No`. Set `auto_approve` to `true` or `false` accordingly.
   - Use `AskUserQuestion` — question: `Auto-commit after approval?`, options: `Yes`, `No`. Set `auto_commit` to `true` or `false` accordingly.
   - Use `AskUserQuestion` — question: `Auto-push after committing?`, options: `Yes`, `No`. Set `auto_merge` to `true` or `false` accordingly.
   Write `{"initialized":true,"init_commit":"<sha-or-null>","backfill":"<done|skipped|null>","changelog":{"protocol":<object-or-null>},"auto_approve":<bool>,"auto_commit":<bool>,"auto_merge":<bool>}` to `.claude/kermit/pref.json`. `changelog.protocol` is the object set by the custom protocol sub-flow, or `null` when the default `refs/changelog-protocol.md` applies. If `--init` was passed: END. Otherwise: END init block — continue to step 1 below.

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
   - If `CHANGELOG_EXISTS=1` in cache: append an entry following the user's changelog format — read `changelog.protocol` from pref.json; if it is an object, honour its `summary`/`fields`/`show_files`/`flag_breaking` (or free-text `description`) when writing the entry, otherwise use the default `refs/changelog-protocol.md`. The default format is: a `##` summary heading stating the product goal/outcome (fall back to a technical description only when no goal is clear) that surfaces any breaking or large change, the ISO date on its own line, then one bullet per touched file (sub-points for multiple changes to the same file). After writing the changelog, update `.claude/kermit/pref.json`: set `"last_logged_commit"` to the current HEAD SHA (`git log -1 --format="%H"`), preserving all other keys.
   - If `CHANGELOG_EXISTS=0`: Stop hook initializes after session
   Run `$RTK git commit -m "<approved message>"`
6. If `auto_merge` is `true` in pref.json, skip the question and proceed as `yes`. Otherwise use `AskUserQuestion` — question: `(6) Push to remote?`, options: `yes`, `no`. On yes: run `$RTK git push`.

---

Dedicated to JC 💕