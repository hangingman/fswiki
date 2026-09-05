# Active Context

- Branch: `migration/raku-core-mvp`
- Raku implementation provides Core hooks, handlers, Memory/File Storage, and Cro HTTP routes.
- Current routes: `GET /health`, `GET /source/<page>`, `POST /page/<page>`, `GET /api/source?page=<page>`, `POST /api/page/<page>`.
- Cro development runner is configured by `.cro.yml` and `make raku-dev`.
- Latest implementation commit: `ca07c1d feat: add JSON page listing and retrieval`.
- Core runtime MVP is complete. Plugin移植と画面/AJAX milestones are tracked in `memory-bank/plugin-port-todo.md`.
- Storage contract now provides page listing, physical/logical timestamps, and single-generation backup primitives for File/Memory backends.
- Core now provides runtime-only users, login state, and public/user/admin handler authorization.
- Core now provides page visibility levels, freeze state, runtime plugin lifecycle, and menu registration.
- Core now delegates Wiki processing through an explicit processor registry. The default Wiki processor uses a block state machine and inline cursor scanner.
- Core now provides an explicit Format Plugin registry and bidirectional conversion API.
- Core now provides runtime config/title/URL/redirect/head-info helpers.
- Core now provides a minimal runtime WikiFarm child registry with safe names and prefix search.
- JSON API now has explicit input schemas, Core validation, unified errors, and centralized permission enforcement.
- Filesystem Farm, HTTP session, dynamic plugin loading, and full legacy parser/plugin behavior remain deferred.
- API exposure remains explicit; do not publish all Core methods automatically.
- Base classes and Proxy/Adapter are deferred until multiple plugins demonstrate duplicated adaptation logic.

## Verification

- `make raku-test` passes after the authentication/authorization extension.
- `make raku-test` passes after the page permission/freeze and plugin lifecycle extensions.
- `raku -I raku/lib raku/t/parser.t` and `make raku-test` pass after the Wiki processor extension.
- `make raku-test` passes after the Format Plugin API extension.
- `make raku-test` passes after the Core helper API extension.
- `make raku-test` passes after the WikiFarm API extension.
- `raku -I raku/lib raku/t/api.t` and `make raku-test` pass after JSON API hardening.
- `raku -c raku/dev-server.raku` passes.
- Real HTTP GET `/api/source?page=FrontPage` and POST `/api/page/ApiDraft` were verified on the Cro development server.

## Next milestone

- M0: browser verification of `/source/Home` and `/api/source?page=Home` is complete.
- M1: Wiki Processor and M2 HTTP editing are complete; M3 JSON pages/page retrieval is implemented and verified.

## Known legacy documents

The numbered documents describe the Raku migration direction. Historical Perl/Docker/DB details should not be used as current Raku implementation requirements unless verified against the repository.

