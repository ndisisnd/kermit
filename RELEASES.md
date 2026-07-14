# Releases

What's new for you, release by release.

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
