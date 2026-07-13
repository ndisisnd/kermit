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

**Natural-language routing** (no flag needed): PR intent ("make/open/raise a PR", "open a pull request to `<base>`", "PR this branch") → `--pr`; if the user names a base ("…to `develop`"), use it as the PR base. Otherwise commit intent → the default commit flow.

- `--pr`: run the **PR protocol** (`refs/protocol-pr.md`) — open/update a GitHub pull request for the current branch via `gh`. Operates on commits already on the branch; does **not** create a commit.
- `--init`: re-run the full init block regardless of prior initialization, then exit.
- `--changelog-reset [--apply]`: rewrite the existing changelog to current conventions (`## [N]` numbering, normalised headings/dates/bullets); shows a diff and confirms before writing (`--apply` skips the confirm), then exits.
- `--workflows`: (re)run **only** the Release/Deploy workflow setup — enable workflows and scaffold the missing `release.yml`/`deploy.yml` templates — then exit. Use it to turn workflows on later if you declined during `--init`; the normal commit flow never re-prompts for this.
- `--release` / `--deploy`: run the full commit flow first, then skip the step-7 "Trigger a workflow?" question and go straight to a Release (version bump + publish) or Deploy (put the commit live in an environment), dispatched via `gh`.

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

Two protocol modes, each in its own ref:

- **Commit** (default) — `refs/protocol-commit.md`: format a message, gate it, commit, optionally push and trigger a workflow.
- **PR** — `refs/protocol-pr.md`: open/update a pull request for the current branch.

`.claude/kermit/pref.json` is read **once** at the mode-check step below — cache its
values (`gate_mode`, `changelog.*`, `workflows.*`) for the rest of the run rather than
re-reading the file in later steps.

### Mode check (runs before everything else)

- **`--changelog-reset`** → read `refs/changelog-reset.md`, follow it end-to-end, then **exit** — do not run the commit flow.
- **`--workflows`** → read `.claude/kermit/pref.json`. If it is absent or `initialized` is `false`, fall through to the normal init below (the full `--init` flow already covers workflow setup). Otherwise read `refs/init.md` and run **only its step 3 (Workflow setup)** against the existing pref: ask whether to enable Release/Deploy workflows, and on `Yes` set `workflows.enabled: true` and offer to scaffold any missing `release.yml`/`deploy.yml` templates (never overwrite existing files). Merge-write the resulting `workflows` object back into `.claude/kermit/pref.json` in a single write, preserving all other keys. Then **exit** — do not run the commit flow.
- **Otherwise** → read `.claude/kermit/pref.json`. If the file is absent, create it with `{"initialized":false}`. If `initialized` is `false` **or** `--init` was passed: read `refs/init.md` and follow it end-to-end, then continue as it directs. Otherwise fall through to the protocol dispatch below.

### Protocol dispatch

Select the protocol mode and read its ref, then follow it end-to-end:

- `--pr` was passed → read **`refs/protocol-pr.md`** and follow it.
- Otherwise (default commit flow) → read **`refs/protocol-commit.md`** and follow it.

---

Dedicated to JC 💕
