# Commit protocol

The default kermit flow: format a Conventional Commits message, gate it, commit,
and optionally push.

**General rule:** batch independent commands into one Bash call (step 1 does this for the rtk check + diff read). `$KERMIT_DIR/pref.json` (config) and `$KERMIT_DIR/state.json` (volatile state — git-ignored) are read once at mode-check (SKILL.md) — cache `gate_mode`/`changelog.*` from pref and `last_logged_commit`/`last_number` from state for the run; don't re-read either in later steps. `GATE(...)`, `HARNESS`, `KERMIT_DIR`, `INTERACTIVE` and the closing `kermit-result` block are all defined in SKILL.md.

## Gate resolution (runs once, before step 1)

Resolve how many interactive gates this run has from `gate_mode` in pref.json. This
sets the effective `auto_approve` / `auto_commit` / `auto_merge` values used by steps
3, 4 and 6, plus a `push_enabled` flag:

| `gate_mode` | `auto_approve` | `auto_commit` | `auto_merge` | `push_enabled` | Gates |
|-------------|----------------|---------------|--------------|----------------|-------|
| `full` | false | false | false | true | approve · commit · push |
| `auto` | false | true | true | true | approve only |
| `flash` | true | true | true | true | none — commits & pushes immediately |
| `commit-only` | true | true | — | **false** | none — commits, never pushes |

**Legacy fallback:** if `gate_mode` is absent (older prefs), use the individual
`auto_approve` / `auto_commit` / `auto_merge` booleans and treat `push_enabled` as
`true`. When `push_enabled` is `false` (`commit-only`), **skip step 6
entirely** — do not push, do not ask.

**Non-interactive override:** if `INTERACTIVE=false`, force `auto_approve`, `auto_commit`
and `auto_merge` to `true` regardless of `gate_mode` (`push_enabled` still honours
`commit-only`), and report `gates: auto (non-interactive)`.

---
1. Detect rtk **and** read the staged diff in one Bash call: `which rtk >/dev/null 2>&1 && RTK=rtk || RTK=; echo "(1) Reading latest git diff..."; $RTK git diff --staged`. If rtk is absent, `$RTK` is empty and commands run as plain `git`.

2. Emit `(2) Writing commit message...` Produce a Conventional Commits message:
   - Line 1: `<emoji> <type>[(<scope>)][!]: <description>` — ≤72 chars total; description is lowercase imperative; `!` and `BREAKING CHANGE` footer are both required for breaking changes. Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`. Pick an emoji matching the type (e.g. ✨ feat, 🐛 fix, 📝 docs, ♻️ refactor, 🚀 perf, ✅ test, 🔧 chore).
   - Blank line
   - Body: `- <file> — <descriptor>` per changed file; keep terse unless the change is large or impactful
   - Footer (if breaking): `BREAKING CHANGE: <description>` — mandatory for any breaking change, never omit
   - **Never add AI co-authorship or attribution trailers** (e.g. `Co-Authored-By: Claude …`, `Co-Authored-By: <any AI>`, `Generated with …`). The commit is the user's — omit these always, and strip any that appear when revising a message.

3. Emit `(3) Proposed commit message:` in a code block. If the resolved `auto_approve` is `true` (see Gate resolution), skip the gate and proceed as approved. Otherwise `GATE(question: "Approve or revise?", options: ["approve", "revise"], default: "approve")`. On revise: `GATE(question: "What would you like to revise?", options: ["more explicit changes", "less vague title", "fix linting / formatting", "other (I'll describe)"], default: "more explicit changes")`. Incorporate the feedback, rewrite the message, and return to 3. (The revise loop is unreachable non-interactively — the approve default short-circuits it.)
   After the message is approved, emit: `💡 If you commit this manually or close the session before step 5 completes, run \`/kermit --changelog-sync\` afterward to sync the changelog.`
4. If the resolved `auto_commit` is `true` (see Gate resolution), skip the gate and proceed as `yes`. Otherwise `GATE(question: "(4) Run git commit on your behalf?", options: ["yes", "no"], default: "yes")`. On no: emit `Tip: if you commit manually later, run \`/kermit --changelog-sync\` to update the changelog.` and terminate (emit the `kermit-result` block first).
5. Emit `(5) Updating changelog and committing...`
   - **Probe the changelog.** Resolve the changelog path from the cached `changelog.path` and test it in one call: `CL="<cached path or CHANGELOG.md>"; test -f "$CL" || printf '# Changelog\n\nAll notable changes to this project will be documented here.\n' > "$CL"`. If the Claude PreToolUse hook already left `CHANGELOG_EXISTS=1` in `/tmp/commit_cl_cache` you may trust it as a pre-warm, but the `test -f` probe is authoritative — never skip writing the entry because a hook cache is missing or absent.
   - Append an entry following the user's changelog format — use `changelog.protocol` from the pref.json already read at the mode-check step (do not re-read the file); if it is an object, honour its `summary`/`fields`/`show_files`/`flag_breaking` (or free-text `description`) when writing the entry. Only if `changelog.protocol` is `null`, read `refs/changelog-protocol.md` now and follow it. **Number the entry** (unless a custom `changelog.protocol` sets `"number": false`): use the cached `last_number` from state.json (if absent, use the highest existing `### [k]` in the file, else 0); let `N = that + 1`. **Group by date:** if the topmost `## <date>` section in the entry area equals today's date, add `### [N] — <summary>` as the first entry directly under it; otherwise open a new `## <today>` section at the top of the entry area (below the `# Changelog` preamble) with the entry under it. kermit commits one at a time, so exactly one numbered entry is written per run.
   Run `$RTK git commit -m "<approved message>"`. **Then** record runtime state in `$KERMIT_DIR/state.json` in a single write: set `"last_logged_commit"` to the new HEAD SHA (`git log -1 --format="%H"` — the commit just made) **and** `"last_number"` to `N`, preserving all other keys. Writing state.json *after* the commit keeps it out of the commit, and since state.json is git-ignored the write never dirties the working tree.
6. If `push_enabled` is `false` (`commit-only` mode), skip this step entirely — the run ends after the commit. Otherwise: if `auto_merge` is `true`, skip the gate and proceed as `yes`; else `GATE(question: "(6) Push to remote?", options: ["yes", "no"], default: "yes")`. On yes: run `$RTK git push`.
   **Sandbox-tolerant push.** A subagent may have no network. If the push fails for any network/auth reason (`could not resolve host`, `connection refused`, `permission denied`, timeout), do **not** error the run: record `pushed: failed`, emit one remediation line — `Push blocked (no network in this sandbox) — run \`git push\` yourself, or grant the worker network access.` — and terminate successfully. The commit and changelog entry are the deliverable.

7. **Close.** Emit the `kermit-result` block defined in SKILL.md — `mode: commit`, `head` = the new HEAD SHA (or `null` if no commit was made), `changelog_entry` = `N` (or `null`), `pushed` = `yes`/`no`/`failed`, `published: n/a`, `gates` = the resolved gate level.
