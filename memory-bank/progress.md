# Progress

## Completed

- Raku Core hook、handler、plugin metadataを実装。
- Memory/File Storageを実装。
- 既存`data/*.wiki`をRakuから読み取り。
- `/source/<page>`をCore hook経由で提供。
- `/page/<page>`のPOST保存をCore/Storage経由で提供。
- source HTMLエスケープとStorageパス逸脱回帰テストを追加。
- Croによる開発時ホットリロードを追加。

## Next

1. Core handler recordに明示的なAPI metadataを追加。
2. API metadataからJSON routeを生成。
3. `GET /api/source`で同じCore処理をJSON化。
4. `POST /api/page/<page>`で同じ保存処理をJSON化。
5. 実機HTTPでHTML/JSONの共通Core経路を検証。

## Deferred

- 認証、CSRF、履歴、Wikiパーサー、DB Storage、OpenAPI生成。
- 複数Pluginで重複が確認されるまで、共通基底クラスやProxy基底実装を増やさない。
