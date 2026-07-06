<div align="center">

# ✍🏻 kermit

<br />

### Commit good code, but what about good committing?

<sub>Lightwight opinionated conventional commit style with emoji prefixes, in-built changelog, deployment, release management, and breaking change emission. </sub>

<br />

<img src="./asset/readme.jpg">

<br />

**One command. Intelligent, automated committing.** One-time setup for you to automate commit messages.

</div>

## ⬇️ Installation

**npm (recommended)**

```bash
npx kermit-msg
```

Or install globally:

```bash
npm install -g kermit-msg
kermit-msg
```

**macOS / Linux (curl)**

```bash
curl -fsSL https://raw.githubusercontent.com/ndisisnd/kermit/main/install.sh | bash
```

**Windows (PowerShell)**

```powershell
irm https://raw.githubusercontent.com/ndisisnd/kermit/main/install.ps1 | iex
```

All methods install `SKILL.md` and `refs/` into `~/.claude/skills/kermit/`.

## 🌟 How to use

In any Claude Code session, invoke the skill:

```
/kermit
```

Or describe what you want:

> "commit this", "make a commit", "commit my changes"

### Initialize changelog

Run once per repo to create `CHANGELOG.md`:

```
/kermit --init
```

### Flags

| Flag | What it does |
|------|--------------|
| `--init` | Re-run the full setup (changelog + automation + workflow prefs), then exit |
| `--changelog-reset [--apply]` | Rewrite an existing changelog to the latest conventions — adds `## [N]` numbering and normalises headings/dates/bullets. Backs up to `CHANGELOG.md.bak`, shows a diff, and asks before writing (`--apply` skips the confirm), then exits |
| `--release` | After committing, dispatch the **Release** workflow (version bump → npm publish → tag → GitHub Release) via `gh` |
| `--deploy` | After committing, dispatch the **Deploy** workflow (put the commit live in a chosen environment) via `gh` |

## ✨ How it works

1. Reads your staged diff
2. Writes a commit message — emoji prefix, Conventional Commits type and scope, short imperative subject, one bullet per changed file in the body, and a `BREAKING CHANGE` footer if needed
3. Shows you the message and asks to approve or revise. Pick a revision hint (more explicit, less vague, fix linting, etc.) or just describe what you want — it rewrites and comes back
4. Asks whether to run `git commit` for you. Say no and it stops; you keep the message and commit manually
5. On commit, appends a numbered entry (`## [N] — summary`) to `CHANGELOG.md` with the date and the files touched — one number per commit, newest at the top
6. If workflows are enabled, offers to trigger a **Release** or **Deploy** after pushing (see [Releases & Deployments](#-releases--deployments))

### 🔢 Numbered changelog

Every entry gets a sequential number — `## [1]`, `## [2]`, … — one per commit, with the newest at the top carrying the highest number. A **release** stamps a `## vX.Y.Z — date` marker above the commits it shipped, so the changelog reads on two axes: per-commit numbers and per-release versions.

Bringing an older changelog up to this format? Run `/kermit --changelog-reset` — it numbers and normalises the existing entries in place (after a backup and a diff you approve).

### 🚀 Releases & Deployments

If you enable workflows during `--init`, kermit can drive two GitHub Actions workflows after a commit:

- **Release** (`.github/workflows/release.yml`) — bump the version, publish to npm with provenance, push the tag, and cut a GitHub Release whose notes are every changelog entry since the last release.
- **Deploy** (`.github/workflows/deploy.yml`) — put the current commit live in an environment (`staging` / `production`) using GitHub Environments. The deploy command comes from your repo: a `deploy:<env>` npm script, else a `DEPLOY_CMD` repo variable, else a safe no-op.

kermit doesn't deploy or publish itself — it dispatches the workflows via the GitHub CLI (`gh`). During `--init`, kermit can scaffold both workflow templates into a repo that doesn't have them yet (it never overwrites existing files).

### Changelog management

The first time you run `/kermit` in a repo, it checks `.claude/kermit/pref.json`. If the skill hasn't been set up yet, it walks you through changelog initialisation before doing anything else.

You get two options:

- **Create a new changelog** — kermit creates `CHANGELOG.md` for you. If the repo already has commits, it asks whether to backfill them as a `## History` section (one `- date — subject` line per commit) or leave the slate clean.
- **I already have a changelog** — kermit scans the repo for an existing changelog file. If it finds one, it uses it. If it can't find anything, it asks whether to create one or let you provide the path.

The result is stored in `.claude/kermit/pref.json` so the setup prompt never appears again.

## Requirements

- Git
- (Optional) [rtk](https://github.com/rtk-ai/rtk) for token-optimized git commands. Saves lots of tokens.