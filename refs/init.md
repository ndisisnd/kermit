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
   - **"Yes, populate it automatically"**: append a `## History` section to the changelog: `printf '\n## History\n\n' >> <changelog>` then `git log --format="- %ad — %s" --date=short --reverse >> <changelog>`. Emit `Changelog populated with <n> past commits.` Set `backfill` to `"done"` in pref.json.
   - **"No, ignore past commits"**: Set `backfill` to `"skipped"` in pref.json. Emit `Past commits will not appear in the changelog.`
   Either way: record the current HEAD SHA via `git log -1 --format="%H" 2>/dev/null` as `init_commit` in pref.json. Returns empty string on a zero-commit repo — store as `null` in that case.

2. Ask the user their automation preferences sequentially:
   - Use `AskUserQuestion` — question: `Auto-approve commit messages?`, options: `Yes`, `No`. Set `auto_approve` to `true` or `false` accordingly.
   - Use `AskUserQuestion` — question: `Auto-commit after approval?`, options: `Yes`, `No`. Set `auto_commit` to `true` or `false` accordingly.
   - Use `AskUserQuestion` — question: `Auto-push after committing?`, options: `Yes`, `No`. Set `auto_merge` to `true` or `false` accordingly.
   Write `{"initialized":true,"init_commit":"<sha-or-null>","backfill":"<done|skipped|null>","changelog":{"path":"<changelog-path-or-null>","protocol":<object-or-null>},"last_logged_commit":null,"auto_approve":<bool>,"auto_commit":<bool>,"auto_merge":<bool>}` to `.claude/kermit/pref.json`. `changelog.path` is the changelog file located or created above (log-it reads it). `changelog.protocol` is the object set by the custom protocol sub-flow, or `null` when the default `refs/changelog-protocol.md` applies. If `--init` was passed: END. Otherwise: END init block — return to SKILL.md and continue at step 1.
