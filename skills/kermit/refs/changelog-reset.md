# kermit --changelog-reset — protocol

Read only when `--changelog-reset` was passed to `/kermit`. Rewrites an existing
changelog so it follows the current conventions in `refs/changelog-protocol.md`: groups
entries under `## <date>` sections, numbers each entry as `### [N]`, and normalises
headings/bullets. Runs and **exits** — it never falls through to the commit flow.

Detect rtk: `which rtk >/dev/null 2>&1 && RTK=rtk || RTK=`. `GATE(...)`, `KERMIT_DIR` and
`INTERACTIVE` are defined in SKILL.md; non-interactive runs take each gate's stated default.

## 1. Resolve the changelog path

Same resolution as `--changelog-sync`: read `$KERMIT_DIR/pref.json`; use `changelog.path` if
present. Otherwise `find . -maxdepth 3 \( -iname 'changelog*' -o -iname 'history*' \) 2>/dev/null | grep -v node_modules | head -1`.
If nothing is found, emit `No changelog found — nothing to reset.` and exit.
Store the resolved path as `CHANGELOG`.

## 2. Safety first

- **Backup**: `cp "$CHANGELOG" "$CHANGELOG.bak"` and announce `Backup written to <path>.bak`.
- **Dry-run by default**: build the rewritten file in a temp file, show a unified diff
  (`diff -u "$CHANGELOG" "$TMP"` or `git --no-pager diff --no-index "$CHANGELOG" "$TMP"`),
  then `GATE(question: "Apply these changelog changes?", options: ["Apply", "Keep dry-run only"], default: "Apply")`.
  On **Keep dry-run only**: emit `No changes written — backup left at <path>.bak.` and exit.
  - If `--apply` was passed alongside `--changelog-reset`, still show the diff, then apply
    without the question.

## 3. Parse the file

Identify the parts of the file:
- the top preamble (the `# Changelog` title and any intro lines before the first entry) — preserve verbatim;
- any `## History` backfill block — treat it as a special case: ask once via
  `GATE(question: "Fold the History section into dated entries too?", options: ["Leave verbatim", "Fold it in"], default: "Leave verbatim")`;
  since it is machine-generated one-liners, the default leaves it verbatim at the bottom of the file;
- **every other heading is a commit entry** to normalise — whether it is already `### [N] — …`
  under a `## <date>`, or a legacy `## [N] — <summary>` / `## <summary>` with the date on its own
  line beneath it. For each entry, capture its **summary**, its **date** (the ISO date on the line
  under the old heading, or embedded in the heading as `— YYYY-MM-DD`; if none, `<date unknown>`),
  and its **bullets**.

## 4. Normalise each entry

To the current `refs/changelog-protocol.md` convention:
- Strip any pre-existing `[k]` from the summary — numbers are reassigned in step 5 (do not trust old numbers).
- Keep the summary text and the bullet prose intact. Only structural fixes: ensure each change line
  starts with `- ` and wrap an obvious `path/to/file` in backticks if it isn't already.
- **Never invent content** — summaries, dates, and bullets come only from what is already in the file.

## 5. Renumber and group by date

1. Number the entries **oldest→newest** as `[1], [2], … [N]` so the **newest** entry carries the
   highest `N`. (Leave the `## History` block out of the numbering unless the user opted to fold it in.)
2. **Group by date.** Emit one `## <YYYY-MM-DD>` section per distinct date, newest date first;
   under each, its entries as `### [N] — <summary>` (+ bullets), newest `N` first. Each date appears once.
3. Set `last_number` in `$KERMIT_DIR/state.json` to the max `N` (preserve all other keys; create the
   file with `{"last_logged_commit":null,"last_number":<N>,"last_released_number":0,"backfill":null}` if
   absent). This seeds the counter so the next normal `/kermit` commit continues the sequence.

Reset works on the entries **as they exist** — it cannot retroactively split a legacy multi-file
"product goal" heading into per-commit entries (there is no commit mapping), so each existing heading
becomes exactly one numbered entry.

## 6. Write + verify idempotency

Write the rewritten file (only after approval in step 2). Then re-parse it: a second
`--changelog-reset` on the result must produce an **empty diff** (same numbers, same dated grouping).
If the re-parse would change anything, report it rather than looping.

## 7. Summary

Emit: `<n> entries normalised, numbered [1..N], grouped under <d> dates. Backup at <path>.bak. last_number set to <N>.`

Then close with the `kermit-result` block defined in SKILL.md — `mode: changelog-reset`,
`head` = current HEAD SHA, `changelog_entry` = `N`, `pushed: no`, `published: n/a`,
`gates` = the resolved gate level.
