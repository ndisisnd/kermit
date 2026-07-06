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
  - refs/changelog-reset.md
---

## Usage

**Invoke**: `/kermit [--init] [--changelog-reset] [--workflows] [--release] [--deploy]` — "commit this", "make a commit", "commit my changes"

- `--init`: re-run the full init block regardless of prior initialization, then exit
- `--changelog-reset [--apply]`: rewrite the existing changelog to the latest conventions (adds `## [N]` numbering, normalises headings/dates/bullets); shows a diff and asks before writing (`--apply` skips the confirm), then exits
- `--workflows`: (re)run **only** the Release/Deploy workflow setup — enable workflows and scaffold the missing `release.yml`/`deploy.yml` templates — then exit. Use this to turn workflows on later if you declined during `--init`; the normal commit flow never re-prompts for this on its own
- `--release` / `--deploy`: skip the "Trigger a workflow?" question in step 7 and go straight to a Release (version bump + publish) or a Deploy (put the commit live in an environment). Both dispatch the repo's GitHub Actions workflows via `gh`; both still run the full commit flow first.

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

### Mode check (runs before everything else)

**If `--changelog-reset` was passed**: read `refs/changelog-reset.md`, follow it end-to-end,
then **exit** — do not run the commit flow.

**If `--workflows` was passed**: read `.claude/kermit/pref.json`. If it is absent or
`initialized` is `false`, fall through to the normal init below instead (the full `--init`
flow already covers workflow setup). Otherwise read `refs/init.md` and run **only its step 3
(Workflow setup)** against the existing pref: ask whether to enable Release/Deploy workflows,
and on `Yes` set `workflows.enabled: true` and offer to scaffold any missing
`release.yml`/`deploy.yml` templates (never overwrite existing files). Write the resulting
`workflows` object back into `.claude/kermit/pref.json` in a single merged write, preserving
all other keys. Then **exit** — do not run the commit flow.

Otherwise, read `.claude/kermit/pref.json`. If the file is absent, create it with
`{"initialized":false}`. If `initialized` is `false` **or** `--init` was passed:
read `refs/init.md` and follow it end-to-end, then continue as it directs.
Otherwise skip straight to step 1.

---
1. Detect rtk: `which rtk >/dev/null 2>&1 && RTK=rtk || RTK=`. If rtk is absent, `$RTK` is empty and all commands run as plain `git` — no rtk required. Also detect the GitHub CLI for step 7: `gh auth status >/dev/null 2>&1 && GH_OK=1 || GH_OK=0` (used only to decide whether the workflow gate can run — never block a commit on it). Emit `(1) Reading latest git diff...` Run `$RTK git diff --staged`.

2. Emit `(2) Writing commit message...` Produce a Conventional Commits message:
   - Line 1: `<emoji> <type>[(<scope>)][!]: <description>` — ≤72 chars total; description is lowercase imperative; `!` and `BREAKING CHANGE` footer are both required for breaking changes. Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`. Pick an emoji matching the type (e.g. ✨ feat, 🐛 fix, 📝 docs, ♻️ refactor, 🚀 perf, ✅ test, 🔧 chore).
   - Blank line
   - Body: `- <file> — <descriptor>` per changed file; keep terse unless the change is large or impactful
   - Footer (if breaking): `BREAKING CHANGE: <description>` — mandatory for any breaking change, never omit
   - **Never add AI co-authorship or attribution trailers** (e.g. `Co-Authored-By: Claude …`, `Co-Authored-By: <any AI>`, `Generated with …`). The commit is the user's — omit these always, and strip any that appear when revising a message.

3. Emit `(3) Proposed commit message:` in a code block. If `auto_approve` is `true` in pref.json, skip the question and proceed as approved. Otherwise use `AskUserQuestion` — question: `Approve or revise?`, options: `approve`, `revise`. On revise: use `AskUserQuestion` — question: `What would you like to revise?`, options: `more explicit changes`, `less vague title`, `fix linting / formatting`, `other (I'll describe)`. Incorporate the feedback, rewrite the message, and return to 3.
   After the message is approved, emit: `💡 If you commit this manually or close the session before step 5 completes, run \`/log-it\` afterward to sync the changelog.`
4. If `auto_commit` is `true` in pref.json, skip the question and proceed as `yes`. Otherwise use `AskUserQuestion` — question: `(4) Run git commit on your behalf?`, options: `yes`, `no`. On no: emit `Tip: if you commit manually later, run \`/log-it\` to update the changelog.` and terminate.
5. Emit `(5) Updating changelog and committing...`
   - If `CHANGELOG_EXISTS=1` in cache: append an entry following the user's changelog format — read `changelog.protocol` from pref.json; if it is an object, honour its `summary`/`fields`/`show_files`/`flag_breaking` (or free-text `description`) when writing the entry. Only if `changelog.protocol` is `null`, read `refs/changelog-protocol.md` now and follow it. **Number the entry** (unless a custom `changelog.protocol` sets `"number": false`): read `changelog.last_number` from pref (if absent, use the highest existing `## [k]` in the file, ignoring `## v…` markers, else 0); let `N = that + 1` and write the heading as `## [N] — <summary>`. kermit commits one at a time, so exactly one numbered entry is written per run. After writing the changelog, update `.claude/kermit/pref.json` in a single write: set `"last_logged_commit"` to the current HEAD SHA (`git log -1 --format="%H"`) **and** `changelog.last_number` to `N`, preserving all other keys.
   - If `CHANGELOG_EXISTS=0`: Stop hook initializes after session
   Run `$RTK git commit -m "<approved message>"`
6. If `auto_merge` is `true` in pref.json, skip the question and proceed as `yes`. Otherwise use `AskUserQuestion` — question: `(6) Push to remote?`, options: `yes`, `no`. On yes: run `$RTK git push`.
7. **Trigger a workflow?** Run this step only if the push in step 6 happened, `workflows.enabled` is `true` in pref.json, and `GH_OK=1` (from step 1). If any is false, skip step 7 silently — but if `workflows.enabled` is `true` and `GH_OK=0`, emit once: `💡 Install & auth the GitHub CLI to trigger workflows: gh auth login`, then skip.
   - **Choose the action.** If `--release` or `--deploy` was passed, use it directly. Else if `workflows.auto` is `release:<bump>` or `deploy:<env>`, use that. Otherwise use `AskUserQuestion` — question: `(7) Trigger a workflow?`, options: `Release`, `Deploy`, `No`. On `No`: terminate.
   - **Release** → pick the bump: `AskUserQuestion` — question: `Release — which bump?`, options: `patch`, `minor`, `major` (skip if `--release=<bump>`/auto already names one). Run `$RTK gh workflow run "$(node -p "require('./.claude/kermit/pref.json').workflows.release_file" 2>/dev/null || echo release.yml)" -f bump=<bump>`. Then emit the run: `$RTK gh run list --workflow=release.yml -L1`.
   - **Deploy** → pick the environment: `AskUserQuestion` — question: `Deploy — which environment?`, options sourced from `workflows.environments` in pref.json (fallback `staging`, `production`). Run `$RTK gh workflow run "$(node -p "require('./.claude/kermit/pref.json').workflows.deploy_file" 2>/dev/null || echo deploy.yml)" -f environment=<env>`. Then emit `$RTK gh run list --workflow=deploy.yml -L1`.

---

Dedicated to JC 💕