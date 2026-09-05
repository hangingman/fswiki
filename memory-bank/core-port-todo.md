# Core移植TODO

## 判定

FSWiki Coreの移植は未完了。現在のRaku Coreは、フック、基本Handler、Plugin metadata、Storage委譲、明示的API metadataを実装したMVPである。Perl版`lib/Wiki.pm`には68個のサブルーチンがあり、Raku側の対応は一部に限られる。

## TODO

- [x] Core/Storage契約を拡張する: ページ一覧、更新日時、バックアップ/履歴の必要性をPerl Wiki.pmとStorageから調査してRaku APIを決める（`get-page-list`、`get-last-modified`、`get-last-modified2`、backup API）
- [x] 認証・認可を移植する: `add_user`、`user_exists`、`login_check`、`get_login_info`、public/user/admin handler権限（Raku Core内のruntime-only実装。HTTP session、hashing、永続化は後続）
- [x] ページ権限・凍結を移植する: `freeze_page`、`un_freeze_page`、`is_freeze`、`can_modify_page`、`set_page_level`、`can_show`（runtime metadata。Fileは`.fswiki-metadata`、Memoryはプロセス内）
- [x] Pluginライフサイクルを移植する: `install_plugin`、`is_installed`、`get_plugin_instance`、editform/menu/admin-menu登録（明示Callableのみ。動的module loadingは後続）
- [x] Wiki処理境界を移植する: `process_wiki`、`process_plugin`、`parse_inline_plugin`、Parser/Format Plugin契約（Processor registryとWiki state-machine parserを実装。legacy plugin処理は後続）
- [ ] Format Plugin APIを移植する: `add_format_plugin`、`get_format_names`、`convert_to_fswiki`、`convert_from_fswiki`、`get_edit_format`
- [ ] Core補助APIを移植する: `config`、`set_title/get_title`、`create_page_url/create_url`、`redirect`、head-info
- [ ] WikiFarm APIを移植する: `farm_is_enable`、`create_wiki`、`remove_wiki`、`wiki_exists`、`get_wiki_list`、`search_child`
- [ ] JSON API基盤を固める: 入力スキーマ、統一エラー、権限適用、HTML/JSON共通handler経路

## 実装順

1. Storage契約とページ一覧/更新日時。
2. 認証・認可とHandler権限。
3. ページ権限・凍結。
4. Plugin lifecycleとメニュー。
5. Parser/Format Plugin境界。
6. URL/config補助API。
7. WikiFarm。
8. JSON API hardening。

## ルール

- Perl版は責務と挙動のリファレンス。逐語移植しない。
- 各項目はPerl実装と既存呼び出し元を調査し、失敗テスト→最小実装→実機確認で進める。
- 完全パーサー、DB、認証基盤などを先行実装しない。
- API公開は明示登録だけに限定する。
- 基底クラスやProxyは複数Pluginで重複が確認されてから導入する。

## 対応済み範囲

- `add_hook` / `do_hook`
- `add_handler` / `add_user_handler` / `add_admin_handler`の登録情報
- `call_handler`の基本呼び出し
- inline/paragraph/block Plugin metadata
- `get_page` / `save_page` / `page_exists`
- File/Memory Storage
- API metadataと`SOURCE`/`SAVE_PAGE` JSON endpoint

## 対応未完了

FSWikiのCore全体、認証、権限、履歴、Parser、Format Plugin、Farm、URL生成、設定管理は未完了。
