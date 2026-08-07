# kermit --init — bootstrap protocol

Read only when `$KERMIT_DIR/pref.json` has `initialized: false` **or** `--init` was
passed. Runs once per repo. When it finishes, return to `SKILL.md` and continue as the
final step directs. `GATE(...)`, `HARNESS`, `KERMIT_DIR` and `INTERACTIVE` are defined in
SKILL.md and were resolved before this file was read.

## Zero-question bootstrap (check this first)

If `INTERACTIVE=false` **and** pref is missing or `initialized: false`, do **not** run the
interview below — a non-interactive run has nobody to answer it. Instead, in one batched call:

- Write `$KERMIT_DIR/pref.json`:
  `{"initialized":true,"init_commit":"<HEAD sha or null>","changelog":{"path":"CHANGELOG.md","protocol":null},"release_guard":false,"gate_mode":"flash"}`
  — `CHANGELOG.md` at the repo root, the default changelog protocol
  (`refs/changelog-protocol.md`), zero gates, no merge guard.
- Create `CHANGELOG.md` with header
  `# Changelog\n\nAll notable changes to this project will be documented here.\n` if absent.
- Write `$KERMIT_DIR/state.json`:
  `{"last_logged_commit":null,"last_number":0,"last_released_number":0,"backfill":null}`
  and git-ignore it:
  `grep -qxF "$KERMIT_DIR/state.json" .gitignore 2>/dev/null || printf '%s\n' "$KERMIT_DIR/state.json" >> .gitignore`.
- Emit `initialized by non-interactive bootstrap — run /kermit --init interactively to customise`.

Then **continue into the requested mode** (the Protocol dispatch in SKILL.md) — do not exit,
even if `--init` was the flag that got you here.

Everything below is the interactive path.

---

If `initialized` is `false` **or** `--init` was passed:
1. `GATE(question: "Set up your changelog", options: ["Create a new changelog", "I already have a changelog", "I have a CHANGELOG.md but I want to customise how it's written"], default: "Create a new changelog")`.
   - **"Create a new changelog"**: create `CHANGELOG.md` with header `# Changelog\n\nAll notable changes to this project will be documented here.\n`. Emit `Changelog created at CHANGELOG.md.` → proceed to **backfill check** below.
   - **"I already have a changelog"**: search the repo for a changelog file — `find . -maxdepth 3 -iname 'changelog*' -o -iname 'history*' -o -iname 'releases*' 2>/dev/null | grep -v node_modules | head -5`. If a file is found, emit the path and use it — **skip backfill check**, go to step 2. If **no file is found**, `GATE(question: "No changelog file found. What would you like to do?", options: ["Initialise one for me", "I'll give you the path"], default: "Initialise one for me")`. On **"Initialise one for me"**: create `CHANGELOG.md` as above → proceed to **backfill check**. On **"I'll give you the path"**: `GATE(question: "Changelog file path:", options: free text, default: "CHANGELOG.md")` — **skip backfill check**, go to step 2.
   - **"I have a CHANGELOG.md but I want to customise how it's written"**: locate the changelog with the same `find` as above (if none is found, fall back to the *"No changelog file found"* gate from the previous option). Then run the **custom protocol sub-flow** below. When it completes, **skip backfill check** and go to step 2.

   **Custom protocol sub-flow** (only runs on the customise option):
   `GATE(question: "How do you want to define your changelog format?", options: ["I'll describe it", "Interview me"], default: "Interview me")`.
   - **"I'll describe it"**: `GATE(question: "Describe how entries should be written (summary style, fields, files, breaking changes):", options: free text, default: "" )`. Store the answer as `{"description":"<free-text>"}`.
   - **"Interview me"**: carry these four questions together in **one** gate call (the GATE contract resolves a multi-question gate as a single tool call on interactive Claude):
     1. header `Summary` — question: `How should the summary be written?`, options: `Product goal / outcome`, `Technical description`, `One-line prose`.
     2. header `Fields` (multiSelect) — question: `What should each entry record?`, options: `Commit SHA`, `Date`, `Author`.
     3. header `Files` — question: `Show the touched files in each entry?`, options: `Yes`, `No`.
     4. header `Breaking` — question: `Flag breaking changes prominently?`, options: `Yes`, `No`.
     Store the answers as `{"summary":"<product-goal|technical|prose>","fields":["sha","date","author"],"show_files":<bool>,"flag_breaking":<bool>}`.
   Set `changelog.protocol` in pref.json to the resulting object (create the `"changelog"` object if absent). Emit `Custom changelog format saved to pref.json.`

   **Backfill check** (only runs after a fresh changelog file is created):
   Run `git log --oneline 2>/dev/null | wc -l` to count existing commits. If count > 0:
   `GATE(question: "This repo has existing commits. Add them to the changelog?", options: ["Yes, populate it automatically", "No, ignore past commits"], default: "No, ignore past commits")`.
   - **"Yes, populate it automatically"**: append a `## History` section to the changelog: `printf '\n## History\n\n' >> <changelog>` then `git log --format="- %ad — %s" --date=short --reverse >> <changelog>`. Emit `Changelog populated with <n> past commits.` Record `backfill` as `"done"` (written to state.json in the final write below).
   - **"No, ignore past commits"**: Record `backfill` as `"skipped"` (written to state.json below). Emit `Past commits will not appear in the changelog.`
   Either way: record the current HEAD SHA via `git log -1 --format="%H" 2>/dev/null` as `init_commit` (written to pref.json below). Returns empty string on a zero-commit repo — store as `null` in that case.

2. Ask the user how many gates each commit run should have.
   `GATE(question: "How much should kermit ask before acting?", options: ["Full (3 gates)", "Auto (1 gate)", "Flash (0 gates)", "Commit-only (0 gates)"], default: "Flash (0 gates)")`:
   - `Full (3 gates)` → `gate_mode = "full"` — approve the message, confirm commit, confirm push.
   - `Auto (1 gate)` → `gate_mode = "auto"` — approve the message once, then auto-commit and auto-push.
   - `Flash (0 gates)` → `gate_mode = "flash"` — write, commit and push immediately, no prompts.
   - `Commit-only (0 gates)` → `gate_mode = "commit-only"` — write and commit immediately, never push.

   Store the chosen `gate_mode` string in pref.json. It is the single source of truth
   for run gates; SKILL.md's Gate resolution derives the effective
   `auto_approve` / `auto_commit` / `auto_merge` / `push_enabled` values from it.

3. **Release-notes setup.** kermit keeps user-facing release notes in `RELEASES.md`, separate from the technical `CHANGELOG.md`. Default `release_guard` to `false` and the initial `last_released_number` to `0`.
   - **Scaffold the file.** If `RELEASES.md` does not exist, create it with header `# Releases\n\nWhat's new for you, release by release.\n` and emit `Release notes file created at RELEASES.md.` If it already exists, leave it untouched.
   - **Offer an inaugural note.** Only if the changelog already contains numbered entries (`grep -q '^## \[' <changelog>`) — i.e. there is release-worthy history to summarise — `GATE(question: "Draft an initial release note from your history?", options: ["Yes", "No"], default: "No")`. On `Yes`: follow `refs/protocol-release.md` steps 2–7 against the changelog to write the first `RELEASES.md` section (version defaults to `package.json` `version` if present, else `v1.0.0`); remember the highest changelog number it covered and use it as the initial `last_released_number` in the state write below. On `No` (or when the changelog has no numbered entries): leave `RELEASES.md` as the empty scaffold and keep `last_released_number: 0`.
   - **Merge-to-main guard.** Branch on `HARNESS`:
     - **`HARNESS=claude`** — `GATE(question: "Install the merge-to-main guard so kermit reminds you to write release notes before a release?", options: ["Yes", "No"], default: "No")`. On `Yes`: set `release_guard` to `true` and add a PreToolUse Bash hook to the project's `.claude/settings.json` running `"$HOME/.claude/skills/kermit/hooks/kermit-merge-guard.sh"` — **merge** into any existing `hooks` block, never clobbering other hooks (create `.claude/settings.json` with just this hook if it is absent). On `No`: keep `release_guard: false`.
     - **`HARNESS=codex`** — Codex hooks are beta, so the guard ships as a convention, not a hook. Set `release_guard` to `true` (meaning "convention communicated") and print this snippet for the user to paste into their repo's `AGENTS.md`:
       ```
       - After completing a change, delegate the commit to the kermit skill / kermit subagent rather than committing ad hoc.
       - Before merging or pushing to main/master, run `/kermit --release` (or spawn the kermit subagent in release mode) so the release ships user-facing notes.
       ```
       Do not write into the user's `AGENTS.md` yourself — print it and let them paste.

   Write **two files** — kermit splits stable config from volatile runtime state so per-commit writes never dirty a tracked file:
   - **Config** → `$KERMIT_DIR/pref.json`: `{"initialized":true,"init_commit":"<sha-or-null>","changelog":{"path":"<changelog-path-or-null>","protocol":<object-or-null>},"release_guard":<bool>,"gate_mode":"<full|auto|flash|commit-only>"}`. `changelog.path` is the changelog file located or created above (`--changelog-sync` reads it). `changelog.protocol` is the object set by the custom protocol sub-flow, or `null` when the default `refs/changelog-protocol.md` applies. `release_guard` is the merge-guard toggle set above. This file is safe to commit and share across a team.
   - **State** → `$KERMIT_DIR/state.json`: `{"last_logged_commit":null,"last_number":0,"last_released_number":<0-or-inaugural-N>,"backfill":"<done|skipped|null>"}`. `last_number` seeds the per-commit changelog counter at 0 (first entry becomes `[1]`); `last_released_number` seeds the release boundary (`0`, or the highest number an inaugural note covered); `backfill` is the value recorded in the backfill check. This file is rewritten on every commit and must **not** be tracked.
   - **Ignore the state file.** Ensure `$KERMIT_DIR/state.json` is git-ignored so those per-run writes stay out of the working tree: `grep -qxF "$KERMIT_DIR/state.json" .gitignore 2>/dev/null || printf '%s\n' "$KERMIT_DIR/state.json" >> .gitignore` (creates `.gitignore` if absent; the `grep -qxF` guard makes it idempotent). Do **not** ignore `pref.json`.

   If `--init` was passed: END (emit the `kermit-result` block defined in SKILL.md first — `mode: init`, `head: null`, `changelog_entry: null`, `pushed: no`, `published: n/a`). Otherwise: END init block — return to SKILL.md and continue at the **Protocol dispatch** (which honours `--pr`; the default is the commit flow).
