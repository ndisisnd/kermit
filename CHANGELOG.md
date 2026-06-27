# Changelog

All notable changes to this project will be documented here.

## 2026-06-28

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
