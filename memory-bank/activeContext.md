# Active Context

- Branch: `migration/raku-core-mvp`
- Raku implementation provides Core hooks, handlers, Memory/File Storage, and Cro HTTP routes.
- Current routes: `GET /health`, `GET /source/<page>`, `POST /page/<page>`, `GET /api/source?page=<page>`, `POST /api/page/<page>`.
- Cro development runner is configured by `.cro.yml` and `make raku-dev`.
- Latest implementation commit: `93a0f80 feat: register and serve JSON API metadata` before the current uncommitted continuation.
- Core handler records now carry explicit API metadata. `register-api-handlers` registers SOURCE and SAVE_PAGE once during application initialization; JSON responses use the same Core and Storage path.
- API exposure remains explicit; do not publish all Core methods automatically.
- Base classes and Proxy/Adapter are deferred until multiple plugins demonstrate duplicated adaptation logic.
- Keep this file limited to current state and next step.

## Verification

- `make raku-test` passes.
- `raku -c raku/dev-server.raku` passes.
- Real HTTP GET `/api/source?page=FrontPage` and POST `/api/page/ApiDraft` were verified on the Cro development server.

## Next

- Add structured API error responses and permission enforcement when the authentication model is introduced.
- Extend metadata-driven route generation beyond the two page operations only after the registration contract is stable.

## Known legacy documents

The numbered documents describe the Raku migration direction. Historical Perl/Docker/DB details should not be used as current Raku implementation requirements unless verified against the repository.

