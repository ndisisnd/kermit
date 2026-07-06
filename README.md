<div align="center">

# ✍🏻 kermit

### Commit good code, but what about good committing?

<sub>Lightwight opinionated conventional commit style with emoji prefixes, in-built changelog, deployment, release management, and breaking change emission. </sub>

<br />

<img width="360" src="./asset/readme.jpg">

<br />

**One command. Intelligent, automated committing.** One-time setup for you to automate commit messages.

</div>

## ⬇️ Get started in 30 seconds

### 1. Install the script
The script installs the `kermit` skill and its' relevant references.
**On a macOS / Linux?** Paste this in your terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/ndisisnd/kermit/main/install.sh | bash
```

**On Windows?** Paste this in your shell:

```powershell
irm https://raw.githubusercontent.com/ndisisnd/kermit/main/install.ps1 | iex
```

### 2. Initialise kermit
`kermit` can be used immediately, but initialising it would make the experience more seamless and personalised to your codebase + repository. Paste ```bash /kermit --init``` in your terminal. Initialising will run a step-by-step protocol that basically:

1. Determines how you want to manage your changelog, personalised to your style
2. Determines how you want to gate your commits (e.g. auto-commit, auto-approve, or even commit to push immediately)
3. Sets up Github Workflows
4. Saves all your preferences in a JSON file that's used by future `/kermit` runs

_If you already have a changelog, `kermit` will ask you to point to the relative path._

## ❓ How does it work?

1. The skill will reads your staged diff. If you didn't stage anything, your LLM might tell you to stage your changes first
2. Writes a commit message based on the inbuilt protocols
3. Goes through the gate mode that you've selected

## ✌🏻 Who is this for?
- You **don't like spending time** thinking about how to write commit messages
- Your **commit messages would be challenging to write** because of huge code changes
- You want to make sure **commit messages** are always accurate and representative

## ⚒️ How does `kermit` fit into your harness or workflow?
- You can ask Claude / Codex / Cursor / LLM of your choice to write `kermit` as a hook or automate it when an agent is done coding
- Use `kermit`'s changelog as a way to debug and provide context for agents

`kermit` isn't a competitor to other commit messaging skills: it preserves maximum context with minimal token usage for codebase health.

## 🌟 How to use

In any session when you want to commit, just run `/kermit` in the terminal. You can also say it in natural language like _make a commit, commit changes, commt this_ and it'll work.

### Flags

| Flag | What it does |
|------|--------------|
| `--init` | Re-run the full setup (changelog + automation + workflow prefs), then exit |
| `--changelog-reset [--apply]` | Rewrite an existing changelog to the latest conventions — adds `## [N]` numbering and normalises headings/dates/bullets. Backs up to `CHANGELOG.md.bak`, shows a diff, and asks before writing (`--apply` skips the confirm), then exits |
| `--release` | After committing, dispatch the **Release** workflow (version bump → npm publish → tag → GitHub Release) via `gh` |
| `--deploy` | After committing, dispatch the **Deploy** workflow (put the commit live in a chosen environment) via `gh` |

### Changelog numbering

Every entry gets a sequential number — `## [1]`, `## [2]`, … — one per commit, with the newest at the top carrying the highest number. A **release** stamps a `## vX.Y.Z — date` marker above the commits it shipped, so the changelog reads on two axes: per-commit numbers and per-release versions.

Bringing an older changelog up to this format? Run `/kermit --changelog-reset` — it numbers and normalises the existing entries in place (after a backup and a diff you approve).

### Releases & Deployments

If you enable workflows during `--init`, kermit can drive two GitHub Actions workflows after a commit:

- **Release** (`.github/workflows/release.yml`) — bump the version, publish to npm with provenance, push the tag, and cut a GitHub Release whose notes are every changelog entry since the last release.
- **Deploy** (`.github/workflows/deploy.yml`) — put the current commit live in an environment (`staging` / `production`) using GitHub Environments. The deploy command comes from your repo: a `deploy:<env>` npm script, else a `DEPLOY_CMD` repo variable, else a safe no-op.

kermit doesn't deploy or publish itself — it dispatches the workflows via the GitHub CLI (`gh`). During `--init`, kermit can scaffold both workflow templates into a repo that doesn't have them yet (it never overwrites existing files).

## License

[MIT](https://github.com/ndisisnd/kermit?tab=MIT-1-ov-file)

## Acknowledgements

- [rtk](https://github.com/rtk-ai/rtk) for token-optimized git commands. Saves lots of tokens
- [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) for the open-sourced scaffold of commit messages