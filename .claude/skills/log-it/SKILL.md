---
name: log-it
description: Check for git commits not yet reflected in CHANGELOG.md, report the count, and offer to write the missing entries. Companion to kermit — run when a session ends before the changelog was updated.
model: claude-sonnet-4-6
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
| pref | JSON | `.claude/kermit/pref.json` (optional — used for changelog path and last-logged SHA) |
| changelog | file | path from pref, or discovered via `find` |
| git log | text | `git log <ref>..HEAD` |

## Outputs

| Name | Format | Destination |
|------|--------|-------------|
| unlogged count | text | emitted inline |
| new changelog entries | prose | prepended to changelog file |
| pref update | JSON | `.claude/kermit/pref.json` — `last_logged_commit` updated after write |

## Protocol

### 1. Setup

Detect rtk: `which rtk >/dev/null 2>&1 && RTK=rtk || RTK=`. All git commands use `$RTK git` or plain `git` if rtk is absent.

### 2. Find changelog path

Read `.claude/kermit/pref.json` if it exists. Look for a `"changelog"` key — use that path if present.

If pref.json is absent or has no `"changelog"` key: search with `find . -maxdepth 3 \( -iname 'changelog*' -o -iname 'history*' \) 2>/dev/null | grep -v node_modules | head -1`.

If no changelog is found after both checks:
- Use `AskUserQuestion` — question: `No changelog found. What would you like to do?`, options: `Init one now (run /kermit --init)`, `I'll give you the path`, `Cancel`.
  - **"Init one now"**: emit `Run \`/kermit --init\` to create a changelog, then re-run \`/log-it\`.` and exit.
  - **"I'll give you the path"**: use `AskUserQuestion` — question: `Enter the changelog file path:`, options: `(type path)`. Use the provided path. If the path does not exist or is not readable, emit `Error: file not found at <path>. Aborting.` and exit.
  - **"Cancel"**: emit `Aborted — no changelog to update.` and exit.

Store the resolved path as `CHANGELOG`.

### 3. Determine the commit range

Read pref.json again. If a `"last_logged_commit"` SHA is present, use it as the base: commits = `$RTK git log <last_logged_commit>..HEAD --format="%H %ad %s" --date=short`.

If `"last_logged_commit"` is absent (kermit hasn't logged yet, or pref.json is missing):
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

For each commit in the list (oldest-first within each date group):
- Run `$RTK git show <SHA> --stat --format="" | head -30` to get changed files.
- Run `$RTK git show <SHA> -s --format="%s%n%b"` to get subject and body.

Group commits by date. For each date group (newest group first in the output):

Write the entry following `refs/changelog-protocol.md`:
```
## YYYY-MM-DD

<One-sentence prose summary covering all commits in this date group.>

- <bullet per meaningful change, one line, active voice>
```

**Prepend** all new date groups before the first existing `## ` line in `$CHANGELOG`. Use a temporary file and `mv`:
```bash
TMP=$(mktemp)
printf '%s\n\n' "<new entries block>" > "$TMP"
grep -n "^## " "$CHANGELOG" | head -1   # find insertion line
# insert before first ## line, or append if none exists
```

After writing, emit `Changelog updated — <N> commit(s) logged under <date-list>.`

### 6. Update pref.json

After a successful write, update `.claude/kermit/pref.json`:
- Set `"last_logged_commit"` to the SHA of the most recent commit that was just logged (HEAD).
- Preserve all other keys in pref.json.

Emit `pref.json updated — last_logged_commit set to <short-sha>.`
