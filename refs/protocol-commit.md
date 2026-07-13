# Commit protocol

The default kermit flow: format a Conventional Commits message, gate it, commit,
optionally push, and optionally trigger a workflow.

**General rule:** batch independent commands into a single Bash call instead of
separate tool round-trips (step 1 already does this for the rtk check + diff read).
`.claude/kermit/pref.json` is read once at the mode-check step (in SKILL.md) — cache its
values (`gate_mode`, `changelog.*`, `workflows.*`) for the rest of the run rather than
re-reading the file in later steps.

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
`auto_approve` / `auto_commit` / `auto_merge` booleans as they are and treat
`push_enabled` as `true`. When `push_enabled` is `false` (`commit-only`), **skip steps
6 and 7 entirely** — do not push, do not ask, do not trigger workflows.

---
1. Detect rtk **and** read the staged diff in a single Bash call: `which rtk >/dev/null 2>&1 && RTK=rtk || RTK=; echo "(1) Reading latest git diff..."; $RTK git diff --staged`. If rtk is absent, `$RTK` is empty and all commands run as plain `git` — no rtk required. Do **not** check the GitHub CLI here — `gh auth status` makes a network call and is only needed by step 7, so it is deferred to that step (workflows are off on most commits and should never pay for it).

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
   - If `CHANGELOG_EXISTS=1` in cache: append an entry following the user's changelog format — use `changelog.protocol` from the pref.json already read at the mode-check step (do not re-read the file); if it is an object, honour its `summary`/`fields`/`show_files`/`flag_breaking` (or free-text `description`) when writing the entry. Only if `changelog.protocol` is `null`, read `refs/changelog-protocol.md` now and follow it. **Number the entry** (unless a custom `changelog.protocol` sets `"number": false`): use the cached `changelog.last_number` (if absent, use the highest existing `## [k]` in the file, ignoring `## v…` markers, else 0); let `N = that + 1` and write the heading as `## [N] — <summary>`. kermit commits one at a time, so exactly one numbered entry is written per run. After writing the changelog, update `.claude/kermit/pref.json` in a single write: set `"last_logged_commit"` to the current HEAD SHA (`git log -1 --format="%H"`) **and** `changelog.last_number` to `N`, preserving all other keys.
   - If `CHANGELOG_EXISTS=0`: Stop hook initializes after session
   Run `$RTK git commit -m "<approved message>"`
6. If `push_enabled` is `false` (`commit-only` mode), skip this step and step 7 entirely — the run ends after the commit. Otherwise: if `auto_merge` is `true`, skip the question and proceed as `yes`; else use `AskUserQuestion` — question: `(6) Push to remote?`, options: `yes`, `no`. On yes: run `$RTK git push`.
7. **Trigger a workflow?** Run this step only if the push in step 6 happened **and** `workflows.enabled` is `true` in pref.json. If either is false, skip step 7 silently. Only when both hold, check the GitHub CLI **now** (deferred from step 1): `gh auth status >/dev/null 2>&1 && GH_OK=1 || GH_OK=0`. If `GH_OK=0`, emit once: `💡 Install & auth the GitHub CLI to trigger workflows: gh auth login`, then skip. Otherwise continue.
   - **Choose the action.** If `--release` or `--deploy` was passed, use it directly. Else if `workflows.auto` is `release:<bump>` or `deploy:<env>`, use that. Otherwise use `AskUserQuestion` — question: `(7) Trigger a workflow?`, options: `Release`, `Deploy`, `No`. On `No`: terminate.
   - **Release** → pick the bump: `AskUserQuestion` — question: `Release — which bump?`, options: `patch`, `minor`, `major` (skip if `--release=<bump>`/auto already names one). Run `$RTK gh workflow run "$(node -p "require('./.claude/kermit/pref.json').workflows.release_file" 2>/dev/null || echo release.yml)" -f bump=<bump>`. Then emit the run: `$RTK gh run list --workflow=release.yml -L1`.
   - **Deploy** → pick the environment: `AskUserQuestion` — question: `Deploy — which environment?`, options sourced from `workflows.environments` in pref.json (fallback `staging`, `production`). Run `$RTK gh workflow run "$(node -p "require('./.claude/kermit/pref.json').workflows.deploy_file" 2>/dev/null || echo deploy.yml)" -f environment=<env>`. Then emit `$RTK gh run list --workflow=deploy.yml -L1`.
