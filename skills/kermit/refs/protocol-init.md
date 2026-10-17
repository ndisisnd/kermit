# kermit --init — bootstrap protocol

Read when `$KERMIT_DIR/pref.json` has `initialized: false` **or** `--init` was passed. Runs
once per repo. An un-initialized repo is set up here *before* the mode the user asked for —
when setup finishes, the **Finish** section hands back to SKILL.md's Protocol dispatch so that
mode still runs. `GATE(...)`, `HARNESS`, `KERMIT_DIR` and `INTERACTIVE` are defined in
SKILL.md and were resolved before this file was read.

## Default settings block

Shared by the zero-question bootstrap and the interactive "Use default settings" option. In one
batched call:

- Write `$KERMIT_DIR/pref.json`:
  `{"initialized":true,"init_commit":"<HEAD sha or null>","changelog":{"path":"CHANGELOG.md","protocol":null},"gate_mode":"flash"}`
  — `CHANGELOG.md` at the repo root, the default changelog protocol
  (`refs/changelog-protocol.md`), zero gates.
- Create `CHANGELOG.md` with header
  `# Changelog\n\nAll notable changes to this project will be documented here.\n` if absent.
  An existing `CHANGELOG.md` is kept as-is, never overwritten.
- Write `$KERMIT_DIR/state.json`:
  `{"last_logged_commit":null,"last_number":0,"last_released_number":0,"backfill":null}`
  and git-ignore it:
  `grep -qxF "$KERMIT_DIR/state.json" .gitignore 2>/dev/null || printf '%s\n' "$KERMIT_DIR/state.json" >> .gitignore`.

## Legacy merge-guard cleanup (every init run)

kermit up to v3.2.0 could install a merge-to-main reminder hook. v3.3.0 removed it and no
longer ships the script, so a leftover hook entry errors on every Bash call. Run this on
every init path — zero-question, default settings, and customise — before writing pref:

- In `.claude/settings.json` and `.claude/settings.local.json` (skip a file that is absent),
  delete every hook whose `command` contains `kermit-merge-guard.sh`. Then delete any
  `PreToolUse` matcher block left with an empty `hooks` array, and a `PreToolUse` key left
  empty. Leave every other hook and key exactly as it was. Do not touch a file with no match.
- Drop a `release_guard` key from the existing `$KERMIT_DIR/pref.json` if present (the pref
  writes below omit it anyway).
- When a hook entry was removed, emit `Removed the retired kermit merge-guard hook from <file>.`

## Zero-question bootstrap (check this first)

If `INTERACTIVE=false` **and** pref is missing or `initialized: false`, do **not** run the
interview below — a non-interactive run has nobody to answer it. Run the **Legacy merge-guard
cleanup**, then the **Default settings block**, emit `initialized by non-interactive bootstrap — run /kermit --init interactively to customise`,
then **continue into the requested mode** (the Protocol dispatch in SKILL.md) — do not exit,
even if `--init` was the flag that got you here.

Everything below is the interactive path.

---

If `initialized` is `false` **or** `--init` was passed, run the **Legacy merge-guard cleanup** first, then:
1. **Defaults or customise.** `GATE(question: "How do you want to set up kermit?", options: ["Use default settings (new CHANGELOG.md, flash mode)", "Customise"], default: "Use default settings (new CHANGELOG.md, flash mode)")`.
   - **"Use default settings"**: run the **Default settings block**, emit `kermit set up with default settings — CHANGELOG.md, flash mode (0 gates). Run /kermit --init to customise.`, then skip steps 2–4 and go to **Finish**.
   - **"Customise"**: continue to step 2.

2. `GATE(question: "Set up your changelog", options: ["Create a new changelog", "I already have a changelog", "I have a CHANGELOG.md but I want to customise how it's written"], default: "Create a new changelog")`.
   - **"Create a new changelog"**: create `CHANGELOG.md` with header `# Changelog\n\nAll notable changes to this project will be documented here.\n`. Emit `Changelog created at CHANGELOG.md.` → proceed to **backfill check** below.
   - **"I already have a changelog"**: search the repo for a changelog file — `find . -maxdepth 3 -iname 'changelog*' -o -iname 'history*' -o -iname 'releases*' 2>/dev/null | grep -v node_modules | head -5`. If a file is found, emit the path and use it — **skip backfill check**, go to step 3. If **no file is found**, `GATE(question: "No changelog file found. What would you like to do?", options: ["Initialise one for me", "I'll give you the path"], default: "Initialise one for me")`. On **"Initialise one for me"**: create `CHANGELOG.md` as above → proceed to **backfill check**. On **"I'll give you the path"**: `GATE(question: "Changelog file path:", options: free text, default: "CHANGELOG.md")` — **skip backfill check**, go to step 3.
   - **"I have a CHANGELOG.md but I want to customise how it's written"**: locate the changelog with the same `find` as above (if none is found, fall back to the *"No changelog file found"* gate from the previous option). Then run the **custom protocol sub-flow** below. When it completes, **skip backfill check** and go to step 3.

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

3. Ask the user how many gates each commit run should have.
   `GATE(question: "How much should kermit ask before acting?", options: ["Full (3 gates)", "Auto (1 gate)", "Flash (0 gates)", "Commit-only (0 gates)"], default: "Flash (0 gates)")`:
   - `Full (3 gates)` → `gate_mode = "full"` — approve the message, confirm commit, confirm push.
   - `Auto (1 gate)` → `gate_mode = "auto"` — approve the message once, then auto-commit and auto-push.
   - `Flash (0 gates)` → `gate_mode = "flash"` — write, commit and push immediately, no prompts.
   - `Commit-only (0 gates)` → `gate_mode = "commit-only"` — write and commit immediately, never push.

   Store the chosen `gate_mode` string in pref.json. It is the single source of truth
   for run gates; SKILL.md's Gate resolution derives the effective
   `auto_approve` / `auto_commit` / `auto_merge` / `push_enabled` values from it.

4. **Release-notes setup.** kermit keeps user-facing release notes in `RELEASES.md`, separate from the technical `CHANGELOG.md`. Default the initial `last_released_number` to `0`.
   - **Scaffold the file.** If `RELEASES.md` does not exist, create it with header `# Releases\n\nWhat's new for you, release by release.\n` and emit `Release notes file created at RELEASES.md.` If it already exists, leave it untouched.
   - **Offer an inaugural note.** Only if the changelog already contains numbered entries (`grep -q '^## \[' <changelog>`) — i.e. there is release-worthy history to summarise — `GATE(question: "Draft an initial release note from your history?", options: ["Yes", "No"], default: "No")`. On `Yes`: follow `refs/protocol-release.md` steps 2–7 against the changelog to write the first `RELEASES.md` section (version defaults to `package.json` `version` if present, else `v1.0.0`); remember the highest changelog number it covered and use it as the initial `last_released_number` in the state write below. On `No` (or when the changelog has no numbered entries): leave `RELEASES.md` as the empty scaffold and keep `last_released_number: 0`.
   - **Codex routing line.** Only when `HARNESS=codex`: print this line for the user to paste into their repo's `AGENTS.md`:
       ```
       - After completing a change, delegate the commit to the kermit skill / kermit subagent rather than committing ad hoc.
       ```
       Do not write into the user's `AGENTS.md` yourself — print it and let them paste.

   Write **two files** — kermit splits stable config from volatile runtime state so per-commit writes never dirty a tracked file:
   - **Config** → `$KERMIT_DIR/pref.json`: `{"initialized":true,"init_commit":"<sha-or-null>","changelog":{"path":"<changelog-path-or-null>","protocol":<object-or-null>},"gate_mode":"<full|auto|flash|commit-only>"}`. `changelog.path` is the changelog file located or created above (`--changelog-sync` reads it). `changelog.protocol` is the object set by the custom protocol sub-flow, or `null` when the default `refs/changelog-protocol.md` applies. This file is safe to commit and share across a team.
   - **State** → `$KERMIT_DIR/state.json`: `{"last_logged_commit":null,"last_number":0,"last_released_number":<0-or-inaugural-N>,"backfill":"<done|skipped|null>"}`. `last_number` seeds the per-commit changelog counter at 0 (first entry becomes `[1]`); `last_released_number` seeds the release boundary (`0`, or the highest number an inaugural note covered); `backfill` is the value recorded in the backfill check. This file is rewritten on every commit and must **not** be tracked.
   - **Ignore the state file.** Ensure `$KERMIT_DIR/state.json` is git-ignored so those per-run writes stay out of the working tree: `grep -qxF "$KERMIT_DIR/state.json" .gitignore 2>/dev/null || printf '%s\n' "$KERMIT_DIR/state.json" >> .gitignore` (creates `.gitignore` if absent; the `grep -qxF` guard makes it idempotent). Do **not** ignore `pref.json`.

## Finish

Both interactive paths (defaults and customise) end here.

- **`--init` was passed** → setup was the whole request. END: emit the `kermit-result` block defined in SKILL.md first — `mode: init`, `head: null`, `changelog_entry: null`, `pushed: no`, `published: n/a`.
- **Otherwise** (init ran because the repo was not set up) → emit `Setup complete — continuing with your /kermit run.`, return to SKILL.md and continue at the **Protocol dispatch** with the flags from the original invocation (`--pr`, `--release`, `--changelog-sync`; none → the commit flow). Do not ask the user to re-run kermit, and do not emit a `kermit-result` block for init — the continued mode emits the run's single block.
