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
- Core全体のruntime MVP範囲を実装し、Plugin/UI/AJAX計画を`memory-bank/plugin-port-todo.md`へ移行。
- Runtime-onlyユーザー、ログイン状態、public/user/admin handler権限と拒否テストを追加。
- ページ公開レベル、凍結、編集可否判定をCoreとFile/Memory Storageに追加。
- 明示CallableによるPlugin install/instance cache、editform/menu/admin-menu登録を追加。
- Wiki Processor契約、Wiki記法のstate-machine/cursor parser、Core Processor registryを追加。Markdownは同じ契約へ差し替え可能なCallableとして検証。
- Format Plugin registry、双方向変換、inline変換、FSWiki fallback、edit format選択を追加。
- Core config/title/URL/redirect/head-info helper APIを追加。
- Runtime WikiFarm child registry、safe name validation、create/remove/list/prefix searchを追加。
- JSON API schema validation、統一エラー、permission enforcement、HTML/JSON共通Core handler経路を追加。
- Wiki ProcessorをHTML表示経路へ接続し、公開Wiki記法、ページリンク、可視性、HTMLエスケープをブラウザ表示経路で確認。
- HTTP編集画面、保存、権限/凍結拒否、保存失敗時の本文保持、ページ作成・削除・差分・一覧・Raw/Pre/Blockquote表示を追加。
- JSON APIにページ一覧`GET /api/pages`とページ取得`GET /api/page/{page}`を追加し、実HTTPで確認。

## Next

1. M3: AJAX編集へ進む。

## Deferred

- 認証、CSRF、履歴、Wikiパーサー、DB Storage、OpenAPI生成。
- 複数Pluginで重複が確認されるまで、共通基底クラスやProxy基底実装を増やさない。
- API契約が安定するまでOpenAPI生成を追加しない。
