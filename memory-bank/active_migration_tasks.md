# Mojolicious移行タスク

## 1. 準備：共存環境の構築
- [x] Mojoliciousの導入と依存関係追加 (`cpanfile`) <!-- id: 0 -->
- [x] `app.psgi` でのMojoliciousマウント設定 (例: `/v2`) <!-- id: 1 -->
- [x] テスト基盤の整備 (`Test::Mojo`導入, 既存URLへのテスト) <!-- id: 2 -->
- [x] Monorepo構成の開始 (`package.json`作成, Vite準備) <!-- id: 3 -->

## 2. 基本機能の移行（フェーズ1）
- [/] RESTルーティングの実装 (`/pages/:name`, `/pages/:name/edit` 等) <!-- id: 4 -->
- [ ] データ層（`Wiki.pm`, `Wiki::DefaultStorage`）の共有設定 <!-- id: 5 -->
- [/] 新テンプレートエンジン(`.html.ep`)の導入と共通レイアウト作成 <!-- id: 6 -->
- [ ] パーサーディスパッチャの作成（拡張子によるパーサー切り替え） <!-- id: 7 -->

## 3. プラグイン・拡張系の移行（フェーズ2）
- [ ] コントローラー化 (既存 `ActionHandler` の移行) <!-- id: 8 -->
- [ ] フックとヘルパーの統合 (Mojolicious hook / helper への置換) <!-- id: 9 -->
- [ ] JavaScriptのモダン化 (各プラグインの `package.json` 化, ES Modules化) <!-- id: 10 -->

## 4. インフラ・外部連携の刷新（フェーズ3）
- [ ] ストレージ抽象化の拡張 (S3互換アダプター追加) <!-- id: 11 -->
- [ ] アセット配信の分離 (画像等のObject Storageオフロード) <!-- id: 12 -->
- [ ] API (JSON-RPC) の実装 <!-- id: 13 -->

## 5. 最終移行
- [ ] パスの切り替え (レガシーパスのリダイレクト) <!-- id: 14 -->
- [ ] クリーンアップ (古い `.tmpl`, `ActionHandler` 削除) <!-- id: 15 -->
