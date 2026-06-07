# Changelog

All notable changes to this project will be documented here.

## 2026-06-07

Added install scripts, a README, and a changelog protocol reference to make kermit distributable and self-documenting.

- Added: `install.sh` (macOS/Linux) and `install.ps1` (Windows) to copy skill files into `~/.claude/skills/kermit/`
- Added: `README.md` with full install, usage, and requirements docs
- Added: `refs/changelog-protocol.md` — changelog format spec with exemplars for the skill to reference at runtime
- Changed: SKILL.md adds a `refs` declaration, tightens commit format spec (type/scope/emoji, rtk fallback, BREAKING CHANGE footer)
