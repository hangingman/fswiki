# Active Context

- Branch: `migration/raku-core-mvp`
- Raku implementation provides Core hooks, handlers, Memory/File Storage, and Cro HTTP routes.
- Current routes: `GET /health`, `GET /source/<page>`, `POST /page/<page>`.
- Cro development runner is configured by `.cro.yml` and `make raku-dev`.
- Latest implementation commit: `40ecc3e feat: add HTTP page save endpoint`.
- Next design slice: explicit Core handler API metadata, generated JSON route, shared Core processing for HTML and JSON.
- API exposure must be explicit; do not publish all Core methods automatically.
- Base classes and Proxy/Adapter are deferred until multiple plugins demonstrate duplicated behavior.
- Keep this file limited to current state and next step.

## Verification

- `make raku-test` passes.
- `raku -c raku/dev-server.raku` passes.
- Real HTTP POST/GET page save/source flow was verified on the Cro development server.

## Known legacy documents

The numbered documents describe the Raku migration direction. Historical Perl/Docker/DB details should not be used as current Raku implementation requirements unless verified against the repository.

