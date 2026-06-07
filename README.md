# kermit

A Claude Code skill that formats and commits changes using [Conventional Commits](https://www.conventionalcommits.org/) with emoji prefixes and manages `CHANGELOG.md` automatically via hooks.

## Installation

**macOS / Linux**

```bash
git clone https://github.com/andychan/kermit.git
cd kermit
chmod +x install.sh
./install.sh
```

**Windows (PowerShell)**

```powershell
git clone https://github.com/andychan/kermit.git
cd kermit
.\install.ps1
```

The installer copies `SKILL.md` and `refs/` into `~/.claude/skills/kermit/`.

## Usage

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

## What it does

1. Reads the staged diff (`git diff --staged`)
2. Proposes a commit message — subject line with emoji + type, file-by-file body
3. Asks for approval or revision
4. Runs `git commit` on confirmation
5. Appends an entry to `CHANGELOG.md`
6. Optionally pushes to remote

## Requirements

- [Claude Code](https://claude.ai/code) CLI
- Git
- (Optional) [rtk](https://github.com/andychan/rtk) for token-optimized git commands
