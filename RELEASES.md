# Releases

What's new for you, release by release.

## v3.1.0 — 2026-08-07

> kermit now runs inside OpenAI Codex as well as Claude Code — same skill, same commands. Spawn it as a Codex subagent and it commits, changelogs and opens PRs entirely on its own, then hands back a machine-readable receipt.

### ✨ New

- Use kermit from OpenAI Codex. Install with `curl -fsSL .../install.sh | bash -s -- --codex` (or `--all` for both harnesses) and the same skill lands in Codex — nothing forked, nothing to keep in sync.
- Let agents run kermit unattended. In a non-interactive run — a Codex subagent, or headless Claude — kermit never stops to ask: every approval takes its stated default, and the run's receipt says so.
- Delegate commits to a kermit worker. A ready-to-copy subagent role file lets orchestrator agents hand commits, PRs and releases to kermit as the closing step of their workflows.
- Read the outcome at a glance. Every run now ends with a small `kermit-result` receipt — what ran, the commit, the changelog entry, whether it pushed — so people and agents alike can verify what happened.

### 📈 Improved

- No network? No problem. If a sandboxed run can't push or publish, kermit finishes cleanly, keeps the commit and notes as the deliverable, and tells you the one command left to run.
- First run in a fresh repo needs no setup when unattended: kermit bootstraps sensible defaults and keeps going — run `/kermit --init` any time to customise.

## v3.0.0 — 2026-07-17

> Installing kermit now copies 88KB instead of 14MB, and `--release` finishes the whole release for you — notes, version bump, tag, and a published GitHub release. The separate `/log-it` command has folded into kermit as `/kermit --changelog-sync`, so there's one skill to install instead of two.

### ✨ New
- Finish a release in one command. `/kermit --release` now writes your notes, bumps your version, commits, pushes, and publishes a tagged GitHub release — where before it wrote the notes and left the rest to you.
- Catch a changelog that's fallen behind with `/kermit --changelog-sync`. It finds commits that landed without an entry — you committed by hand, or a session ended early — shows you what's missing, and writes them in.
- Install on any platform, Windows included, with `npx skills add ndisisnd/kermit -g`.

### 📈 Improved
- Installing kermit copies 88KB instead of 14MB, because it no longer drags the demo video and the rest of the project onto your machine along with the skill.
- Changelog entries are grouped under the day they landed, so a week of work reads as a few dated sections instead of one flat wall.
- kermit now tells you where to report a security problem privately, and ships a readme that shows you the commit flow at a glance rather than describing it.

### 🐛 Fixed
- The release reminder no longer interrupts an ordinary push. It waits for a real merge into a protected branch — which is when a release is actually due.
- The same reminder stopped firing at its own shadow: the word "merge" inside a commit message or an echoed string no longer sets it off.

### ⚠️ Breaking
- `/log-it` is gone. Use `/kermit --changelog-sync` instead — it does the same job, and it's one less thing to install.
- The Windows PowerShell installer is gone. Install with `npx skills add ndisisnd/kermit -g`, which works the same on Windows, macOS and Linux.
- kermit's files moved into `skills/kermit/`. If you pinned anything to their old spots — a hook path, a download link — repoint it. A fresh install needs nothing from you.

## v2.0.0 — 2026-07-14

> kermit now writes release notes for the people using your software — and reminds you to before you ship. The older GitHub-based auto-release and deploy commands are stepping back for now while that side is redesigned.

### ✨ New
- Write user-facing release notes with `/kermit --release`. kermit gathers everything since your last release and rewrites it in plain language, grouped by type, into `RELEASES.md` — so the people using your software can see what changed for them.
- Never ship a release silently: when you merge or push to `main`, kermit reminds you to write release notes first and warns you if you skip. Switch it on during `/kermit --init`.
- Setup now covers release notes too — `/kermit --init` creates `RELEASES.md` for you and can draft an initial note from your history.

### ⚠️ Breaking
- The GitHub **Release** and **Deploy** automations — and their `--deploy` and `--workflows` commands — have been removed while that area is redesigned. `--release` no longer bumps the version or publishes; it writes release notes only. If you relied on the old one-command publish or deploy, use your usual `npm`/deploy steps for now — workflow support will return in a later version.

## v1.0.0 — 2026-07-14

> Meet kermit — one command that writes your commit messages, keeps a changelog for you, and now opens pull requests, drafts release notes, and ships releases too. Set it up once and stop thinking about how to write a good commit.

### ✨ New
- Turn your staged changes into a clean, conventional commit message without writing it yourself — kermit reads the diff, drafts the message, and records a changelog entry in the same step.
- Open or update a GitHub pull request straight from kermit. It writes the title and a structured summary from your branch, so raising a PR is one step instead of a context switch — just say "open a PR" or run `/kermit --pr`.
- Write user-facing **release notes** with `/kermit --release`. kermit gathers everything since your last release and rewrites it into plain-language notes, grouped by type, so the people using your software can see what changed for them.
- Cut real releases and deployments when you're ready: kermit can bump the version, publish, and open a GitHub Release, or put a commit live in an environment — and you can switch these on any time with `--workflows`.
- Point a teammate at a specific change: every changelog entry is now numbered, so "[24]" beats a date and a guess. Bringing an older changelog up to format? `--changelog-reset` numbers and tidies it for you.
- Make the changelog read the way your team likes — describe your own format, or answer a short interview during setup.
- Decide how much kermit checks with you, from confirming every step to writing, committing, and pushing with no prompts at all.
- Install from npm, and get a companion `log-it` command that backfills any changelog entries a commit slipped past.

### 📈 Improved
- Get started in one line — no cloning required — and land straight in setup right after installing.
- kermit is much cheaper to run. It loads far less on each commit, so day-to-day use costs a fraction of the tokens it used to.
- Your commits stay yours: kermit never adds AI co-authorship trailers, and it keeps its own settings and bookkeeping out of git so a commit never leaves your working tree dirty.

### 🐛 Fixed
- The installer no longer trips over a broken repository link, so setup works the first time you try it.
