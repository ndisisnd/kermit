# Changelog Protocol — Reference

The changelog groups entries **by date**. The newest date sits at the top of the file; within a date, the newest entry (highest number) comes first.

## Structure

1. **Date section** — a Markdown `##` heading holding an ISO 8601 date (`## YYYY-MM-DD`). Every entry committed on that day lives under it. Newest date at the top.
2. **Numbered entry** — under a date section, each commit is a `###` heading of the form `### [N] — <summary>`, where `N` is the entry's sequence number (see **Numbering**) and `<summary>` states the commit's product objective or goal: what the user can now do, or why the change matters to them. Frame it as an outcome, **not** a technical description of the implementation. Fall back to a technical description only when there is no clear product goal. The heading **must** surface any breaking or large change — lead with it (e.g. `### [N] — BREAKING: …`).
3. **Change list** — one bullet per touched file, directly under the entry heading. Each bullet names the file and says what changed in it. A bullet may carry sub-points when a single file has multiple distinct changes.

## Numbering

Every entry carries a strictly increasing integer `N`, one per commit, newest entry at the top of the file with the highest `N`. Numbers never reset.

- Get the next number from `last_number + 1` in `.claude/kermit/state.json`.
- If state is unavailable, derive it from the file: the highest existing `### [k]` heading + 1.
- Starting value is `1` (so `last_number: 0` → first entry is `### [1]`).
- After writing, set `last_number` in `.claude/kermit/state.json` to the highest `N` written.

## Date grouping

When writing a new entry, look at the **topmost** `## <date>` section in the entry area:

- If its date equals **today**, add the new `### [N] — <summary>` entry as the **first** entry under it (directly below the `## <date>` line, above that day's previous newest entry).
- Otherwise, open a **new** `## <today>` section at the top of the entry area (below the `# Changelog` preamble) and put the new entry under it.

So each date appears once, and a day's commits accumulate beneath it newest-first.

## Entry format

```
## <YYYY-MM-DD>

### [N] — <Product objective or goal — flag any breaking/large change here>

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

## Exemplar — a day with two entries

```markdown
## 2026-06-07

### [18] — Sign in with Google — no separate password required

- `src/auth/google.ts`: add OAuth2 login flow
  - store the session token in an HTTP-only cookie
- `src/pages/login.tsx`: add the "Sign in with Google" button

### [17] — Redirect straight to the dashboard after login

- `src/routes.ts`: send `/login` to the dashboard on success instead of a confirmation page
```
