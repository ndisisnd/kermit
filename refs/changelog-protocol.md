# Changelog Protocol — Reference

Each changelog entry has exactly three parts:

1. **Summary heading** — a Markdown `##` heading stating the release's product objective or goal: what the user can now do, or why the change matters to them. Frame it as an outcome, **not** a technical description of the implementation. Fall back to a technical description only when there is no clear product goal. The heading **must** surface any breaking change or large change — lead with it (e.g. prefix `BREAKING:`).
2. **Date line** — the ISO 8601 date (`YYYY-MM-DD`) on its own line directly under the heading.
3. **Change list** — one bullet per touched file. Each bullet names the file and says what changed in it. A bullet may carry sub-points when a single file has multiple distinct changes.

## Entry format

```
## <Product objective or goal — flag any breaking/large change here>

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
## Sign in with Google — no separate password required

2026-06-07

- `src/auth/google.ts`: add OAuth2 login flow
  - store the session token in an HTTP-only cookie
- `src/pages/login.tsx`: add the "Sign in with Google" button
- `src/routes.ts`: redirect `/login` to the dashboard on success instead of a confirmation page
```
