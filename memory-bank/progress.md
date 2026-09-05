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
- Core全体の未移植範囲を`memory-bank/core-port-todo.md`へ整理。
- Runtime-onlyユーザー、ログイン状態、public/user/admin handler権限と拒否テストを追加。
- ページ公開レベル、凍結、編集可否判定をCoreとFile/Memory Storageに追加。
- 明示CallableによるPlugin install/instance cache、editform/menu/admin-menu登録を追加。

## Next

1. Wiki処理境界とParser/Format Plugin契約を設計・テストする。
2. URL/config補助API、WikiFarmを順に移植する。
3. JSON APIの入力スキーマ、統一エラー、権限適用を固める。

## Deferred

- 認証、CSRF、履歴、Wikiパーサー、DB Storage、OpenAPI生成。
- 複数Pluginで重複が確認されるまで、共通基底クラスやProxy基底実装を増やさない。
- API契約が安定するまでOpenAPI生成を追加しない。
