<div align="center">

# ✍🏻 kermit

### Commit good code, but what about good committing?

<sub>Lightwight opinionated conventional commit style with emoji prefixes, in-built changelog, pull requests, release notes, and breaking change emission. </sub>

<br />

<img width="240" src="./asset/readme.jpg">

<br />
<br />

<img width="480" src="./asset/kermit_demo_1.gif">

<br />

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
2. Sets up your release notes (`RELEASES.md`) and, optionally, the merge-to-main guard
3. Determines how you want to gate your commits (e.g. auto-commit, auto-approve, or even commit to push immediately)
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

The same goes for pull requests — run `/kermit --pr`, or just say _open a PR_, _raise a pull request to `develop`_, and kermit routes to PR mode automatically (naming a base branch sets the PR base).

### Flags

| Flag | What it does |
|------|--------------|
| `--changelog-reset [--apply]` | Rewrite an existing changelog to the latest conventions — adds `## [N]` numbering and normalises headings/dates/bullets. Backs up to `CHANGELOG.md.bak`, shows a diff, and asks before writing (`--apply` skips the confirm), then exits |
| `--init` | Re-run the full setup (changelog + release notes + commit gating), then exit |
| `--pr` | Open — or update — a GitHub pull request for the current branch via `gh`. Operates on commits already on the branch (it doesn't create a commit), writes a Conventional-Commits title and a structured body, and shows the PR URL |
| `--release` | Write user-facing **release notes** to `RELEASES.md` for everything since the last release — grouped by type, in plain language. Operates on committed history; doesn't create a commit |

### Changelog numbering

Every entry gets a sequential number — `## [1]`, `## [2]`, … — one per commit, with the newest at the top carrying the highest number. A **release** stamps a `## vX.Y.Z — date` marker above the commits it shipped, so the changelog reads on two axes: per-commit numbers and per-release versions.

Bringing an older changelog up to this format? Run `/kermit --changelog-reset` — it numbers and normalises the existing entries in place (after a backup and a diff you approve).

### Pull requests

`/kermit --pr` opens or updates a GitHub pull request for whatever branch you're on. It works on the commits already on the branch — it doesn't make a commit, so run `/kermit` first if you have uncommitted work. kermit reads the branch state, pushes the branch if needed, and writes:

- a **title** in Conventional Commits style that summarises the branch's overall intent, and
- a **body** with `## Summary`, `## Why this is being made`, `## Specific changes` (one bullet per distinct change, keyed by module/file), and an optional `## Additional information`.

It defaults the base to your repo's default branch, or the one you name (_"open a PR to `develop`"_). If a PR already exists for the branch, kermit edits it in place instead of opening a duplicate. Approval follows the same gate mode you set during `--init`. Requires the GitHub CLI, authenticated (`gh auth login`).

### Release notes

`CHANGELOG.md` is written for the people building the software — one numbered entry per commit, with the files that changed. **Release notes** are written for the people _using_ it. Run `/kermit --release` (or say _"cut a release"_, _"write release notes"_) and kermit reads every change since your last release and rewrites it into `RELEASES.md`: a highlight summary up top, then changes grouped by type — **✨ New**, **📈 Improved**, **🐛 Fixed**, **🔒 Security**, **⚠️ Breaking**, **🗑️ Deprecated**.

The notes focus on you, not the diff — what you can now do, what changed for you, and why — in plain language, no file names or jargon. It's the same spirit as the [Linear](https://linear.app/changelog) and [Notion](https://www.notion.com/releases) changelogs. `--init` scaffolds `RELEASES.md` for you (and can draft an inaugural note from your history), and approval follows the gate mode you set during setup.

**Automatic prompt on merge to main.** A release is a formal moment — usually a branch landing on `main`. If you enable the **merge-to-main guard** during `--init`, kermit watches for a merge or push to `main` and reminds you to write release notes first, warning you if you skip them (so a release never ships silently). The guard is a local hook — it prompts, it never blocks your merge.

## License

[MIT](https://github.com/ndisisnd/kermit?tab=MIT-1-ov-file)

## Acknowledgements

- [rtk](https://github.com/rtk-ai/rtk) for token-optimized git commands. Saves lots of tokens
- [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) for the open-sourced scaffold of commit messages