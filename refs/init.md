# kermit --init — bootstrap protocol

Read only when `.claude/kermit/pref.json` has `initialized: false` **or** `--init` was
passed. Runs once per repo. When it finishes, return to `SKILL.md` and continue as the
final step directs.

---

If `initialized` is `false` **or** `--init` was passed:
1. Use `AskUserQuestion` — question: `Set up your changelog`, options: `Create a new changelog`, `I already have a changelog`, `I have a CHANGELOG.md but I want to customise how it's written`.
   - **"Create a new changelog"**: create `CHANGELOG.md` with header `# Changelog\n\nAll notable changes to this project will be documented here.\n`. Emit `Changelog created at CHANGELOG.md.` → proceed to **backfill check** below.
   - **"I already have a changelog"**: search the repo for a changelog file — `find . -maxdepth 3 -iname 'changelog*' -o -iname 'history*' -o -iname 'releases*' 2>/dev/null | grep -v node_modules | head -5`. If a file is found, emit the path and use it — **skip backfill check**, go to step 2. If **no file is found**, use `AskUserQuestion` — question: `No changelog file found. What would you like to do?`, options: `Initialise one for me`, `I'll give you the path`. On **"Initialise one for me"**: create `CHANGELOG.md` as above → proceed to **backfill check**. On **"I'll give you the path"**: prompt the user for the path via `AskUserQuestion` (free-text) — **skip backfill check**, go to step 2.
   - **"I have a CHANGELOG.md but I want to customise how it's written"**: locate the changelog with the same `find` as above (if none is found, fall back to the *"No changelog file found"* prompt from the previous option). Then run the **custom protocol sub-flow** below. When it completes, **skip backfill check** and go to step 2.

   **Custom protocol sub-flow** (only runs on the customise option):
   Use `AskUserQuestion` — question: `How do you want to define your changelog format?`, options: `I'll describe it`, `Interview me`.
   - **"I'll describe it"**: use `AskUserQuestion` (free-text) — question: `Describe how entries should be written (summary style, fields, files, breaking changes):`. Store the answer as `{"description":"<free-text>"}`.
   - **"Interview me"**: use a single `AskUserQuestion` call carrying these four questions together:
     1. header `Summary` — question: `How should the summary be written?`, options: `Product goal / outcome`, `Technical description`, `One-line prose`.
     2. header `Fields` (multiSelect) — question: `What should each entry record?`, options: `Commit SHA`, `Date`, `Author`.
     3. header `Files` — question: `Show the touched files in each entry?`, options: `Yes`, `No`.
     4. header `Breaking` — question: `Flag breaking changes prominently?`, options: `Yes`, `No`.
     Store the answers as `{"summary":"<product-goal|technical|prose>","fields":["sha","date","author"],"show_files":<bool>,"flag_breaking":<bool>}`.
   Set `changelog.protocol` in pref.json to the resulting object (create the `"changelog"` object if absent). Emit `Custom changelog format saved to pref.json.`

   **Backfill check** (only runs after a fresh changelog file is created):
   Run `git log --oneline 2>/dev/null | wc -l` to count existing commits. If count > 0:
   Use `AskUserQuestion` — question: `This repo has existing commits. Add them to the changelog?`, options: `Yes, populate it automatically`, `No, ignore past commits`.
   - **"Yes, populate it automatically"**: append a `## History` section to the changelog: `printf '\n## History\n\n' >> <changelog>` then `git log --format="- %ad — %s" --date=short --reverse >> <changelog>`. Emit `Changelog populated with <n> past commits.` Record `backfill` as `"done"` (written to state.json in the final write below).
   - **"No, ignore past commits"**: Record `backfill` as `"skipped"` (written to state.json below). Emit `Past commits will not appear in the changelog.`
   Either way: record the current HEAD SHA via `git log -1 --format="%H" 2>/dev/null` as `init_commit` (written to pref.json below). Returns empty string on a zero-commit repo — store as `null` in that case.

2. Ask the user how many gates each commit run should have. Use `AskUserQuestion` —
   question: `How much should kermit ask before acting?`, options:
   - `Full (3 gates)` → `gate_mode = "full"` — approve the message, confirm commit, confirm push.
   - `Auto (1 gate)` → `gate_mode = "auto"` — approve the message once, then auto-commit and auto-push.
   - `Flash (0 gates)` → `gate_mode = "flash"` — write, commit and push immediately, no prompts.
   - `Commit-only (0 gates)` → `gate_mode = "commit-only"` — write and commit immediately, never push.

   Store the chosen `gate_mode` string in pref.json. It is the single source of truth
   for run gates; SKILL.md's Gate resolution derives the effective
   `auto_approve` / `auto_commit` / `auto_merge` / `push_enabled` values from it.

3. **Workflow setup** (Releases & Deployments). Build a `workflows` object, default `{"enabled":false,"release_file":"release.yml","deploy_file":"deploy.yml","environments":["staging","production"],"auto":"none"}`. (When reached standalone via `/kermit --workflows`, run only this step's questions and scaffolding, then merge just the resulting `workflows` object into the existing pref — skip the full-pref write at the end of this step.)
   - Use `AskUserQuestion` — question: `Let kermit trigger Release/Deploy workflows after a commit?`, options: `Yes`, `No`. On `No`: keep `enabled:false` and skip the rest of this step.
   - On `Yes`: set `workflows.enabled` to `true`. Then check for existing workflows: `ls .github/workflows/*.yml 2>/dev/null`.
     - If `release.yml` **and** `deploy.yml` both already exist, skip scaffolding.
     - Otherwise use `AskUserQuestion` — question: `Add the missing Release/Deploy workflow templates to this repo?`, options: `Yes`, `No`. On `Yes`: for each of `release.yml` / `deploy.yml` that is **absent** in `.github/workflows/`, copy it from the installed skill's `refs/workflows/<file>` into `.github/workflows/<file>` (`mkdir -p .github/workflows` first). **Never overwrite an existing file** — skip any that are present. Emit which files were written.

   Write **two files** — kermit splits stable config from volatile runtime state so per-commit writes never dirty a tracked file:
   - **Config** → `.claude/kermit/pref.json`: `{"initialized":true,"init_commit":"<sha-or-null>","changelog":{"path":"<changelog-path-or-null>","protocol":<object-or-null>},"workflows":<workflows-object>,"gate_mode":"<full|auto|flash|commit-only>"}`. `changelog.path` is the changelog file located or created above (log-it reads it). `changelog.protocol` is the object set by the custom protocol sub-flow, or `null` when the default `refs/changelog-protocol.md` applies. `workflows` is the object built in step 3 (defaults to `enabled:false`). This file is safe to commit and share across a team.
   - **State** → `.claude/kermit/state.json`: `{"last_logged_commit":null,"last_number":0,"backfill":"<done|skipped|null>"}`. `last_number` seeds the per-commit changelog counter at 0 (first entry becomes `[1]`); `backfill` is the value recorded in the backfill check. This file is rewritten on every commit and must **not** be tracked.
   - **Ignore the state file.** Ensure `.claude/kermit/state.json` is git-ignored so those per-run writes stay out of the working tree: `grep -qxF '.claude/kermit/state.json' .gitignore 2>/dev/null || printf '.claude/kermit/state.json\n' >> .gitignore` (creates `.gitignore` if absent; the `grep -qxF` guard makes it idempotent). Do **not** ignore `pref.json`.

   If `--init` was passed: END. Otherwise: END init block — return to SKILL.md and continue at the **Protocol dispatch** (which honours `--pr`; the default is the commit flow).
