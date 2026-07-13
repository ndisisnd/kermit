---
name: kermit
description: Format and run git commits using Conventional Commits style with emoji prefix, point-form file bodies, and BREAKING CHANGE footer. Manages CHANGELOG.md via hooks. Use --init to initialize changelog.
model: sonnet
allowed_tools:
  - Bash
  - AskUserQuestion
refs:
  - refs/init.md
  - refs/protocol-commit.md
  - refs/protocol-pr.md
  - refs/changelog-protocol.md
  - refs/changelog-reset.md
---

## Usage

**Invoke**: `/kermit [--pr] [--init] [--changelog-reset] [--workflows] [--release] [--deploy]` — "commit this", "make a commit", "commit my changes"

**Natural language routes to a mode — no explicit flag needed:**
- PR intent → treat as **`--pr`**: "make a PR", "make a pull request", "raise/open a PR", "open a pull request to `<base>`", "PR this branch". If the user names a base branch ("…to `develop`"), use it as the PR base instead of the repo default.
- Otherwise (commit intent: "commit this", "commit my changes") → the default commit flow.

- `--pr`: run the **PR protocol** instead of the commit flow — open (or update) a GitHub pull request for the current branch via `gh`. Operates on commits already on the branch; does not create a commit. See `refs/protocol-pr.md`
- `--init`: re-run the full init block regardless of prior initialization, then exit
- `--changelog-reset [--apply]`: rewrite the existing changelog to the latest conventions (adds `## [N]` numbering, normalises headings/dates/bullets); shows a diff and asks before writing (`--apply` skips the confirm), then exits
- `--workflows`: (re)run **only** the Release/Deploy workflow setup — enable workflows and scaffold the missing `release.yml`/`deploy.yml` templates — then exit. Use this to turn workflows on later if you declined during `--init`; the normal commit flow never re-prompts for this on its own
- `--release` / `--deploy`: skip the "Trigger a workflow?" question in step 7 and go straight to a Release (version bump + publish) or a Deploy (put the commit live in an environment). Both dispatch the repo's GitHub Actions workflows via `gh`; both still run the full commit flow first.

## Inputs

| Name | Format | Source |
|------|--------|--------|
| staged diff | text | `git diff --staged` (rtk-prefixed if available) |
| changelog flag | bool | `/tmp/commit_cl_cache` (PreToolUse hook) |
| branch state (PR mode) | text | `git rev-parse` / `git log $BASE..HEAD` / `gh pr view` |

## Outputs

| Name | Format | Destination |
|------|--------|-------------|
| commit message | text | shown inline for approval |
| CHANGELOG.md entry | prose | appended on confirmed commit |
| git commit / push | shell | run on user confirmation |
| pull request (PR mode) | shell | created/updated via `gh pr create`/`gh pr edit`, URL shown |

## Protocol

kermit has two protocol modes, each in its own ref:

- **Commit** (default) — `refs/protocol-commit.md`: format a message, gate it, commit, optionally push and trigger a workflow.
- **PR** — `refs/protocol-pr.md`: open/update a pull request for the current branch.

`.claude/kermit/pref.json` is read once at the mode-check step below — cache its
values (`gate_mode`, `changelog.*`, `workflows.*`) for the rest of the run rather than
re-reading the file in later steps.

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
Otherwise fall through to the protocol dispatch below.

### Protocol dispatch

Select the protocol mode and read its ref, then follow it end-to-end:

- `--pr` was passed → read **`refs/protocol-pr.md`** and follow it.
- Otherwise (default commit flow) → read **`refs/protocol-commit.md`** and follow it.

---

Dedicated to JC 💕