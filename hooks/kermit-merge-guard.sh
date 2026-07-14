#!/usr/bin/env bash
# kermit merge-guard — PreToolUse (Bash) hook.
#
# When a Bash command is about to land changes on main/master — a formal release —
# inject a non-blocking reminder telling kermit to ask the user whether to write
# release notes (/kermit --release) and to warn them if they decline. Never blocks
# the command; always exits 0.
#
# Wire into a project's .claude/settings.json as a PreToolUse hook with matcher "Bash":
#   { "type": "command", "command": "$HOME/.claude/skills/kermit/hooks/kermit-merge-guard.sh" }

input="$(cat)"

# Extract tool_input.command from the hook JSON. python3 is reliable on macOS/Linux;
# if it's missing or the JSON is unparseable, degrade to a silent no-op.
cmd="$(printf '%s' "$input" | python3 -c 'import sys,json
try:
    print(json.load(sys.stdin).get("tool_input",{}).get("command",""))
except Exception:
    pass' 2>/dev/null)"
[ -z "$cmd" ] && exit 0

branch="$(git branch --show-current 2>/dev/null || echo)"

is_release=0
case "$cmd" in
  *"gh pr merge"*) is_release=1 ;;                       # PR merges target the base branch
esac
# A merge while sitting on main/master.
if printf '%s' "$cmd" | grep -Eq '(^|[^[:alnum:]])git[[:space:]]+merge([^[:alnum:]]|$)'; then
  case "$branch" in main|master) is_release=1 ;; esac
fi
# A push carrying an explicit :main/:master refspec, or a push while on main/master.
if printf '%s' "$cmd" | grep -Eq '(^|[^[:alnum:]])git[[:space:]]+push'; then
  if printf '%s' "$cmd" | grep -Eq ':[[:space:]]*(main|master)([^[:alnum:]]|$)'; then
    is_release=1
  else
    case "$branch" in main|master) is_release=1 ;; esac
  fi
fi

[ "$is_release" = 1 ] || exit 0

# Best-effort throttle: fire at most once per ~2 minutes per working tree, so a
# retried command doesn't spam the reminder.
key="$(printf '%s' "$PWD" | tr -c 'A-Za-z0-9' '_' )"
marker="${TMPDIR:-/tmp}/kermit_merge_guard_${key}"
if [ -f "$marker" ]; then
  now="$(date +%s)"; then_ts="$(cat "$marker" 2>/dev/null || echo 0)"
  [ $((now - then_ts)) -lt 120 ] && exit 0
fi
date +%s > "$marker" 2>/dev/null || true

cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"⚠️ kermit merge-guard: this command lands changes on main — a formal release. Before it completes, ask the user whether they also want to run `/kermit --release` to write user-facing release notes for RELEASES.md. If they decline, warn them the release will ship without release notes and users won't see what changed."}}
JSON
exit 0
