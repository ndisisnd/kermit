# Release notes template — reference

The shape every release section in `RELEASES.md` follows. `RELEASES.md` is the **user-facing**
release-notes page — newest release on top, one section per release. It is a different file
from `CHANGELOG.md` (which is the per-commit technical log): release notes speak to the people
*using* the software, not to the people building it.

## Rules

- **Highlight is mandatory; every other section is conditional.** Emit a `###` section only
  when it has at least one entry — never leave an empty heading.
- **Fixed section order, Breaking first** so a user sees what they must act on before anything
  else: `⚠️ Breaking` → `✨ New` → `📈 Improved` → `🐛 Fixed` → `🔒 Security` → `🗑️ Deprecated`.
  If the release has a breaking change, the Highlight also leads with it.
- **Spacing.** One blank line after the `##` release heading, after the Highlight, after each
  `###` section heading, and between sections. No blank lines between bullets.
- **Short bullets.** One sentence per bullet, **20 words or fewer**. Lead with the change in a
  few words, then the user benefit in a short clause. No em-dash asides, no parenthetical
  lists, no second sentence. If a bullet needs a command or more detail, it belongs in the
  README or the changelog, not here.
- **Write for the user, not the diff.** Say what a person can now do, no longer needs to do,
  or must do differently — and *why*. Never name files, functions, or internal machinery, and
  avoid words like "refactor", "wire up", or "endpoint".
- **Plain, conversational English.** Prefer the second person: "You can now…", "You no longer
  need to…". One idea per bullet.
- **Fold invisible churn.** Changes with no user-visible effect become at most one line under
  Improved ("Under-the-hood speed and reliability fixes."), or are dropped.

## Labels

| Section | Use for |
|---------|---------|
| ⚠️ Breaking | Changes that require the user to act — say exactly what to do |
| ✨ New | Capabilities the user didn't have before |
| 📈 Improved | Existing things that got better, faster, or clearer |
| 🐛 Fixed | Things that were broken and now work |
| 🔒 Security | Hardening or patches — describe the risk closed, in plain terms |
| 🗑️ Deprecated | Still works, but going away — say by when |

## Template

```markdown
## <version> — <YYYY-MM-DD>

> <Highlight: 1–3 short sentences, plain language — the headline of this release. Lead with
> the breaking change if there is one, else the single most impactful change.>

### ⚠️ Breaking

- <What changed and exactly what to do — 20 words or fewer.>

### ✨ New

- <A capability the user now has, and why — 20 words or fewer.>

### 📈 Improved

- <Something that got better — the benefit, not the mechanism.>

### 🐛 Fixed

- <Something that was broken and now works, from the user's side.>

### 🔒 Security

- <The risk this closes, in plain terms.>

### 🗑️ Deprecated

- <What still works but is going away, and by when.>
```

## Exemplar

```markdown
## v2.0.0 — 2026-07-14

> Kermit now opens pull requests for you and numbers every changelog entry. Setup is a single
> command.

### ✨ New

- Open or update a pull request from kermit, with the title and summary written for you.
- Write user-facing release notes in one command, so users see what changed for them.

### 📈 Improved

- Each changelog entry has a number, so you can point a teammate at "[24]".
- Install in one line, with no cloning.

### 🐛 Fixed

- The install command no longer fails on a bad link.
```
