#!/usr/bin/env bash
# kermit merge-guard — PreToolUse (Bash) hook.
#
# Fires ONLY when a branch is being MERGED into a protected branch
# (main / master / production) — a formal release. It injects a non-blocking
# reminder telling kermit to ask the user whether to write release notes
# (/kermit --release) and to warn them if they decline. A plain `git push`
# (even from a protected branch) is NOT a merge and does not fire — release
# notes for anything else are opt-in via an explicit `/kermit --release`.
# Never blocks the command; always exits 0.
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

# Protected branches — a branch merging into one of these is a formal release.
is_release=0
# A PR merge lands a branch onto its base (a protected branch, in practice).
case "$cmd" in
  *"gh pr merge"*) is_release=1 ;;
esac
# A local `git merge` while sitting on a protected branch (main/master/production).
if printf '%s' "$cmd" | grep -Eq '(^|[^[:alnum:]])git[[:space:]]+merge([^[:alnum:]]|$)'; then
  case "$branch" in main|master|production) is_release=1 ;; esac
fi
# A push carrying an explicit refspec ONTO a protected branch (e.g. `feature:main`).
# A plain `git push` — even from a protected branch — is not a merge and does NOT fire.
if printf '%s' "$cmd" | grep -Eq '(^|[^[:alnum:]])git[[:space:]]+push'; then
  if printf '%s' "$cmd" | grep -Eq ':[[:space:]]*(main|master|production)([^[:alnum:]]|$)'; then
    is_release=1
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
{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"⚠️ kermit merge-guard: this merges a branch into a protected branch (main/master/production) — a formal release. Before it completes, ask the user whether they also want to run `/kermit --release` to write user-facing release notes for RELEASES.md. If they decline, warn them the release will ship without release notes and users won't see what changed."}}
JSON
exit 0
