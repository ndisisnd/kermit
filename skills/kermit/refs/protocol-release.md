# Release protocol

Reached via `--release`, or when the merge-to-main guard prompts a release. This mode writes
and maintains **release notes** — the user-facing story of what changed, in `RELEASES.md` —
then commits them and publishes a GitHub release. It does **not** create a commit for your
*code*; it operates on committed history. Run the default commit flow first (`/kermit`) if you
have uncommitted work you want in this release. The only commit this mode makes is the release
commit itself (step 8).

**General rule:** batch independent commands into one Bash call. `$KERMIT_DIR/pref.json`
(config) and `$KERMIT_DIR/state.json` (volatile) were read once at mode-check (SKILL.md) —
reuse the cached `gate_mode` / `changelog.*`; don't re-read them. `GATE(...)`, `HARNESS`,
`KERMIT_DIR`, `INTERACTIVE` and the closing `kermit-result` block are defined in SKILL.md.

## Gate resolution (runs once, before step 1)

Reuse the commit protocol's `gate_mode` table. This mode uses four resolved values:

| `gate_mode` | `auto_approve` (the notes) | `auto_commit` (the release commit) | `push_enabled` | `auto_publish` (the GitHub release) |
|-------------|----------------------------|------------------------------------|----------------|--------------------------------------|
| `full` | false | false | true | false |
| `auto` | false | true | true | true |
| `flash` | true | true | true | true |
| `commit-only` | true | true | **false** | **false** |

`auto_publish` reuses the `auto_merge` column. **Legacy fallback:** if `gate_mode` is absent,
use the individual `auto_approve` / `auto_commit` / `auto_merge` booleans (treat `auto_merge`
as `auto_publish`), default `auto_approve` to `false`, and treat `push_enabled` as `true`.

Publishing a release is inherently a remote action. When `push_enabled` is `false`
(`commit-only`), still make the release commit, but do **not** auto-push — ask before pushing,
and skip the GitHub release if the user declines.

**Non-interactive override:** if `INTERACTIVE=false`, force `auto_approve`, `auto_commit` and
`auto_publish` to `true` regardless of `gate_mode`, and report `gates: auto (non-interactive)`.

---
1. **Detect rtk and locate inputs** in one Bash call:
   `which rtk >/dev/null 2>&1 && RTK=rtk || RTK=`. Resolve the changelog path (cached
   `changelog.path`, else `find . -maxdepth 3 \( -iname 'changelog*' -o -iname 'history*' \) 2>/dev/null | grep -v node_modules | head -1`) as `CHANGELOG`. If none is found, emit
   `No changelog found — nothing to write release notes from.` and exit. Read `RELEASES.md`
   if it exists (you will prepend to it); if it is absent it will be created with the header
   `# Releases\n\nWhat's new for you, release by release.\n`.

2. **Determine the range.** The "unreleased" slice is every changelog entry with a number
   greater than the cached `last_released_number` from `state.json` (the highest `### [N]`
   already covered by a previous release; `0` means nothing has been released yet). The
   changelog groups entries under `## <date>` sections with `### [N] — <summary>` entries
   beneath them — collect each `### [N]` entry whose `N > last_released_number` (ignore the
   `## <date>` section headers; they are not entries). If no entry qualifies, emit
   `No unreleased changes to write notes for.` and exit. Remember the highest `N` in the slice
   as `N_top` (it equals `last_number` from state).

3. **Determine the version label.** If `--release=<x.y.z>` or a bump was named, use it.
   Otherwise decide the bump from the change mix — any breaking change → `major`; else any new
   capability → `minor`; else `patch` — and confirm via
   `GATE(question: "What kind of release is this?", options: ["Patch — fixes only", "Minor — new features, backward-compatible", "Major — breaking changes"], default: the inferred bump)`
   (put the inferred default first). Compute the next version from `package.json` `version` +
   the bump (`node -p "require('./package.json').version" 2>/dev/null`); if there is no
   `package.json`, `GATE(question: "Version string for this release?", options: free text, default: "1.0.0")`. Remember the result
   as `VERSION` (bare, no `v` prefix) and whether a `package.json` was found as `HAS_PKG` —
   both are used by step 8. The date line is today's ISO date (`date +%F`).

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

7. **Gate.** If `auto_approve` is `true`, proceed as approved. Otherwise
   `GATE(question: "Approve or revise?", options: ["approve", "revise"], default: "approve")`.
   On `revise`: `GATE(question: "What would you like to revise?", options: ["sharpen the highlight", "simpler language", "regroup a change", "other (I'll describe)"], default: "sharpen the highlight")`.
   Incorporate, rewrite, and return to 6. (Unreachable non-interactively.) Write `RELEASES.md` only after approval (create it with the header first if
   absent). Emit `Release notes written to RELEASES.md.`

8. **Commit the release.** If `HAS_PKG` is true, bump `package.json`'s `version` field to
   `VERSION` now (edit that field only — leave formatting and every other key untouched).
   Compose the commit message:
   ```
   🔖 chore(release): v<VERSION>

   - RELEASES.md — add v<VERSION> notes
   - package.json — bump version to <VERSION>
   ```
   (drop the `package.json` bullet when `HAS_PKG` is false). Never add AI co-authorship or
   attribution trailers. If `auto_commit` is `false`, first
   `GATE(question: "(8) Commit the release notes?", options: ["yes", "no"], default: "yes")`.
   On `no`: emit `Release notes are
   written but uncommitted — commit them yourself, then run \`gh release create v<VERSION>\` if
   you want the GitHub release.` and terminate. Otherwise stage **only** the release files and
   commit: `$RTK git add RELEASES.md package.json` (omit `package.json` when `HAS_PKG` is
   false), then `$RTK git commit -m "<message>"`. **Write no changelog entry for this commit** —
   it is release bookkeeping, not a change users need in the next release's notes.

   **Then record state** in `$KERMIT_DIR/state.json` in a single write (preserve all other
   keys): set `last_released_number` to `N_top` so the next `--release` only covers changes made
   after this one, and set `last_logged_commit` to the new HEAD SHA
   (`git log -1 --format="%H"`) so `--changelog-sync` doesn't offer to changelog the release commit.
   state.json is git-ignored, so writing it after the commit never dirties the tree.

9. **Publish the GitHub release.** Check auth and skip cleanly if unavailable:
   `gh auth status >/dev/null 2>&1 && GH_OK=1 || GH_OK=0`. If `GH_OK=0`, emit `💡 Release
   committed. Install & auth the GitHub CLI to publish it: gh auth login` and terminate.

   Push first — the tag is cut from the pushed HEAD. If `push_enabled` is `true`, run
   `$RTK git push`. If it is `false` (`commit-only`),
   `GATE(question: "Push and publish the GitHub release for v<VERSION>?", options: ["yes", "no"], default: "yes")`.
   On `no`: emit `Release committed locally. Push when ready, then run \`gh release create v<VERSION>\`.`
   and terminate; on `yes`, run `$RTK git push` and continue.

   **Sandbox-tolerant push/publish.** If the push or the `gh` call fails for a network/auth
   reason (`could not resolve host`, `connection refused`, timeout), do **not** error the run:
   record `pushed: failed` / `published: no`, emit `Release committed locally but not published
   (no network in this sandbox) — push, then run \`gh release create v<VERSION>\`.`, close with
   the `kermit-result` block and terminate successfully. The notes and the release commit are
   the deliverable.

   If `auto_publish` is `false`,
   `GATE(question: "(9) Publish the GitHub release for v<VERSION>?", options: ["yes", "no"], default: "yes")`.
   On `no`: emit `Skipped — run \`gh release create v<VERSION>\` any time to publish.` and
   terminate. Otherwise publish, passing the composed
   section body (everything under the `## <version> — <date>` heading) as the notes:
   ```
   $RTK gh release create "v<VERSION>" --title "v<VERSION>" --notes "<section body>"
   ```
   `gh` creates the `v<VERSION>` tag from the pushed HEAD, so there is one source of truth for
   the tag. Add `--prerelease` if the user asked for one. If the command fails because the tag
   already exists, emit `Tag \`v<VERSION>\` already exists — the notes and commit are done; publish
   manually or pick another version.` and terminate. On success, emit the release URL
   (`$RTK gh release view "v<VERSION>" --json url -q .url`).

10. **Close.** Emit the `kermit-result` block defined in SKILL.md — `mode: release`, `head` =
    the release commit SHA (or `null`), `changelog_entry: null`, `pushed` = `yes`/`no`/`failed`,
    `published` = `yes`/`no`, `gates` = the resolved gate level.
