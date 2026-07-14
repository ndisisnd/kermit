# Commit protocol

The default kermit flow: format a Conventional Commits message, gate it, commit,
and optionally push.

**General rule:** batch independent commands into one Bash call (step 1 does this for the rtk check + diff read). `.claude/kermit/pref.json` (config) and `.claude/kermit/state.json` (volatile state — git-ignored) are read once at mode-check (SKILL.md) — cache `gate_mode`/`changelog.*` from pref and `last_logged_commit`/`last_number` from state for the run; don't re-read either in later steps.

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

---
1. Detect rtk **and** read the staged diff in one Bash call: `which rtk >/dev/null 2>&1 && RTK=rtk || RTK=; echo "(1) Reading latest git diff..."; $RTK git diff --staged`. If rtk is absent, `$RTK` is empty and commands run as plain `git`.

2. Emit `(2) Writing commit message...` Produce a Conventional Commits message:
   - Line 1: `<emoji> <type>[(<scope>)][!]: <description>` — ≤72 chars total; description is lowercase imperative; `!` and `BREAKING CHANGE` footer are both required for breaking changes. Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`. Pick an emoji matching the type (e.g. ✨ feat, 🐛 fix, 📝 docs, ♻️ refactor, 🚀 perf, ✅ test, 🔧 chore).
   - Blank line
   - Body: `- <file> — <descriptor>` per changed file; keep terse unless the change is large or impactful
   - Footer (if breaking): `BREAKING CHANGE: <description>` — mandatory for any breaking change, never omit
   - **Never add AI co-authorship or attribution trailers** (e.g. `Co-Authored-By: Claude …`, `Co-Authored-By: <any AI>`, `Generated with …`). The commit is the user's — omit these always, and strip any that appear when revising a message.

3. Emit `(3) Proposed commit message:` in a code block. If the resolved `auto_approve` is `true` (see Gate resolution), skip the question and proceed as approved. Otherwise use `AskUserQuestion` — question: `Approve or revise?`, options: `approve`, `revise`. On revise: use `AskUserQuestion` — question: `What would you like to revise?`, options: `more explicit changes`, `less vague title`, `fix linting / formatting`, `other (I'll describe)`. Incorporate the feedback, rewrite the message, and return to 3.
   After the message is approved, emit: `💡 If you commit this manually or close the session before step 5 completes, run \`/log-it\` afterward to sync the changelog.`
4. If the resolved `auto_commit` is `true` (see Gate resolution), skip the question and proceed as `yes`. Otherwise use `AskUserQuestion` — question: `(4) Run git commit on your behalf?`, options: `yes`, `no`. On no: emit `Tip: if you commit manually later, run \`/log-it\` to update the changelog.` and terminate.
5. Emit `(5) Updating changelog and committing...`
   - If `CHANGELOG_EXISTS=1` in cache: append an entry following the user's changelog format — use `changelog.protocol` from the pref.json already read at the mode-check step (do not re-read the file); if it is an object, honour its `summary`/`fields`/`show_files`/`flag_breaking` (or free-text `description`) when writing the entry. Only if `changelog.protocol` is `null`, read `refs/changelog-protocol.md` now and follow it. **Number the entry** (unless a custom `changelog.protocol` sets `"number": false`): use the cached `last_number` from state.json (if absent, use the highest existing `## [k]` in the file, ignoring `## v…` markers, else 0); let `N = that + 1` and write the heading as `## [N] — <summary>`. kermit commits one at a time, so exactly one numbered entry is written per run.
   - If `CHANGELOG_EXISTS=0`: Stop hook initializes after session
   Run `$RTK git commit -m "<approved message>"`. **Then** record runtime state in `.claude/kermit/state.json` in a single write: set `"last_logged_commit"` to the new HEAD SHA (`git log -1 --format="%H"` — the commit just made) **and** `"last_number"` to `N`, preserving all other keys. Writing state.json *after* the commit keeps it out of the commit, and since state.json is git-ignored the write never dirties the working tree.
6. If `push_enabled` is `false` (`commit-only` mode), skip this step entirely — the run ends after the commit. Otherwise: if `auto_merge` is `true`, skip the question and proceed as `yes`; else use `AskUserQuestion` — question: `(6) Push to remote?`, options: `yes`, `no`. On yes: run `$RTK git push`. This is the final step of the commit flow.
