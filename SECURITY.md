# Security policy

## Reporting a vulnerability

Please don't open a public issue for a security problem. Report it privately through
[GitHub's private vulnerability reporting](https://github.com/ndisisnd/kermit/security/advisories/new)
— it goes straight to the maintainer and stays closed until there's a fix.

Include what you can: what the issue is, how to reproduce it, and what an attacker could
do with it. A rough report is more useful than no report.

You'll get an acknowledgment as soon as a maintainer sees it. Once a fix ships, you'll be
credited in the advisory unless you'd rather not be.

## Supported versions

kermit is distributed from `main` — the install script pulls the skill and its refs
straight from that branch. Fixes land on `main`; there are no maintained release
branches. Use the latest commit.

## Scope

kermit is a Claude Code skill: a set of markdown protocol files, a shell installer, and a
git hook. It runs entirely on your machine, inside the repo you point it at. It reads your
staged diff, writes `CHANGELOG.md` and `RELEASES.md`, and runs `git` and `gh` commands on
your behalf. It has no server, no network listener, and no credentials of its own — when
it talks to GitHub it borrows the `gh` CLI auth you already set up.

The realistic surface is therefore three things: the curl-piped installer
(`install.sh` / `install.ps1`) and what it writes into `~/.claude/skills/kermit`, the
merge-guard hook it can install into your repo, and the shell commands the protocols
instruct an agent to run. Anything that could turn one of those into arbitrary code
execution, or make kermit write outside the repo it was invoked in, is in scope.

## Disclosure

Report privately, and please hold off on publishing until a fix is out. Fixed issues are
published as a GitHub advisory with credit to the reporter.
