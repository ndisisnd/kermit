# Changelog Protocol — Reference

Each changelog entry (one per commit) has exactly three parts:

1. **Numbered summary heading** — a Markdown `##` heading of the form `## [N] — <summary>`, where `N` is the entry's sequence number (see **Numbering** below) and `<summary>` states the commit's product objective or goal: what the user can now do, or why the change matters to them. Frame it as an outcome, **not** a technical description of the implementation. Fall back to a technical description only when there is no clear product goal. The heading **must** surface any breaking change or large change — lead with it (e.g. `## [N] — BREAKING: …`).
2. **Date line** — the ISO 8601 date (`YYYY-MM-DD`) on its own line directly under the heading.
3. **Change list** — one bullet per touched file. Each bullet names the file and says what changed in it. A bullet may carry sub-points when a single file has multiple distinct changes.

## Numbering

Every entry carries a strictly increasing integer `N`, one per commit, newest entry at the top of the file with the highest `N`. Numbers never reset.

- Get the next number from `last_number + 1` in `.claude/kermit/state.json`.
- If state is unavailable, derive it from the file: the highest existing `## [k]` heading + 1 (ignore `## v…` version markers — they are not numbered).
- Starting value is `1` (so `last_number: 0` → first entry is `## [1]`).
- After writing, set `last_number` in `.claude/kermit/state.json` to the highest `N` written.

**Version markers.** A release inserts a `## v<version> — <date>` line (no `[N]`) above the commits it shipped. These are structural separators, not entries — skip them when scanning for the next number.

## Entry format

```
## [N] — <Product objective or goal — flag any breaking/large change here>

<YYYY-MM-DD>

- `path/to/file`: <what changed in this file>
  - <sub-point: another distinct change in the same file>
- `path/to/other`: <what changed>
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

Labels are optional — prefix a bullet (or sub-point) with one when the category isn't obvious from the text.

---

## Exemplar — Feature release (product-goal summary)

```markdown
## [17] — Sign in with Google — no separate password required

2026-06-07

- `src/auth/google.ts`: add OAuth2 login flow
  - store the session token in an HTTP-only cookie
- `src/pages/login.tsx`: add the "Sign in with Google" button
- `src/routes.ts`: redirect `/login` to the dashboard on success instead of a confirmation page
```
