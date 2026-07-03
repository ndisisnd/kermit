#!/usr/bin/env bash
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/ndisisnd/kermit/main"
SKILL_DIR="${HOME}/.claude/skills/kermit"
REFS=("commit-protocol.md" "changelog-protocol.md")

# Resolve a local checkout dir if this script was run from one (git clone + ./install.sh).
# When piped through `curl ... | bash` there is no local file, so we download instead.
SCRIPT_DIR=""
if [ "${BASH_SOURCE[0]:-bash}" != "bash" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# fetch <repo-relative-path> <dest> — copy from the local checkout if present, else download.
fetch() {
  if [ -n "${SCRIPT_DIR}" ] && [ -f "${SCRIPT_DIR}/$1" ]; then
    cp "${SCRIPT_DIR}/$1" "$2"
  else
    curl -fsSL "${REPO_RAW}/$1" -o "$2"
  fi
}

echo "Installing kermit → ${SKILL_DIR}"

mkdir -p "${SKILL_DIR}/refs"

fetch "SKILL.md" "${SKILL_DIR}/SKILL.md"
for r in "${REFS[@]}"; do
  fetch "refs/${r}" "${SKILL_DIR}/refs/${r}"
done
# pref.json is a template and optional — skip silently if it can't be fetched.
fetch "pref.json" "${SKILL_DIR}/pref.json" 2>/dev/null || true

echo "Done. Installed → ${SKILL_DIR}"
echo
echo "kermit formats and runs git commits using Conventional Commits — emoji prefix,"
echo "point-form file bodies, BREAKING CHANGE footer — and keeps CHANGELOG.md in sync."
echo
echo "→ Run \"/kermit --init\" in any local repo to initialise its preferences."
echo "→ Tailor kermit to your needs by editing ${SKILL_DIR}/SKILL.md."
echo
printf '\033[35mThank you JC \342\235\244\357\270\217\033[0m\n'
