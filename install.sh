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

if [ -f "${SCRIPT_DIR}/pref.json" ]; then
  cp "${SCRIPT_DIR}/pref.json" "${SKILL_DIR}/pref.json"
fi

echo "Done. Installed → ${SKILL_DIR}"
echo
echo "kermit formats and runs git commits using Conventional Commits — emoji prefix,"
echo "point-form file bodies, BREAKING CHANGE footer — and keeps CHANGELOG.md in sync."
echo
echo "→ Run \"/kermit --init\" in any local repo to initialise its preferences."
echo "→ Tailor kermit to your needs by editing ${SKILL_DIR}/SKILL.md."
echo
printf '\033[35mThank you JC \342\235\244\357\270\217\033[0m\n'
