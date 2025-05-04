# **Tech Context**

## **使用技術**

* **Cloudflare Workers:** サーバーレス実行環境 (JavaScript/TypeScript)  
* **Cloudflare D1:** SQLite互換リレーショナルデータベース  
* **Cloudflare KV:** Key-Valueストア  
* **Cloudflare R2:** オブジェクトストレージ  
* **Cline:** PerlコードをJavaScript/TypeScriptに変換するためのマイグレーションツール  
* **TypeScript:** 静的型付けによる開発効率と保守性の向上  
* **Node.js / npm:** 開発環境、依存パッケージ管理  
* **Wrangler CLI:** Cloudflare Workersの開発、デプロイ、管理ツール  
* **Git:** バージョン管理システム  
* (必要に応じて) テキスト整形、差分計算、ルーティングなどのJavaScript/TypeScriptライブラリ

## **開発環境**

* **OS:** Linux, macOS, Windows (WSL含む) など、Node.jsとWrangler CLIが動作する環境  
* **エディタ:** VS Codeなど、TypeScript開発に適したエディタ  
* **CLI:** Wrangler CLI (npm install \-g wrangler)  
* **依存管理:** npm または yarn, pnpm  
* **Cline実行環境:** Clineが動作する環境 (Perlが必要な場合あり)

## **技術的な制約**

* **Cloudflare Workersの制限:** CPU実行時間、メモリ使用量、スクリプトサイズなどの制限を考慮する必要があります。複雑な処理は分散させるか、最適化が必要です。  
* **D1の制限:** 比較的新しいサービスであり、大規模なデータや複雑なクエリにおけるパフォーマンス特性を理解し、適切に利用する必要があります。  
* **KVの結果整合性:** 書き込み後、全てのリージョンに反映されるまで若干の遅延があるため、即時の一貫性が必要な処理には向きません（キャッシュ用途が主）。  
* **Clineの変換精度:** Perlの全ての構文やライブラリ呼び出しを完全に自動でTypeScriptに変換できるわけではありません。変換後のコードには手動での修正やリファクタリングが必須となります。特に、FreestyleWiki固有のマクロ処理やプラグイン機構など、複雑なPerlコードの移植は大きな課題となります。

## **依存関係**

* **Cloudflare Workers Runtime:** Workers実行環境自体が提供するAPI (Fetch Event, Durable Object State, Bindings等)  
* **Cloudflare Bindings:** D1, KV, R2へのアクセスに使用するBinding  
* **npm Packages:**  
  * @cloudflare/workers-types: Workers APIの型定義  
  * itty-router または他のルーターライブラリ  
  * テキスト処理、差分計算、HTML生成などのユーティブリライブラリ  
  * (開発依存) typescript, wrangler, テストフレームワーク (vitestなど)  
* **Cline:** 移植プロセスを実行するための外部ツール。

(さらに詳しい依存ライブラリや特記事項は memory-bank/details/technical\_notes.md に記載)