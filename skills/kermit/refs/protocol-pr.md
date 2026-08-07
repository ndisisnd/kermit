# PR protocol

Open — or update — a GitHub pull request for the current branch. Reached via `--pr`.
This mode does **not** produce a commit; it operates on commits that already exist on
the branch. Run the default commit flow first if you have uncommitted work.

**General rule:** batch independent commands into one Bash call (step 1 does this for the rtk check + branch state). `$KERMIT_DIR/pref.json` is read once at mode-check (SKILL.md) — cache `gate_mode`/`pr.*` for the run; don't re-read it. `GATE(...)`, `HARNESS`, `KERMIT_DIR`, `INTERACTIVE` and the closing `kermit-result` block are defined in SKILL.md.

## Gate resolution (runs once, before step 1)

Reuse the same `gate_mode` table as the commit protocol. In PR mode the resolved values map as:

| `gate_mode` | `auto_approve` (title/body) | `auto_create` (open/update the PR) | `push_enabled` (auto-push the branch) |
|-------------|-----------------------------|------------------------------------|----------------------------------------|
| `full` | false | false | true |
| `auto` | false | true | true |
| `flash` | true | true | true |
| `commit-only` | true | true | **false** |

`auto_create` reuses the `auto_commit` column; `auto_approve` and `push_enabled` are as in
the commit table. **Legacy fallback:** if `gate_mode` is absent, use the individual
`auto_approve` / `auto_commit` booleans (treat `auto_commit` as `auto_create`) and
`push_enabled` as `true`.

Opening a PR is inherently a remote action. When `push_enabled` is `false` (`commit-only`),
do **not** auto-push in step 2 — ask before pushing, and skip PR creation if the user declines.

**Non-interactive override:** if `INTERACTIVE=false`, force `auto_approve` and `auto_create` to
`true` regardless of `gate_mode`, and report `gates: auto (non-interactive)`.

---
1. Detect rtk **and** gather branch state in a single Bash call:
   ```
   which rtk >/dev/null 2>&1 && RTK=rtk || RTK=
   echo "(1) Reading branch state..."
   BR=$($RTK git rev-parse --abbrev-ref HEAD)
   BASE=$($RTK gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null || echo main)
   gh auth status >/dev/null 2>&1 && GH_OK=1 || GH_OK=0
   echo "branch=$BR base=$BASE gh=$GH_OK"
   [ "$GH_OK" = 1 ] && $RTK gh pr view --json url,number,state -q '"\(.number) \(.state) \(.url)"' 2>/dev/null
   $RTK git log --oneline "$BASE"..HEAD 2>/dev/null
   $RTK git status --short
   ```
   - If `GH_OK=0`: emit `💡 Install & auth the GitHub CLI to open PRs: gh auth login`, then **terminate**.
   - **Base override:** if the user named a base branch (e.g. "make a PR to `develop`"), use that as `$BASE` instead of the repo default.
   - If `$BR` equals `$BASE`: emit `Can't open a PR from the default branch (\`$BASE\`) onto itself — create a feature branch first (\`git switch -c <name>\`).`, then **terminate**.
   - If `git log $BASE..HEAD` is empty: emit `No commits ahead of \`$BASE\` — nothing to open a PR for.`, then **terminate**.
   - If `git status --short` shows uncommitted changes: emit `⚠️ You have uncommitted changes — they won't be in the PR. Run \`/kermit\` to commit them first if intended.` and continue with what's committed.
   - Note whether an existing PR was reported — call it `PR_EXISTS` (true/false) and remember its number/URL.

2. **Ensure the branch is on the remote.** If the branch has no upstream or has commits not yet pushed:
   - If `push_enabled` is `true`: run `$RTK git push -u origin "$BR"`.
   - If `push_enabled` is `false` (`commit-only`): `GATE(question: "Push \`<branch>\` to open the PR?", options: ["yes", "no"], default: "yes")`. On `no`: emit `Skipped — a PR needs the branch pushed. Re-run without commit-only, or push manually.` and **terminate**.
   - **Sandbox-tolerant push.** If the push fails for a network/auth reason (`could not resolve host`, `connection refused`, timeout), do **not** error the run: record `pushed: failed`, `published: no`, emit `Push blocked (no network in this sandbox) — push the branch yourself, then re-run \`/kermit --pr\`.`, close with the `kermit-result` block and **terminate successfully**.

3. Emit `(3) Writing PR...` Produce the title and body:
   - **Title**: Conventional Commits style — `<type>[(<scope>)][!]: <description>`, ≤72 chars, lowercase imperative description. An emoji prefix is optional here (match the commit style if the branch is single-purpose). Summarise the branch's overall intent, not any one commit.
   - **Body**, in this shape:
     ```
     ## Summary
     - <what this branch does, in one or two lines>

     ## Why this is being made
     - <the motivation / problem being solved>

     ## Specific changes
     - `<module / file>`: <the distinct change here — one bullet per distinct change, grouped by module, function, or file>

     ## Additional information
     - <anything else worth flagging: follow-ups, risks, test plan, screenshots — omit the section if there's nothing>
     ```
     Derive the sections from `git log $BASE..HEAD` (and the diff if needed). Under **Specific changes**, give one bullet per genuinely distinct change, keyed by the module/function/file it lives in — don't restate the same change twice. Keep it terse.
   - **Never add AI co-authorship or attribution trailers** (e.g. `Co-Authored-By: …`, `Generated with …`) to the title or body. Strip any that appear.

4. Emit `(4) Proposed PR:` showing the title and body in a code block. If the resolved
   `auto_approve` is `true`, skip the gate and proceed as approved. Otherwise
   `GATE(question: "Approve or revise?", options: ["approve", "revise"], default: "approve")`.
   On `revise`: `GATE(question: "What would you like to revise?", options: ["sharpen the summary", "expand the test plan", "fix the title", "other (I'll describe)"], default: "sharpen the summary")`.
   Incorporate the feedback, rewrite, and return to 4. (Unreachable non-interactively — the
   approve default short-circuits the loop.)

5. **Open or update the PR.** If `auto_create` is `false`, first
   `GATE(question: "(5) <Open|Update> the PR now?", options: ["yes", "no"], default: "yes")`.
   On `no`: emit the title/body so the user can open it manually, then terminate. Otherwise proceed:
   - If `PR_EXISTS` is `false` → `$RTK gh pr create --base "$BASE" --head "$BR" --title "<title>" --body "<body>"`.
   - If `PR_EXISTS` is `true` → `$RTK gh pr edit <number> --title "<title>" --body "<body>"` (updates the open PR in place).

   If the `gh` call fails for a network/auth reason, do **not** error the run: record
   `published: no`, emit `PR not opened (no network in this sandbox) — the branch is ready; run \`gh pr create\` yourself or re-run with network.`, close with `kermit-result` and terminate successfully.

6. Emit the PR URL: `$RTK gh pr view --json url -q .url`. Report whether it was created or updated.

7. **Close.** Emit the `kermit-result` block defined in SKILL.md — `mode: pr`, `head` = current HEAD SHA, `changelog_entry: null`, `pushed` = `yes`/`no`/`failed`, `published` = `yes` when the PR was created/updated, else `no`, `gates` = the resolved gate level.
