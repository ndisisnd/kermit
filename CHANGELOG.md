# Changelog

All notable changes to this project will be documented here.

## [20] — Batch pref reads and require reuse across steps

2026-07-06

- `SKILL.md`: add a general protocol rule — batch independent Bash calls into one round trip, and reuse `.claude/kermit/pref.json` values already read at the mode-check step instead of re-reading the file in step 5
- `README.md`: trim the intro copy to a tighter one-line pitch

## [19] — Consolidate gate booleans into a single gate_mode

2026-07-06

- `SKILL.md`: replace `auto_approve`/`auto_commit`/`auto_merge` checks with a `gate_mode`-derived resolution (`full`/`auto`/`flash`/`commit-only`) covering steps 3, 4 and 6, plus a `push_enabled` flag; merge rtk detection into the diff-read step; defer the `gh auth status` check from step 1 to step 7 so it's never paid for on commits that don't trigger a workflow
- `refs/init.md`: ask one `gate_mode` question during `--init` instead of three separate yes/no prompts
- `pref.json`: store `gate_mode` instead of the three `auto_*` booleans
- `.claude/skills/log-it/SKILL.md`: bump model to `sonnet`
- `.gitignore`: ignore `improve/`
- `README.md`: add header banner and tagline

## [18] — Turn on Release/Deploy workflows later with `--workflows`

2026-07-06

- `SKILL.md`: add a `--workflows` flag (invoke line + Usage) and a mode-check branch that runs `refs/init.md` step 3 standalone — enable workflows and scaffold missing `release.yml`/`deploy.yml`, merging just the `workflows` object into pref — so you can opt in after declining at `--init`; the commit flow never re-prompts on its own
- `refs/init.md`: note on step 3 that a standalone `--workflows` run merges only the `workflows` object and skips the full-pref write

## [17] — Leaner CI: skip doc-only runs and cancel superseded ones

2026-07-06

- `.github/workflows/ci.yml`: add a `paths` filter so CI runs only when `install.sh`, `package.json`, `SKILL.md`, `refs/**`, or the workflows change (doc-only commits no longer trigger it); add `concurrency` to cancel an in-progress run when a newer commit is pushed

## [16] — Keep AI attribution off your commits

2026-07-06

- `SKILL.md`: step 2 now forbids AI co-authorship/attribution trailers (`Co-Authored-By: <AI>`, `Generated with …`) in commit messages, and strips them on revision

## [15] — kermit v2: workflow orchestration, numbered changelogs, and a changelog reset

2026-07-06

- `SKILL.md`: add `--release`/`--deploy` flags, a `--changelog-reset` mode check, a `gh` preflight, per-commit `## [N]` numbering in step 5, and a step 7 "trigger a workflow?" gate
- `refs/changelog-protocol.md`: switch entries to `## [N] — summary` with a Numbering section; note `## v` version markers are unnumbered
  - `.claude/skills/log-it/refs/changelog-protocol.md`: mirror the format (kept byte-identical)
- `refs/changelog-reset.md`: Added — protocol to renumber/normalise an existing changelog (backup + diff + approval, idempotent)
- `refs/init.md`: seed `changelog.last_number`; add a workflow-setup step that can scaffold `release.yml`/`deploy.yml` into a repo
- `.github/workflows/release.yml`: extract release notes as every entry since the last `## v` marker, insert a version marker on release, add concurrency + an empty-notes guard
- `.github/workflows/deploy.yml`: Added — environment-gated Deploy workflow; command from the target repo (`deploy:<env>` / `DEPLOY_CMD` / no-op)
- `refs/workflows/release.yml`, `refs/workflows/deploy.yml`: Added — scaffolding templates shipped for `--init`
- `.claude/skills/log-it/SKILL.md`: write one numbered entry per commit (no more date grouping)
- `pref.json`: add `changelog.last_number` and a `workflows` config object
- `install.sh`, `install.ps1`, `bin/kermit.js`: ship the `refs/workflows/` subdir (recurse in the Node installer)
- `README.md`: document the flags, numbered changelog, and Releases & Deployments
- `.gitignore`: ignore `*.bak` (changelog-reset backups)
- `CHANGELOG.md`: renumber existing entries `[1]`–`[14]` to the new convention

## [14] — Automated releases — CI guards every PR and one click ships kermit to npm

2026-07-06

- `.github/workflows/ci.yml`: Added — lint `install.sh` with shellcheck, assert every path in package.json `files` exists, and verify all `refs/*.md` pointers in SKILL.md resolve
- `.github/workflows/release.yml`: Added — manual-dispatch release; bump version, publish to npm with provenance, push commit + tag, and cut a GitHub Release with notes from the top CHANGELOG entry
- `bin/kermit.js`: wipe the destination `refs/` dir before copying so files dropped in an upgrade don't linger

## [13] — Cheaper to run — kermit loads ~70% fewer tokens per commit, and reinstalls stay clean

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

## [12] — One-line install — no git clone, just curl the script

2026-07-04

- `install.sh`: fetch `SKILL.md`, `refs/*`, and `pref.json` from raw GitHub when run standalone (`curl … | bash`), falling back to local copies when run from a checkout
- `install.ps1`: mirror the download/local logic for Windows via `Invoke-WebRequest`
- `README.md`: replace both `git clone` install blocks with `curl … | bash` (macOS/Linux) and `irm … | iex` (Windows) one-liners

## [11] — Guide users straight into setup after installing

2026-07-04

- `install.sh`: after copying files, print a one-line summary of what kermit does, prompt the user to run `/kermit --init` in any local repo, note they can tailor the installed `SKILL.md`, then a magenta `Thank you JC ❤️`
- `install.ps1`: mirror the post-install guidance, colouring the thank-you line with `Write-Host -ForegroundColor Magenta`
- `bin/kermit.js`: mirror the post-install guidance with an ANSI-magenta thank-you line
- `README.md`: tidy trailing newline in the Requirements section

## [10] — Fix broken manual-install clone URL so the installer actually runs

2026-07-04

- `README.md`: correct the git clone owner from `andychan` to `ndisisnd` in both the macOS/Linux and Windows install blocks, so the clone no longer 404s and the cascade of downstream errors (`cd`, `chmod`, `./install.sh` all failing) is resolved

## [9] — Keep changelog settings together and seed them on install

2026-07-03

- `pref.json`: nest changelog settings under a `changelog` object (`path` + `protocol`); add `last_logged_commit`
- `SKILL.md`: init write template now records `changelog.path` alongside `changelog.protocol`
- `install.sh`: copy the `pref.json` template into the installed skill dir
- `install.ps1`: copy the `pref.json` template into the installed skill dir
- `bin/kermit.js`: copy the `pref.json` template on npm install
- `package.json`: add `pref.json` to the published `files` list

## [8] — Let teams write changelogs their own way, with clearer default entries

2026-07-03

- `refs/changelog-protocol.md`: rewrite the entry format — summary is now a `##` heading stating the product goal (surfacing breaking/large changes), date on its own line, one bullet per touched file with sub-points
  - replace exemplars with feature, bug-fix+security, and breaking-change samples
- `.claude/skills/log-it/refs/changelog-protocol.md`: mirror the rewritten protocol
- `SKILL.md`: add a third init option to customise how the changelog is written (describe-it or interview), persist the format under `changelog.protocol` in pref.json, and read it when writing entries
- `.claude/skills/log-it/SKILL.md`: read `changelog.path` and `changelog.protocol` from pref.json when locating the file and writing entries

## [7] — Keep local pref.json out of the repository

2026-06-28

- Changed: `.gitignore` — add `.claude/kermit/pref.json` entry
- Removed: `.claude/kermit/pref.json` — untracked from git

## [6] — --init re-runs the full init block instead of a one-liner shortcut

2026-06-28

- Changed: `SKILL.md` — `--init` now triggers the full init block; removed the old one-liner shortcut path; clarified that `--init` ends after pref write rather than continuing to step 1
- Changed: `.claude/kermit/pref.json` — update `last_logged_commit` to latest HEAD SHA

## [5] — Add automation preferences: auto-approve, auto-commit, auto-merge

2026-06-28

- Changed: `SKILL.md` — init flow asks three sequential AskUserQuestion calls for automation prefs; steps 3, 4, 6 short-circuit when the corresponding flag is `true`
- Changed: `pref.json` — add `auto_approve`, `auto_commit`, `auto_merge` fields (null default) to the template
- Changed: `.claude/kermit/pref.json` — add `auto_approve`, `auto_commit`, `auto_merge` fields to the live pref file

## [4] — Fix the GitHub repository URL in package.json

2026-06-08

- Changed: `package.json` — correct repo URL from andychan to ndisisnd
- Changed: `.claude/kermit/pref.json` — add `last_logged_commit` field for log-it integration

## [3] — Add the log-it skill to sync missed changelog entries

2026-06-08

- Added: `.claude/skills/log-it/SKILL.md` — the `log-it` skill; detects commits not yet in the changelog by comparing git history against the last logged SHA or date entry, then prompts to write the missing entries
- Added: `.claude/skills/log-it/refs/changelog-protocol.md` — changelog entry format reference used by `log-it` at runtime
- Changed: `SKILL.md` — adds `/log-it` reminder tip after message approval and on manual commit exit; writes `last_logged_commit` to `pref.json` after each changelog update

## [2] — Publish kermit as the kermit-msg npm package

2026-06-08

- Added: `package.json` — npm package manifest (`kermit-msg`) with bin entry, file list, and keywords
- Added: `bin/kermit.js` — Node installer that copies `SKILL.md` and `refs/` into `~/.claude/skills/kermit/`
- Added: `LICENSE` — MIT license
- Added: `asset/readme.jpg` — hero image for README
- Changed: `README.md` — rewritten with npm/npx install path, visual header, and step-by-step how-it-works
- Changed: `SKILL.md` — adds init check block covering changelog setup, backfill, and pref.json persistence
- Changed: `.gitignore` — adds `node_modules/` exclusion
- Added: `pref.json` — root-level preference template

## [1] — Make kermit distributable with install scripts and docs

2026-06-07

- Added: `install.sh` (macOS/Linux) and `install.ps1` (Windows) to copy skill files into `~/.claude/skills/kermit/`
- Added: `README.md` with full install, usage, and requirements docs
- Added: `refs/changelog-protocol.md` — changelog format spec with exemplars for the skill to reference at runtime
- Changed: SKILL.md adds a `refs` declaration, tightens commit format spec (type/scope/emoji, rtk fallback, BREAKING CHANGE footer)
