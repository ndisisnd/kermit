#!/usr/bin/env bash
set -euo pipefail

SKILL_DIR="${HOME}/.claude/skills/kermit"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing kermit → ${SKILL_DIR}"

mkdir -p "${SKILL_DIR}"
cp "${SCRIPT_DIR}/SKILL.md" "${SKILL_DIR}/SKILL.md"

if [ -d "${SCRIPT_DIR}/refs" ]; then
  cp -r "${SCRIPT_DIR}/refs" "${SKILL_DIR}/refs"
fi

echo "Done. Use /kermit in any Claude Code session."
