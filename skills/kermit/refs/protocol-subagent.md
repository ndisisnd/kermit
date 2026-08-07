# Subagent worker contract

How an orchestrator drives kermit as a non-interactive worker (Codex `spawn_agent` /
`codex exec`, or headless Claude `claude -p`). Read this when you are *spawning* kermit,
or when you *are* the spawned worker and want the contract you are held to.

## What the orchestrator must hand over

| Mode | Repo precondition | Sandbox | Network |
|------|-------------------|---------|---------|
| commit (default) | changes **staged** (`git add` already run) | workspace-write | only if you want the push |
| `--pr` | commits already on the branch | workspace-write | **required** (`gh`) |
| `--release` | commits already on the branch | workspace-write | required to publish |
| `--changelog-sync` | commits already in history | workspace-write | not needed |

kermit never stages for you. An empty `git diff --staged` in commit mode means there is
nothing to do. Pass the mode in the task prompt (`--pr`, `--release`, `--changelog-sync`,
or nothing for commit).

## What comes back

One fenced `kermit-result` block (defined in SKILL.md), always last, always present —
including on handled failures. Parse it; do not parse the prose above it.

```kermit-result
mode: commit
head: 9f1c2ab…
changelog_entry: 12
pushed: yes
published: n/a
gates: auto (non-interactive)
```

`gates: auto (non-interactive)` is the tell that **nothing was human-reviewed** — the worker
resolved every gate to its default. Treat the commit as machine-approved.

## Handled outcomes (not errors)

All three terminate **successfully**. None should be retried blindly.

- **`pushed: failed`** — commit and changelog entry landed; the push did not (no network, or
  no credentials in the sandbox). Remediation: push it yourself, or re-spawn with network.
- **`published: no`** — release notes were written and committed; the GitHub release was not
  published. Remediation: run `gh release create` yourself, or re-spawn with network.
- **Bootstrap note** (`initialized by non-interactive bootstrap …` in the run output) — the
  repo had no kermit pref, so the worker wrote the defaults (`CHANGELOG.md` at root,
  `gate_mode: flash`) and continued. The run is valid; run `/kermit --init` interactively
  if you want different conventions.

## AGENTS.md snippet for Codex repos

Add these two lines to the repo's `AGENTS.md` so any Codex session finds kermit and honours
the release guard:

```
- After completing a change, delegate the commit to the kermit skill / kermit subagent
  rather than committing ad hoc.
- Before merging or pushing to main/master, run `/kermit --release` (or spawn the kermit
  subagent in release mode) so the release ships user-facing notes.
```
