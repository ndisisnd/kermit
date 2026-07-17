#!/usr/bin/env bash
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/ndisisnd/kermit/main"
SKILL_DIR="${HOME}/.claude/skills/kermit"
# The skill body lives under skills/kermit/ in the repo so packagers ship only it,
# not the whole repo. Everything below is fetched relative to this prefix.
SKILL_SRC="skills/kermit"
# Every top-level ref SKILL.md loads. Keep in sync with the repo's skills/kermit/refs/
# dir — a curl-piped install can't list the repo, so a missing entry ships a broken skill.
REFS=("protocol-init.md" "protocol-commit.md" "protocol-pr.md" "protocol-release.md" "protocol-changelog-sync.md" "template-release.md" "changelog-protocol.md" "changelog-reset.md")
HOOKS=("kermit-merge-guard.sh")              # shell hooks under hooks/

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

# Wipe any previous install so files retired or renamed in an upgrade don't linger
# (e.g. an old ref, a template dropped from a later version). The skill dir holds only
# shipped files — the per-repo runtime lives in each project's .claude/kermit/ — so a
# full wipe is safe and guarantees the install matches this version exactly.
rm -rf "${SKILL_DIR}"
mkdir -p "${SKILL_DIR}/refs"

fetch "${SKILL_SRC}/SKILL.md" "${SKILL_DIR}/SKILL.md"
for r in "${REFS[@]}"; do
  fetch "${SKILL_SRC}/refs/${r}" "${SKILL_DIR}/refs/${r}"
done
# Hooks (e.g. the merge-to-main guard) live in hooks/ and must stay executable.
mkdir -p "${SKILL_DIR}/hooks"
for h in "${HOOKS[@]}"; do
  fetch "${SKILL_SRC}/hooks/${h}" "${SKILL_DIR}/hooks/${h}"
  chmod +x "${SKILL_DIR}/hooks/${h}" 2>/dev/null || true
done
# pref.json (config) and state.json (volatile runtime state) are templates and
# optional — skip silently if either can't be fetched.
fetch "${SKILL_SRC}/pref.json" "${SKILL_DIR}/pref.json" 2>/dev/null || true
fetch "${SKILL_SRC}/state.json" "${SKILL_DIR}/state.json" 2>/dev/null || true

echo "Done. Installed → ${SKILL_DIR}"
echo
echo "kermit formats and runs git commits using Conventional Commits — emoji prefix,"
echo "point-form file bodies, BREAKING CHANGE footer — and keeps CHANGELOG.md in sync."
echo
echo "→ Run \"/kermit --init\" in any local repo to initialise its preferences."
echo "→ Tailor kermit to your needs by editing ${SKILL_DIR}/SKILL.md."
echo
printf '\033[35mThank you JC \342\235\244\357\270\217\033[0m\n'
