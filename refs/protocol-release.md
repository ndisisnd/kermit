# Release protocol

Reached via `--release`, or when the merge-to-main guard prompts a release. This mode writes
and maintains **release notes** — the user-facing story of what changed, in `RELEASES.md`. It
does **not** create a commit; it operates on committed history. Run the default commit flow
first (`/kermit`) if you have uncommitted work you want in this release.

**General rule:** batch independent commands into one Bash call. `.claude/kermit/pref.json`
(config) and `.claude/kermit/state.json` (volatile) were read once at mode-check (SKILL.md) —
reuse the cached `gate_mode` / `changelog.*`; don't re-read them.

## Gate resolution (runs once, before step 1)

Reuse the commit protocol's `gate_mode` table. In this mode only `auto_approve` matters:
`full`/`commit-only` → `auto_approve=false` (ask before writing); `auto`/`flash` →
`auto_approve=true` (write without asking). **Legacy fallback:** if `gate_mode` is absent, use
the `auto_approve` boolean, default `false`.

---
1. **Detect rtk and locate inputs** in one Bash call:
   `which rtk >/dev/null 2>&1 && RTK=rtk || RTK=`. Resolve the changelog path (cached
   `changelog.path`, else `find . -maxdepth 3 \( -iname 'changelog*' -o -iname 'history*' \) 2>/dev/null | grep -v node_modules | head -1`) as `CHANGELOG`. If none is found, emit
   `No changelog found — nothing to write release notes from.` and exit. Read `RELEASES.md`
   if it exists (you will prepend to it); if it is absent it will be created with the header
   `# Releases\n\nWhat's new for you, release by release.\n`.

2. **Determine the range.** The "unreleased" slice is every changelog entry with a number
   greater than the cached `last_released_number` from `state.json` (the highest `## [N]`
   already covered by a previous release; `0` means nothing has been released yet). Collect
   each `## [N]` entry whose `N > last_released_number` — since entries are newest-on-top with
   the highest `N` first, that is the run of entries from the top of the file down to (and
   including) the one numbered `last_released_number + 1`. Any `## v…` line is a legacy marker —
   skip it. If no entry qualifies, emit `No unreleased changes to write notes for.` and exit.
   Remember the highest `N` in the slice as `N_top` (it equals `last_number` from state).

3. **Determine the version label.** If `--release=<x.y.z>` or a bump was named, use it.
   Otherwise decide the bump from the change mix — any breaking change → `major`; else any new
   capability → `minor`; else `patch` — and confirm via `AskUserQuestion` — question:
   `What kind of release is this?`, options: `Patch — fixes only`, `Minor — new features,
   backward-compatible`, `Major — breaking changes` (put the inferred default first). Compute
   the next version from `package.json` `version` + the bump
   (`node -p "require('./package.json').version" 2>/dev/null`); if there is no `package.json`,
   ask the user for the version string via `AskUserQuestion` (free-text). The date line is
   today's ISO date (`date +%F`).

4. **Rewrite and classify.** Read `refs/template-release.md` now for the exact shape, section
   order, labels, and voice rules. For each changelog entry in range, translate its technical
   summary into a **user-facing** line and sort it into one bucket: `✨ New`, `📈 Improved`,
   `🐛 Fixed`, `🔒 Security`, `⚠️ Breaking`, `🗑️ Deprecated`. Apply the voice rules: say what
   the user can now do / no longer needs to do / must do differently, and *why* — no file
   names, no jargon, second person. Collapse changes with no user-visible effect into at most
   one "under the hood" line under Improved, or drop them.

5. **Write the Highlight.** A 1–3 sentence blockquote leading with the release's single most
   material change — the thing a user would care about most.

6. **Compose and prepend.** Render the release section per the template — the `## <version> —
   <date>` heading, the Highlight blockquote, then only the non-empty `###` sections in fixed
   order. **Prepend** it directly under the `RELEASES.md` header so the newest release is on
   top. Show the composed section to the user.

7. **Gate.** If `auto_approve` is `true`, proceed as approved. Otherwise `AskUserQuestion` —
   question: `Approve or revise?`, options: `approve`, `revise`. On `revise`: `AskUserQuestion`
   — question: `What would you like to revise?`, options: `sharpen the highlight`,
   `simpler language`, `regroup a change`, `other (I'll describe)`. Incorporate, rewrite, and
   return to 6. Write `RELEASES.md` only after approval (create it with the header first if
   absent). **Then record the release boundary:** set `last_released_number` to `N_top` in
   `.claude/kermit/state.json` (single write, preserve all other keys) so the next `--release`
   only covers changes made after this one. Emit `Release notes written to RELEASES.md.` That
   is the mode's deliverable — the notes are written; terminate.
