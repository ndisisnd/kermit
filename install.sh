#!/usr/bin/env bash
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/ndisisnd/kermit/main"
# Claude Code reads user-level skills from ~/.claude/skills/.
CLAUDE_SKILL_DIR="${HOME}/.claude/skills/kermit"
# Codex reads user-level skills from $HOME/.agents/skills/ (the USER scope in
# OpenAI's skill-discovery order: SYSTEM → ADMIN → USER → REPO). Verified against
# the Codex skills docs at implementation time; older third-party guides still
# quote ~/.codex/skills, which is the deprecated path.
CODEX_SKILL_DIR="${HOME}/.agents/skills/kermit"
# The skill body lives under skills/kermit/ in the repo so packagers ship only it,
# not the whole repo. Everything below is fetched relative to this prefix.
SKILL_SRC="skills/kermit"
# Every top-level ref SKILL.md loads. Keep in sync with the repo's skills/kermit/refs/
# dir — a curl-piped install can't list the repo, so a missing entry ships a broken skill.
# The same rule applies to AGENTS_FILES below and the repo's skills/kermit/agents/ dir.
REFS=("protocol-init.md" "protocol-commit.md" "protocol-pr.md" "protocol-release.md" "protocol-changelog-sync.md" "protocol-subagent.md" "template-release.md" "changelog-protocol.md" "changelog-reset.md")
HOOKS=("kermit-merge-guard.sh")              # shell hooks under hooks/
AGENTS_FILES=("openai.yaml" "kermit-agent.toml")   # Codex adapter files under agents/

# Which harness(es) to install for. --claude stays the default so existing
# curl-pipe lines keep behaving exactly as before.
INSTALL_CLAUDE=1
INSTALL_CODEX=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --claude) INSTALL_CLAUDE=1; INSTALL_CODEX=0 ;;
    --codex)  INSTALL_CLAUDE=0; INSTALL_CODEX=1 ;;
    --all)    INSTALL_CLAUDE=1; INSTALL_CODEX=1 ;;
    -h|--help)
      echo "Usage: install.sh [--claude | --codex | --all]"
      echo "  --claude  install for Claude Code at ${CLAUDE_SKILL_DIR} (default)"
      echo "  --codex   install for OpenAI Codex at ${CODEX_SKILL_DIR}"
      echo "  --all     install for both"
      exit 0
      ;;
    *) echo "Unknown option: $1 (try --help)" >&2; exit 1 ;;
  esac
  shift
done

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

# install_body <dest-dir> — lay down one copy of the skill. The body is identical on
# both harnesses; only the destination and the closing message differ.
install_body() {
  local dest="$1"
  echo "Installing kermit → ${dest}"

  # Wipe any previous install so files retired or renamed in an upgrade don't linger
  # (e.g. an old ref, a template dropped from a later version). The skill dir holds only
  # shipped files — the per-repo runtime lives in each project's kermit dir — so a
  # full wipe is safe and guarantees the install matches this version exactly.
  rm -rf "${dest}"
  mkdir -p "${dest}/refs"

  fetch "${SKILL_SRC}/SKILL.md" "${dest}/SKILL.md"
  for r in "${REFS[@]}"; do
    fetch "${SKILL_SRC}/refs/${r}" "${dest}/refs/${r}"
  done
  # Hooks (e.g. the merge-to-main guard) live in hooks/ and must stay executable.
  mkdir -p "${dest}/hooks"
  for h in "${HOOKS[@]}"; do
    fetch "${SKILL_SRC}/hooks/${h}" "${dest}/hooks/${h}"
    chmod +x "${dest}/hooks/${h}" 2>/dev/null || true
  done
  # Codex adapter files: the skill declaration Codex reads, and the ready-to-copy
  # subagent role. Shipped on both harnesses so one install can serve either.
  mkdir -p "${dest}/agents"
  for a in "${AGENTS_FILES[@]}"; do
    fetch "${SKILL_SRC}/agents/${a}" "${dest}/agents/${a}"
  done
  # pref.json (config) and state.json (volatile runtime state) are templates and
  # optional — skip silently if either can't be fetched.
  fetch "${SKILL_SRC}/pref.json" "${dest}/pref.json" 2>/dev/null || true
  fetch "${SKILL_SRC}/state.json" "${dest}/state.json" 2>/dev/null || true

  echo "Done. Installed → ${dest}"
}

if [ "${INSTALL_CLAUDE}" -eq 1 ]; then
  install_body "${CLAUDE_SKILL_DIR}"
fi
if [ "${INSTALL_CODEX}" -eq 1 ]; then
  install_body "${CODEX_SKILL_DIR}"
fi

echo
echo "kermit formats and runs git commits using Conventional Commits — emoji prefix,"
echo "point-form file bodies, BREAKING CHANGE footer — and keeps CHANGELOG.md in sync."
echo

if [ "${INSTALL_CLAUDE}" -eq 1 ]; then
  echo "Claude Code"
  echo "→ Run \"/kermit --init\" in any local repo to initialise its preferences."
  echo "→ Tailor kermit to your needs by editing ${CLAUDE_SKILL_DIR}/SKILL.md."
  echo
fi

if [ "${INSTALL_CODEX}" -eq 1 ]; then
  echo "Codex"
  echo "→ Run \"/kermit --init\" in any local repo to initialise its preferences."
  echo "→ Tailor kermit to your needs by editing ${CODEX_SKILL_DIR}/SKILL.md."
  echo "→ Copy ${CODEX_SKILL_DIR}/agents/kermit-agent.toml to .codex/agents/kermit.toml in a repo to make kermit spawnable as a subagent."
  echo
  echo "Add these two lines to your repo's AGENTS.md so Codex routes commits through kermit:"
  echo
  echo "  After completing a change, delegate the commit to the kermit skill / kermit subagent rather than committing ad hoc."
  echo "  Before merging or pushing to main/master, run \`/kermit --release\` (or spawn the kermit subagent in release mode) so the release ships user-facing notes."
  echo
fi

printf '\033[35mThank you JC \342\235\244\357\270\217\033[0m\n'
