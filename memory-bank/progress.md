# Progress

## Completed

- Raku Core hook、handler、plugin metadataを実装。
- Memory/File Storageを実装。
- 既存`data/*.wiki`をRakuから読み取り。
- `/source/<page>`をCore hook経由で提供。
- `/page/<page>`のPOST保存をCore/Storage経由で提供。
- source HTMLエスケープとStorageパス逸脱回帰テストを追加。
- Croによる開発時ホットリロードを追加。
- Core handlerへ明示的なAPI metadataを登録可能にした。
- API metadata登録時に`SOURCE`と`SAVE_PAGE`のJSON routeを生成。
- `GET /api/source?page=<page>`と`POST /api/page/<page>`を同じCore/Storage処理へ接続。
- 実機HTTPでJSON取得とJSON保存を確認。

## Next

1. APIエラー形式と権限エラーを定義する。
2. 認証モデル導入後にpublic/user/admin権限をJSON経路へ適用する。
3. 2つのページ操作でAPI登録契約を安定させる。
4. 複数Pluginで重複が確認できた場合だけRoleまたはProxy共通実装を追加する。

## Deferred

- 認証、CSRF、履歴、Wikiパーサー、DB Storage、OpenAPI生成。
- 複数Pluginで重複が確認されるまで、共通基底クラスやProxy基底実装を増やさない。
- API契約が安定するまでOpenAPI生成を追加しない。
