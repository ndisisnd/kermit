# Conventional Commits — Protocol Reference

Format: `<emoji> <type>[(<scope>)][!]: <description>`

- Subject line ≤ 72 chars; description is lowercase imperative
- Blank line between subject and body
- Body: one bullet per changed file — `- <file> — <descriptor>`
- Breaking changes: add `!` to subject AND `BREAKING CHANGE:` footer

## Exemplar 1 — Simple feature

```
✨ feat(auth): add oauth2 login via google provider

- src/auth/oauth.ts — new OAuth2 client and callback handler
- src/routes/auth.ts — /auth/google and /auth/callback routes
- src/middleware/session.ts — persist oauth tokens to session store
```

## Exemplar 2 — Bug fix with scope

```
🐛 fix(parser): handle empty token list without panic

- src/parser/tokenizer.ts — guard against zero-length input early return
- tests/parser.test.ts — regression case for empty string input
```

## Exemplar 3 — Breaking change

```
♻️ refactor(api)!: replace REST endpoints with tRPC router

- src/server/router.ts — tRPC router replacing all express route handlers
- src/client/api.ts — generated tRPC client replacing axios calls
- src/types/api.ts — shared input/output schemas moved to router definition

BREAKING CHANGE: all /api/* REST endpoints removed; callers must migrate to tRPC client
```
