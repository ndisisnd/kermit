# Changelog-sync protocol

Reached via `--changelog-sync`. Backfills the changelog with any commits that landed
without an entry — you committed by hand, a session ended mid-run, or a rebase moved
history. This mode writes **only** the changelog file: it makes no commit, opens nothing,
and pushes nothing. It reports what's missing, asks, and writes.

**General rule:** batch independent commands into one Bash call (step 1 does this for the
rtk check + range read). `$KERMIT_DIR/pref.json` (config) and `$KERMIT_DIR/state.json`
(volatile — git-ignored) were read once at mode-check (SKILL.md) — reuse the cached
`gate_mode` / `changelog.*` from pref and `last_logged_commit` / `last_number` from state;
don't re-read either. `GATE(...)`, `KERMIT_DIR`, `INTERACTIVE` and the closing `kermit-result`
block are defined in SKILL.md.

## Gate resolution (runs once, before step 1)

Reuse the commit protocol's `gate_mode` table. In this mode only `auto_approve` matters:
`full`/`commit-only` → `auto_approve=false` (ask before writing); `auto`/`flash` →
`auto_approve=true` (write without asking). **Legacy fallback:** if `gate_mode` is absent,
use the `auto_approve` boolean, default `false`.

**Non-interactive override:** if `INTERACTIVE=false`, force `auto_approve` to `true` and report
`gates: auto (non-interactive)`.

---

1. **Detect rtk** and resolve the changelog in one Bash call:
   `which rtk >/dev/null 2>&1 && RTK=rtk || RTK=; echo "(1) Checking for unlogged commits..."`.
   If rtk is absent, `$RTK` is empty and commands run as plain `git`.

   Use the cached `changelog.path` from pref.json. If it is `null` or absent, search:
   `find . -maxdepth 3 \( -iname 'changelog*' -o -iname 'history*' \) 2>/dev/null | grep -v node_modules | head -1`.

   If no changelog is found after both checks,
   `GATE(question: "No changelog found. What would you like to do?", options: ["Init one now (run /kermit --init)", "I'll give you the path", "Cancel"], default: "Init one now (run /kermit --init)")`.
   - **Init one now** → non-interactively this means: create `CHANGELOG.md` at the repo root
     with header `# Changelog\n\nAll notable changes to this project will be documented here.\n`,
     use it as `CHANGELOG`, and continue. Interactively, emit ``Run `/kermit --init` to create a
     changelog, then re-run `/kermit --changelog-sync`.`` and terminate.
   - **I'll give you the path** → `GATE(question: "Enter the changelog file path:", options: free text, default: "CHANGELOG.md")`.
     If the path does not exist or is not readable, emit `Error: file not found at <path>.
     Aborting.` and terminate.
   - **Cancel** → emit `Aborted — no changelog to update.` and terminate.

   Store the resolved path as `CHANGELOG`.

2. **Determine the commit range.** If the cached `last_logged_commit` SHA is present, use it
   as the base: `$RTK git log <last_logged_commit>..HEAD --format="%H %ad %s" --date=short`.
   (**Legacy fallback:** if state.json had no value but `pref.json` still carries a top-level
   `last_logged_commit`, use that.)

   If `last_logged_commit` is absent (kermit hasn't logged yet), fall back to the changelog's
   own most recent date header: `grep -E "^## [0-9]{4}-[0-9]{2}-[0-9]{2}" "$CHANGELOG" | head -1`.
   - Date found → `$RTK git log --after="<date>" --format="%H %ad %s" --date=short`. **Note:**
     `--after` is exclusive of the given date, so commits *on* that date are included — they
     may already be covered by that day's entry. Warn in step 3.
   - No date header → all commits: `$RTK git log --format="%H %ad %s" --date=short`.

   Collect the result into a list. Count `N` = number of lines.

3. **Report.** If `N = 0`, emit `Changelog is up to date — no unlogged commits found.` and
   terminate.

   If the date-based fallback was used **and** the oldest unlogged commit shares a day with the
   last changelog entry, emit: `⚠️  Some commits below may already be covered by the existing
   <date> entry. Review before confirming.`

   Emit:
   ```
   Found <N> commit(s) not reflected in the changelog:

   <sha-short> <date> <subject>
   ...
   ```

   If the resolved `auto_approve` is `true`, skip the gate and proceed as approved.
   Otherwise `GATE(question: "Write these <N> commit(s) to the changelog?", options: ["Yes, update now", "No, skip"], default: "Yes, update now")`.
   On no: emit ``Changelog unchanged. Re-run
   `/kermit --changelog-sync` any time.`` and terminate.

4. **Write the entries.** For each commit (oldest-first), read what changed:
   `$RTK git show <SHA> --stat --format="" | head -30` for the file list, and
   `$RTK git show <SHA> -s --format="%s%n%b"` for subject and body — noting the commit's date
   (`%ad`, `--date=short`).

   Write each entry following the user's changelog format — if the cached `changelog.protocol`
   is an object, honour its `summary`/`fields`/`show_files`/`flag_breaking` (or free-text
   `description`). Only if `changelog.protocol` is `null` or absent, read
   `refs/changelog-protocol.md` now and follow it.

   **Numbering** (unless `changelog.protocol` sets `"number": false`): resolve the starting
   number once — the cached `last_number`, else the highest existing `### [k]` in the file,
   else 0. Number the commits **oldest→newest** (`start+1 … start+k`) so the newest commit
   carries the highest `N`.

   **Place each entry by date**, working newest-commit-first so higher numbers land above
   lower ones:
   - The commit's date already has a `## <date>` section → insert its `### [N] — <summary>`
     as the **first** entry under that header.
   - Otherwise → open a new `## <date>` section in the correct chronological position (newest
     date nearest the top, below the `# Changelog` preamble) and put the entry under it.

   Use a temporary file and `mv` to rewrite the file. Emit
   `Changelog updated — <k> commit(s) logged as [<start+1>..<start+k>].`

5. **Record state** in `$KERMIT_DIR/state.json` in a single write, preserving all other keys
   (create it with `{"last_logged_commit":null,"last_number":0,"last_released_number":0,"backfill":null}`
   first if absent, and ensure it is git-ignored:
   `grep -qxF "$KERMIT_DIR/state.json" .gitignore 2>/dev/null || printf '%s\n' "$KERMIT_DIR/state.json" >> .gitignore`):
   - `"last_logged_commit"` → the SHA of the most recent commit just logged (HEAD).
   - `"last_number"` → the highest `N` written.

   Emit `state.json updated — last_logged_commit set to <short-sha>, last_number set to <N>.`
   This mode makes no commit — the changelog is left in your working tree to commit as you see
   fit.

6. **Close.** Emit the `kermit-result` block defined in SKILL.md — `mode: changelog-sync`,
   `head` = current HEAD SHA, `changelog_entry` = the highest `N` written (or `null`),
   `pushed: no`, `published: n/a`, `gates` = the resolved gate level.
