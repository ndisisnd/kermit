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

### Writing rules

- **Summary heading**: a `##` heading phrased as a product goal or user outcome; fall back to a technical description only when no product goal is clear. Always call out breaking changes and large changes in the heading itself.
- **Date**: ISO 8601 (`YYYY-MM-DD`) on its own line beneath the heading; latest entry at the top of the file.
- **Bullets**: one per touched file, starting with the file path, then what changed. Keep each terse; use sub-points for multiple changes to the same file. Skip pure churn (whitespace, comment-only edits) unless it carries meaning.
- **Breaking changes**: never leave them implicit — the heading flags them and the relevant file bullet spells out the migration.

---

## Exemplar 1 — Feature release (product-goal summary)

```markdown
## Sign in with Google — no separate password required

2026-06-07

- `src/auth/google.ts`: add OAuth2 login flow
  - store the session token in an HTTP-only cookie
- `src/pages/login.tsx`: add the "Sign in with Google" button
- `src/routes.ts`: redirect `/login` to the dashboard on success instead of a confirmation page
```

## Exemplar 2 — Bug fix + security patch

```markdown
## Stop crashes on empty input and close a search-field XSS hole

2026-05-14

- `src/parser.ts`: Fixed — return an empty result instead of panicking on an empty string
- `src/search/render.ts`: Security — escape HTML entities before rendering results
- `src/errors.ts`: Changed — include the offending line number in parse errors
```

## Exemplar 3 — Breaking change

```markdown
## BREAKING: unify configuration under a single `kermit.json` file

2026-05-02

- `src/config/load.ts`: read config from `kermit.json`; drop support for `.kermitrc`
  - throw a clear migration error when a legacy `.kermitrc` is detected
- `README.md`: document the new config file and the migration steps
- `.gitignore`: ignore local `kermit.json` overrides
```
