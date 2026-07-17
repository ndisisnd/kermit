---
name: kermit
description: Format and run git commits using Conventional Commits style with emoji prefix, point-form file bodies, and BREAKING CHANGE footer. Manages CHANGELOG.md via hooks. Use --init to initialize changelog.
model: sonnet
allowed_tools:
  - Bash
  - AskUserQuestion
refs:
  - refs/protocol-init.md
  - refs/protocol-commit.md
  - refs/protocol-pr.md
  - refs/protocol-release.md
  - refs/protocol-changelog-sync.md
  - refs/template-release.md
  - refs/changelog-protocol.md
  - refs/changelog-reset.md
---

## Usage

**Invoke**: `/kermit [--pr] [--init] [--changelog-reset] [--changelog-sync] [--release]` — "commit this", "make a commit", "commit my changes"

**Natural-language routing** (no flag needed): PR intent ("make/open/raise a PR", "open a pull request to `<base>`", "PR this branch") → `--pr`; if the user names a base ("…to `develop`"), use it as the PR base. Release intent ("write release notes", "cut a release", "do a release") → `--release`. Changelog-backfill intent ("check my changelog", "log missing commits", "sync the changelog", "backfill the changelog") → `--changelog-sync`. Otherwise commit intent → the default commit flow.

- `--pr`: run the **PR protocol** (`refs/protocol-pr.md`) — open/update a GitHub pull request for the current branch via `gh`. Operates on commits already on the branch; does **not** create a commit.
- `--init`: re-run the full init block regardless of prior initialization, then exit.
- `--changelog-reset [--apply]`: rewrite the existing changelog to current conventions (entries grouped under `## <date>` sections, numbered `### [N]`, normalised bullets); shows a diff and confirms before writing (`--apply` skips the confirm), then exits.
- `--changelog-sync`: run the **changelog-sync protocol** (`refs/protocol-changelog-sync.md`) — find commits that landed without a changelog entry, report them, and backfill the missing entries. Writes only the changelog; makes no commit.
- `--release`: run the **release protocol** (`refs/protocol-release.md`) — write user-facing release notes to `RELEASES.md` for the changes since the last release, organised by type with a highlight summary, then commit them (bumping `package.json`'s version) and publish a GitHub release via `gh`. Operates on committed history; the only commit it makes is the release commit itself.

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
| backfilled entries (changelog-sync mode) | prose | written to the changelog; no commit made |
| git commit / push | shell | run on user confirmation |
| pull request (PR mode) | shell | created/updated via `gh pr create`/`gh pr edit`, URL shown |
| RELEASES.md notes (release mode) | prose | prepended, then committed with a `package.json` version bump |
| GitHub release (release mode) | shell | published via `gh release create v<x.y.z>`, URL shown |

## Protocol

Four protocol modes, each in its own ref:

- **Commit** (default) — `refs/protocol-commit.md`: format a message, gate it, commit, and optionally push.
- **PR** — `refs/protocol-pr.md`: open/update a pull request for the current branch.
- **Release** — `refs/protocol-release.md`: write release notes, commit them, publish a GitHub release.
- **Changelog-sync** — `refs/protocol-changelog-sync.md`: backfill changelog entries for commits that landed without one.

kermit keeps two files under `.claude/kermit/`: **`pref.json`** holds stable config
(`initialized`, `init_commit`, `changelog.*`, `release_guard`, `gate_mode`) and is safe to
commit; **`state.json`** holds volatile runtime state (`last_logged_commit`, `last_number`,
`last_released_number`, `backfill`) that is rewritten on every commit and must stay git-ignored. Both are read
**once** at the mode-check step below — cache their values for the rest of the run rather
than re-reading either file in later steps.

### Mode check (runs before everything else)

- **`--changelog-reset`** → read `refs/changelog-reset.md`, follow it end-to-end, then **exit** — do not run the commit flow.
- **Otherwise** → read `.claude/kermit/pref.json` and `.claude/kermit/state.json`. If pref is absent, create it with `{"initialized":false}`. If `initialized` is `false` **or** `--init` was passed: read `refs/protocol-init.md` and follow it end-to-end, then continue as it directs. Otherwise fall through to the protocol dispatch below.
  - **Legacy migration.** Older prefs kept the state fields inside `pref.json`. If `state.json` is absent, create it now — seed `last_logged_commit` from `pref.last_logged_commit`, `last_number` from `pref.changelog.last_number`, `last_released_number` to `0`, and `backfill` from `pref.backfill` (each defaulting to `null`/`0` when the legacy key is missing), then rewrite `pref.json` without those three keys and ensure `.claude/kermit/state.json` is in `.gitignore` (`grep -qxF '.claude/kermit/state.json' .gitignore 2>/dev/null || printf '.claude/kermit/state.json\n' >> .gitignore`). Cache the migrated state for the run.

### Protocol dispatch

Select the protocol mode and read its ref, then follow it end-to-end:

- `--release` was passed → read **`refs/protocol-release.md`** and follow it.
- `--pr` was passed → read **`refs/protocol-pr.md`** and follow it.
- `--changelog-sync` was passed → read **`refs/protocol-changelog-sync.md`** and follow it.
- Otherwise (default commit flow) → read **`refs/protocol-commit.md`** and follow it.

---

Dedicated to JC 💕
