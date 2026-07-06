# Changelog

All notable changes to this project will be documented here.

## Cheaper to run — kermit loads ~70% fewer tokens per commit, and reinstalls stay clean

2026-07-06

- `SKILL.md`: replace the one-time `--init` block with a pointer to `refs/init.md`, so the init protocol only loads on `--init`
  - drop the inline commit-format restatement (kept solely in step 2) and the inline changelog-format restatement
  - defer reading `refs/changelog-protocol.md` to step 5, and only when no custom protocol is set
- `refs/init.md`: Added — full `--init` bootstrap protocol extracted verbatim from SKILL.md
- `refs/commit-protocol.md`: Removed — the commit format now lives only in SKILL.md step 2
- `refs/changelog-protocol.md`: trim the redundant writing-rules section and two of three exemplars
- `.claude/skills/log-it/SKILL.md`: strip the inline changelog format; defer to `refs/changelog-protocol.md`
- `.claude/skills/log-it/refs/changelog-protocol.md`: sync the trimmed copy (kept byte-identical)
- `install.sh`: swap `commit-protocol.md` for `init.md` in the ref list; wipe `refs/` before copying so dropped files don't linger
- `install.ps1`: mirror the ref-list change and the `refs/` prune for Windows
- `.gitignore`: ignore the local `kermit-v1.md` plan

## One-line install — no git clone, just curl the script

2026-07-04

- `install.sh`: fetch `SKILL.md`, `refs/*`, and `pref.json` from raw GitHub when run standalone (`curl … | bash`), falling back to local copies when run from a checkout
- `install.ps1`: mirror the download/local logic for Windows via `Invoke-WebRequest`
- `README.md`: replace both `git clone` install blocks with `curl … | bash` (macOS/Linux) and `irm … | iex` (Windows) one-liners

## Guide users straight into setup after installing

2026-07-04

- `install.sh`: after copying files, print a one-line summary of what kermit does, prompt the user to run `/kermit --init` in any local repo, note they can tailor the installed `SKILL.md`, then a magenta `Thank you JC ❤️`
- `install.ps1`: mirror the post-install guidance, colouring the thank-you line with `Write-Host -ForegroundColor Magenta`
- `bin/kermit.js`: mirror the post-install guidance with an ANSI-magenta thank-you line
- `README.md`: tidy trailing newline in the Requirements section

## Fix broken manual-install clone URL so the installer actually runs

2026-07-04

- `README.md`: correct the git clone owner from `andychan` to `ndisisnd` in both the macOS/Linux and Windows install blocks, so the clone no longer 404s and the cascade of downstream errors (`cd`, `chmod`, `./install.sh` all failing) is resolved

## Keep changelog settings together and seed them on install

2026-07-03

- `pref.json`: nest changelog settings under a `changelog` object (`path` + `protocol`); add `last_logged_commit`
- `SKILL.md`: init write template now records `changelog.path` alongside `changelog.protocol`
- `install.sh`: copy the `pref.json` template into the installed skill dir
- `install.ps1`: copy the `pref.json` template into the installed skill dir
- `bin/kermit.js`: copy the `pref.json` template on npm install
- `package.json`: add `pref.json` to the published `files` list

## Let teams write changelogs their own way, with clearer default entries

2026-07-03

- `refs/changelog-protocol.md`: rewrite the entry format — summary is now a `##` heading stating the product goal (surfacing breaking/large changes), date on its own line, one bullet per touched file with sub-points
  - replace exemplars with feature, bug-fix+security, and breaking-change samples
- `.claude/skills/log-it/refs/changelog-protocol.md`: mirror the rewritten protocol
- `SKILL.md`: add a third init option to customise how the changelog is written (describe-it or interview), persist the format under `changelog.protocol` in pref.json, and read it when writing entries
- `.claude/skills/log-it/SKILL.md`: read `changelog.path` and `changelog.protocol` from pref.json when locating the file and writing entries

## 2026-06-28

Gitignored `pref.json` and removed it from git tracking so local preferences stay out of the repository.

- Changed: `.gitignore` — add `.claude/kermit/pref.json` entry
- Removed: `.claude/kermit/pref.json` — untracked from git

---

Updated `--init` behavior in SKILL.md so it re-runs the full init block rather than just creating a changelog file. Bumped `last_logged_commit` in pref.json to the current HEAD SHA.

- Changed: `SKILL.md` — `--init` now triggers the full init block; removed the old one-liner shortcut path; clarified that `--init` ends after pref write rather than continuing to step 1
- Changed: `.claude/kermit/pref.json` — update `last_logged_commit` to latest HEAD SHA

---

Added `auto_approve`, `auto_commit`, and `auto_merge` boolean preferences to kermit. During init, three sequential prompts collect the user's automation choices and persist them to `pref.json`. The commit flow now checks these flags and skips the corresponding confirmation prompts when set to `true`.

- Changed: `SKILL.md` — init flow asks three sequential AskUserQuestion calls for automation prefs; steps 3, 4, 6 short-circuit when the corresponding flag is `true`
- Changed: `pref.json` — add `auto_approve`, `auto_commit`, `auto_merge` fields (null default) to the template
- Changed: `.claude/kermit/pref.json` — add `auto_approve`, `auto_commit`, `auto_merge` fields to the live pref file

## 2026-06-08

Fixed the GitHub repository URL in `package.json` and updated changelog tracking in `pref.json`.

- Changed: `package.json` — correct repo URL from andychan to ndisisnd
- Changed: `.claude/kermit/pref.json` — add `last_logged_commit` field for log-it integration

## 2026-06-08

Added the `log-it` skill for syncing the changelog after unlogged or manually committed changes.

- Added: `.claude/skills/log-it/SKILL.md` — the `log-it` skill; detects commits not yet in the changelog by comparing git history against the last logged SHA or date entry, then prompts to write the missing entries
- Added: `.claude/skills/log-it/refs/changelog-protocol.md` — changelog entry format reference used by `log-it` at runtime
- Changed: `SKILL.md` — adds `/log-it` reminder tip after message approval and on manual commit exit; writes `last_logged_commit` to `pref.json` after each changelog update

## 2026-06-08

Published kermit as the `kermit-msg` npm package with a Node.js installer script, added MIT license, rewrote the README with npm install instructions and a how-it-works walkthrough, and extended SKILL.md with the changelog init check protocol.

- Added: `package.json` — npm package manifest (`kermit-msg`) with bin entry, file list, and keywords
- Added: `bin/kermit.js` — Node installer that copies `SKILL.md` and `refs/` into `~/.claude/skills/kermit/`
- Added: `LICENSE` — MIT license
- Added: `asset/readme.jpg` — hero image for README
- Changed: `README.md` — rewritten with npm/npx install path, visual header, and step-by-step how-it-works
- Changed: `SKILL.md` — adds init check block covering changelog setup, backfill, and pref.json persistence
- Changed: `.gitignore` — adds `node_modules/` exclusion
- Added: `pref.json` — root-level preference template

## 2026-06-07

Added install scripts, a README, and a changelog protocol reference to make kermit distributable and self-documenting.

- Added: `install.sh` (macOS/Linux) and `install.ps1` (Windows) to copy skill files into `~/.claude/skills/kermit/`
- Added: `README.md` with full install, usage, and requirements docs
- Added: `refs/changelog-protocol.md` — changelog format spec with exemplars for the skill to reference at runtime
- Changed: SKILL.md adds a `refs` declaration, tightens commit format spec (type/scope/emoji, rtk fallback, BREAKING CHANGE footer)
