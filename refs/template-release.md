# Release notes template — reference

The shape every release section in `RELEASES.md` follows. `RELEASES.md` is the **user-facing**
release-notes page — newest release on top, one section per release. It is a different file
from `CHANGELOG.md` (which is the per-commit technical log): release notes speak to the people
*using* the software, not to the people building it.

## Rules

- **Highlight is mandatory; every other section is conditional.** Emit a `###` section only
  when it has at least one entry — never leave an empty heading.
- **Fixed section order** so releases read consistently: `✨ New` → `📈 Improved` → `🐛 Fixed`
  → `🔒 Security` → `⚠️ Breaking` → `🗑️ Deprecated`. (If a release is dominated by breaking
  changes, still keep the order, but let the Highlight lead with the breaking change.)
- **Write for the user, not the diff.** Say what a person can now do, no longer needs to do,
  or must do differently — and *why the change was made*. Never name files, functions, or
  internal machinery, and avoid words like "refactor", "wire up", or "endpoint".
- **Plain, conversational English.** Prefer the second person: "You can now…", "You no longer
  need to…". One idea per bullet.
- **Fold invisible churn.** Changes with no user-visible effect become at most one line under
  Improved ("Various under-the-hood improvements to speed and reliability."), or are dropped.

## Labels

| Section | Use for |
|---------|---------|
| ✨ New | Capabilities the user didn't have before |
| 📈 Improved | Existing things that got better, faster, or clearer |
| 🐛 Fixed | Things that were broken and now work |
| 🔒 Security | Hardening or patches — describe the risk closed, in plain terms |
| ⚠️ Breaking | Changes that require the user to act — say exactly what to do |
| 🗑️ Deprecated | Still works, but going away — say by when |

## Template

```markdown
## <version> — <YYYY-MM-DD>

> <Highlight: 1–3 sentences, plain language — the headline of this release and what it means
> for the people using it. Lead with the single most impactful change.>

### ✨ New
- <A capability the user now has. Say what they can do and why it exists.>

### 📈 Improved
- <Something that got better. Name the benefit, not the mechanism.>

### 🐛 Fixed
- <Something that was broken and now works. Frame it from the user's experience.>

### 🔒 Security
- <A hardening or patch, in plain terms — what risk it closes for the user.>

### ⚠️ Breaking
- <What changed that needs the user to act, and exactly what to do about it.>

### 🗑️ Deprecated
- <What still works but is going away, and by when.>
```

## Exemplar

```markdown
## v2.0.0 — 2026-07-14

> Kermit now opens pull requests for you and keeps every change individually addressable in
> the changelog. Setup is a single command, and reruns never leave a mess behind.

### ✨ New
- Open or update a GitHub pull request without leaving kermit — it writes the title and a
  structured summary for you, so raising a PR is one step instead of a context switch.
- Write user-facing release notes with one command, so the people using your software can
  see what changed for them without reading the commit log.

### 📈 Improved
- Every changelog entry now carries its own number, so you can point a teammate at "[24]"
  instead of a date and a guess.
- Installing takes one line — no cloning required.

### 🐛 Fixed
- The install command no longer fails on a bad link, so setup works the first time.
```
