---
name: log-it
description: Check for git commits not yet reflected in CHANGELOG.md, report the count, and offer to write the missing entries. Companion to kermit — run when a session ends before the changelog was updated.
model: sonnet
allowed_tools:
  - Bash
  - AskUserQuestion
refs:
  - refs/changelog-protocol.md
---

## Usage

**Invoke**: `/log-it` — "check my changelog", "log missing commits", "sync the changelog"

## Inputs

| Name | Format | Source |
|------|--------|--------|
| pref | JSON | `.claude/kermit/pref.json` (optional — used for `changelog.path`) |
| state | JSON | `.claude/kermit/state.json` (optional, git-ignored — holds `last_logged_commit` and `last_number`) |
| changelog | file | path from pref, or discovered via `find` |
| git log | text | `git log <ref>..HEAD` |

## Outputs

| Name | Format | Destination |
|------|--------|-------------|
| unlogged count | text | emitted inline |
| new changelog entries | prose | prepended to changelog file |
| state update | JSON | `.claude/kermit/state.json` — `last_logged_commit` and `last_number` updated after write |

## Protocol

### 1. Setup

Detect rtk: `which rtk >/dev/null 2>&1 && RTK=rtk || RTK=`. All git commands use `$RTK git` or plain `git` if rtk is absent.

### 2. Find changelog path

Read `.claude/kermit/pref.json` if it exists. Look for `changelog.path` — use that path if present.

If pref.json is absent or has no `changelog.path`: search with `find . -maxdepth 3 \( -iname 'changelog*' -o -iname 'history*' \) 2>/dev/null | grep -v node_modules | head -1`.

If no changelog is found after both checks:
- Use `AskUserQuestion` — question: `No changelog found. What would you like to do?`, options: `Init one now (run /kermit --init)`, `I'll give you the path`, `Cancel`.
  - **"Init one now"**: emit `Run \`/kermit --init\` to create a changelog, then re-run \`/log-it\`.` and exit.
  - **"I'll give you the path"**: use `AskUserQuestion` — question: `Enter the changelog file path:`, options: `(type path)`. Use the provided path. If the path does not exist or is not readable, emit `Error: file not found at <path>. Aborting.` and exit.
  - **"Cancel"**: emit `Aborted — no changelog to update.` and exit.

Store the resolved path as `CHANGELOG`.

### 3. Determine the commit range

Read `.claude/kermit/state.json`. If a `"last_logged_commit"` SHA is present, use it as the base: commits = `$RTK git log <last_logged_commit>..HEAD --format="%H %ad %s" --date=short`. (Legacy fallback: if `state.json` is absent but `pref.json` still carries a top-level `last_logged_commit`, use that.)

If `"last_logged_commit"` is absent (kermit hasn't logged yet, or neither file has it):
- Parse the changelog for the most recent date header: `grep -E "^## [0-9]{4}-[0-9]{2}-[0-9]{2}" "$CHANGELOG" | head -1`
- Extract the date string (e.g. `2026-06-08`).
- If a date is found: commits = `$RTK git log --after="<date>" --format="%H %ad %s" --date=short`
  - **Note**: `--after` is exclusive of the given date, so commits ON that date are included in the log. This may include commits already summarised in that day's entry — the user will be warned.
- If no date header is found: commits = all commits (`$RTK git log --format="%H %ad %s" --date=short`).

Collect the result into a list. Count N = number of lines.

### 4. Report

If N = 0: emit `Changelog is up to date — no unlogged commits found.` and exit.

If using date-based fallback and the oldest unlogged commit is ON the same day as the last changelog entry: emit a note — `⚠️  Some commits below may already be covered by the existing <date> entry. Review before confirming.`

Emit:
```
Found <N> commit(s) not reflected in the changelog:

<sha-short> <date> <subject>
...
```

Use `AskUserQuestion` — question: `Write these <N> commit(s) to the changelog?`, options: `Yes, update now`, `No, skip`.

On no: emit `Changelog unchanged. Re-run \`/log-it\` any time to sync.` and exit.

### 5. Write changelog entries

The changelog groups entries by date: a `## <YYYY-MM-DD>` section header with one `### [N] — <summary>` entry per commit beneath it (see `refs/changelog-protocol.md`). **Commits from the same day share one date header** — do not repeat the date.

For each commit in the list (oldest-first):
- Run `$RTK git show <SHA> --stat --format="" | head -30` to get changed files.
- Run `$RTK git show <SHA> -s --format="%s%n%b"` to get subject and body — and note the commit's date (`%ad`, `--date=short`).

Write each entry following the user's changelog format — if pref.json has a `changelog.protocol` object set (from kermit's custom protocol sub-flow), honour its `summary`/`fields`/`show_files`/`flag_breaking` (or free-text `description`). Only if `changelog.protocol` is `null` (or absent), read `refs/changelog-protocol.md` now and follow it.

**Numbering** (unless a custom `changelog.protocol` sets `"number": false`): resolve the starting number once — `last_number` from `.claude/kermit/state.json`, else the highest existing `### [k]` in the file, else 0. Number the commits **oldest→newest** (`start+1 … start+k`), so the newest commit carries the highest `N`.

**Place each entry by date**, working newest-commit-first so higher numbers land above lower ones:
- If the commit's date already has a `## <date>` section in the file, insert its `### [N] — <summary>` entry as the **first** entry under that header (above the day's existing newest entry).
- Otherwise, open a **new** `## <date>` section in the correct chronological position (newest date nearest the top, below the `# Changelog` preamble) and put the entry under it.

Use a temporary file and `mv` to rewrite the file. After writing, emit `Changelog updated — <k> commit(s) logged as [<start+1>..<start+k>].`

### 6. Update state.json

After a successful write, update `.claude/kermit/state.json` in a single write (create it with `{"last_logged_commit":null,"last_number":0,"last_released_number":0,"backfill":null}` first if absent, and ensure `.claude/kermit/state.json` is git-ignored — `grep -qxF '.claude/kermit/state.json' .gitignore 2>/dev/null || printf '.claude/kermit/state.json\n' >> .gitignore`):
- Set `"last_logged_commit"` to the SHA of the most recent commit that was just logged (HEAD).
- Set `"last_number"` to the highest `N` written.
- Preserve all other keys in state.json.

Emit `state.json updated — last_logged_commit set to <short-sha>, last_number set to <N>.`
