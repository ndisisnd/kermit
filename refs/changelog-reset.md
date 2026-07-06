# kermit --changelog-reset — protocol

Read only when `--changelog-reset` was passed to `/kermit`. Rewrites an existing
changelog so it follows the current conventions in `refs/changelog-protocol.md`: adds
per-commit numbering (`## [N]`), normalises headings/dates/bullets, and leaves any
`## v<version>` release markers untouched. Runs and **exits** — it never falls through
to the commit flow.

Detect rtk: `which rtk >/dev/null 2>&1 && RTK=rtk || RTK=`.

## 1. Resolve the changelog path

Same resolution as log-it: read `.claude/kermit/pref.json`; use `changelog.path` if
present. Otherwise `find . -maxdepth 3 \( -iname 'changelog*' -o -iname 'history*' \) 2>/dev/null | grep -v node_modules | head -1`.
If nothing is found, emit `No changelog found — nothing to reset.` and exit.
Store the resolved path as `CHANGELOG`.

## 2. Safety first

- **Backup**: `cp "$CHANGELOG" "$CHANGELOG.bak"` and announce `Backup written to <path>.bak`.
- **Dry-run by default**: build the rewritten file in a temp file, show a unified diff
  (`diff -u "$CHANGELOG" "$TMP"` or `git --no-pager diff --no-index "$CHANGELOG" "$TMP"`),
  then gate with `AskUserQuestion` — question: `Apply these changelog changes?`, options:
  `Apply`, `Keep dry-run only`. On **Keep dry-run only**: emit `No changes written — backup left at <path>.bak.` and exit.
  - If `--apply` was passed alongside `--changelog-reset`, still show the diff, then apply
    without the question.

## 3. Parse the file

Split into blocks on `^## ` lines. Preserve verbatim:
- the top preamble (the `# Changelog` title and any intro lines before the first `## `);
- any `## History` backfill block — treat it as a special case: ask once via
  `AskUserQuestion` (`Renumber the History section too?`, options `Leave verbatim`,
  `Renumber it`) since it is machine-generated one-liners;
- any `## v<version>` **release markers** — leave them in place, **unnumbered**; they are
  structural separators, not entries, and the renumber in step 5 skips over them.

Everything else is a **commit entry** to normalise.

## 4. Normalise each commit entry

To the current `refs/changelog-protocol.md` convention:
- Ensure a `## [N] — <summary>` heading line. Strip any pre-existing `[k]` and reassign in
  step 5 (do not trust old numbers).
- Ensure the ISO date (`YYYY-MM-DD`) sits on its own line directly under the heading. If a
  legacy entry embedded the date in the heading (e.g. `— 2026-06-07`), lift it out onto its
  own line. If an entry has no date, write `<date unknown>` — **do not invent one**.
- Leave the bullet prose intact. Only structural fixes: ensure each change line starts with
  `- ` and wrap an obvious `path/to/file` in backticks if it isn't already.
- **Never invent content** — headings, dates, and bullets come only from what is already in
  the file.

## 5. Renumber

Number the commit entries **oldest→newest** as `[1], [2], … [N]` (skip `## v…` markers and,
unless the user opted in at step 3, the `## History` block), so the **topmost** entry carries
the highest `N`. Set `changelog.last_number` in `.claude/kermit/pref.json` to that max `N`
(preserve all other keys). This seeds the counter so the next normal `/kermit` commit
continues the sequence.

Reset works on the entries **as they exist** — it cannot retroactively split a legacy
multi-file "product goal" heading into per-commit entries (there is no commit mapping), so
each existing heading becomes exactly one numbered entry.

## 6. Write + verify idempotency

Write the rewritten file (only after approval in step 2). Then re-parse it: a second
`--changelog-reset` on the result must produce an **empty diff** (same numbers, same
structure). If the re-parse would change anything, report it rather than looping.

## 7. Summary

Emit: `<n> entries normalised, numbered [1..N]. Backup at <path>.bak. last_number set to <N>.`
