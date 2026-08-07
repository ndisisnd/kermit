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

kermit is an agent skill for Claude Code and OpenAI Codex: a set of markdown protocol
files, a shell installer, and a
git hook. It runs entirely on your machine, inside the repo you point it at. It reads your
staged diff, writes `CHANGELOG.md` and `RELEASES.md`, and runs `git` and `gh` commands on
your behalf. It has no server, no network listener, and no credentials of its own — when
it talks to GitHub it borrows the `gh` CLI auth you already set up.

The realistic surface is therefore three things: the curl-piped installer
(`install.sh`) and what it writes into `~/.claude/skills/kermit` or `~/.agents/skills/kermit`,
the merge-guard hook it can install into your repo, and the shell commands the protocols
instruct an agent to run. Anything that could turn one of those into arbitrary code
execution, or make kermit write outside the repo it was invoked in, is in scope.

## Non-interactive runs auto-approve kermit's own gates

When kermit detects that no human is attached — a Codex subagent, a `codex exec` task, or
a headless Claude run with `claude -p` — it resolves every one of its gates to the
automatic answer: approve the message, make the commit, push the branch, publish the
release. This is deliberate, not an oversight. A non-interactive harness errors out the
moment something waits for an approval, so a gate that stops to ask would simply break the
run rather than protect anyone. Runs in this mode say so, reporting
`gates: auto (non-interactive)` in their closing `kermit-result` block, so an orchestrator
can see that nothing was human-reviewed. Interactive sessions are unaffected — your
`gate_mode` governs them exactly as before.

Treat kermit's gates as a workflow convenience, then, not as a security boundary. The
containment for an unattended worker comes from the harness sandbox around it: run the
worker workspace-write so it can only touch the repo it was given, and leave network
access off unless you actually want it to push, open a PR, or publish a release. A worker
with no network still commits and writes the changelog, and reports `pushed: failed` with
the command to push yourself. Scope what the worker *can* do at the sandbox, and kermit's
gate behaviour stops mattering.

## Disclosure

Report privately, and please hold off on publishing until a fix is out. Fixed issues are
published as a GitHub advisory with credit to the reporter.
