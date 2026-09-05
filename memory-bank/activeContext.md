# Active Context

- Branch: `migration/raku-core-mvp`
- Raku implementation provides Core hooks, handlers, Memory/File Storage, and Cro HTTP routes.
- Current routes: `GET /health`, `GET /source/<page>`, `POST /page/<page>`, `GET /api/source?page=<page>`, `POST /api/page/<page>`.
- Cro development runner is configured by `.cro.yml` and `make raku-dev`.
- Latest implementation commit: `0b7e90d feat: generate JSON page operations from API handlers`.
- Core migration is incomplete. The remaining Perl Wiki.pm responsibilities are tracked in `memory-bank/core-port-todo.md`.
- Storage contract now provides page listing, physical/logical timestamps, and single-generation backup primitives for File/Memory backends.
- Core now provides runtime-only users, login state, and public/user/admin handler authorization.
- Next slice: investigate page visibility levels and page freezing.
- API exposure remains explicit; do not publish all Core methods automatically.
- Base classes and Proxy/Adapter are deferred until multiple plugins demonstrate duplicated adaptation logic.

## Verification

- `make raku-test` passes after the authentication/authorization extension.
- `raku -c raku/dev-server.raku` passes.
- Real HTTP GET `/api/source?page=FrontPage` and POST `/api/page/ApiDraft` were verified on the Cro development server.

## Known legacy documents

The numbered documents describe the Raku migration direction. Historical Perl/Docker/DB details should not be used as current Raku implementation requirements unless verified against the repository.

