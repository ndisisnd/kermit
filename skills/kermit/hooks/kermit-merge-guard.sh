#!/usr/bin/env bash
# kermit merge-guard — PreToolUse (Bash) hook.
#
# Fires ONLY when a branch is being MERGED into a protected branch
# (main / master / production) — a formal release. It injects a non-blocking
# reminder telling kermit to ask the user whether to write release notes
# (/kermit --release) and to warn them if they decline. Never blocks the
# command; always exits 0.
#
# What counts as a merge into a protected branch:
#   - `git merge …`      while checked out on main / master / production
#   - `gh pr merge …`    (a PR merge lands a branch onto its base)
#   - `git push … <src>:<dst>` where <dst> is main / master / production
# A plain `git push` does NOT fire — release notes for anything else are
# opt-in via an explicit `/kermit --release`.
#
# Detection parses the command properly (quotes stripped, split on shell
# operators, per-segment token scan) so trigger words buried in a commit
# message or other quoted text never cause a false positive. A wrapper such
# as `rtk`/`sudo`/`ENV=x` before `git`/`gh` is tolerated.
#
# Wire into a project's .claude/settings.json as a PreToolUse hook with matcher "Bash":
#   { "type": "command", "command": "$HOME/.claude/skills/kermit/hooks/kermit-merge-guard.sh" }

input="$(cat)"
branch="$(git branch --show-current 2>/dev/null || echo)"

# Decide via python3. The script runs as a heredoc (NOT inside $(), which the
# macOS bash 3.2 parser mishandles when the body contains quotes) and signals
# its verdict through the EXIT CODE: 0 = fire, non-zero = do not fire. Input and
# branch arrive via env so the heredoc doesn't collide with the hook JSON on
# stdin. Any python error → non-zero → silently does not fire.
HOOK_INPUT="$input" HOOK_BRANCH="$branch" python3 <<'PY' 2>/dev/null
import os, json, re, shlex

PROTECTED = {"main", "master", "production"}

try:
    cmd = json.loads(os.environ.get("HOOK_INPUT", "")).get("tool_input", {}).get("command", "") or ""
except Exception:
    cmd = ""
branch = os.environ.get("HOOK_BRANCH", "").strip()
if not cmd:
    raise SystemExit(1)

def tokens(seg):
    # shlex keeps a quoted string as ONE token, so a commit message that
    # mentions "git push … :main" cannot leak standalone git/gh/:main tokens.
    try:
        return shlex.split(seg)
    except ValueError:
        return seg.replace('"', ' ').replace("'", ' ').split()

def dst_is_protected(arg):
    # a push refspec src:dst (or :dst) lands on dst; take the branch basename
    return ":" in arg and arg.split(":")[-1].split("/")[-1] in PROTECTED

def is_trigger(seg):
    t = tokens(seg)
    n = len(t)
    for i, tok in enumerate(t):
        if tok == "gh":
            rest = [x for x in t[i + 1:] if not x.startswith("-")]
            if rest[:2] == ["pr", "merge"]:
                return True
        if tok == "git":
            j = i + 1
            while j < n and t[j].startswith("-"):
                j += 2 if t[j] in ("-C", "-c") else 1
            if j >= n:
                continue
            sub = t[j]
            if sub == "merge" and branch in PROTECTED:
                return True
            if sub == "push" and any(dst_is_protected(a) for a in t[j + 1:]):
                return True
    return False

# Split into sub-commands on shell control operators, then judge each on its own.
segments = re.split(r"&&|\|\||;|\||\n", cmd)
raise SystemExit(0 if any(is_trigger(s) for s in segments) else 1)
PY
[ $? -eq 0 ] || exit 0

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
