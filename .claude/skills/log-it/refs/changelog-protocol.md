# Changelog Protocol — Reference

Each changelog entry has exactly two parts:

1. **Summary line** — one sentence, present tense, describing the release as a whole (what changed and why it matters to the user)
2. **Change list** — bullet points covering only user-visible or operationally significant changes; omit internal refactors, typo fixes, and churn

## Entry format

```
## <YYYY-MM-DD>

<Summary line.>

- <change 1>
- <change 2>
- <change n>
```

### Change categories (use as inline labels when helpful)

| Label | Use for |
|-------|---------|
| Added | New features or capabilities |
| Changed | Modified behaviour or updated defaults |
| Fixed | Bug fixes |
| Removed | Deleted features or files |
| Security | Vulnerability patches |
| Deprecated | Still works but will be removed |

Labels are optional — include them when the category isn't obvious from the bullet text.

### Writing rules

- Summary: one sentence, no trailing details; lead with the headline impact
- Bullets: one line each; active voice; user-facing language (what the user gains, not what files changed)
- Omit changes that don't affect users: internal renames, comment edits, formatting passes
- Date format: ISO 8601 (`YYYY-MM-DD`); latest entry at the top of the file

---

## Exemplar 1 — Feature release

```markdown
## 2026-06-07

Added OAuth2 login via Google so users no longer need a separate password.

- Added: sign-in with Google on the login page
- Added: session token stored securely in an HTTP-only cookie
- Changed: `/login` redirects to the dashboard on success instead of showing a confirmation page
```

## Exemplar 2 — Bug fix + security patch

```markdown
## 2026-05-14

Fixed a crash on empty input and patched an XSS vulnerability in the search field.

- Fixed: parser no longer panics when given an empty string
- Security: search field now escapes HTML entities before rendering results
- Changed: error messages now include the offending line number for easier debugging
```
