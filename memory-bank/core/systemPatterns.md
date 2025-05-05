# **System Patterns**

## Perl実装の主要モジュール

### WikiApplication.pm

FreeStyleWikiのフロントエンドPSGIモジュール。リクエストを受け付け、Wikiオブジェクトを生成し、アクションハンドラを呼び出してレスポンスを生成する役割を担う。

`git show master:lib/WikiApplication.pm`

### Wiki.pm

FreeStyleWikiのコア機能を提供するモジュール。設定管理、ユーザー管理、プラグイン管理、ページデータ操作（ストレージ抽象化）、Wiki記法変換、URL生成、Farm機能などを実装している。特にプラグイン機構とストレージ抽象化が特徴的で、高い拡張性を持つ設計となっている。移植においては、このモジュールの機能をCloudflare Workers環境に合わせて再実装する必要がある。

`git show master:lib/Wiki.pm`

### Wiki::DefaultStorage.pm

FreeStyleWikiのデフォルトのストレージ実装モジュール。ファイルシステムをストレージとして使用し、ページの読み書き、バックアップ、凍結、参照権限などをファイル操作で管理している。Cloudflare Workersへの移植では、このファイルシステム操作部分をD1, KV, R2などのCloudflareストレージサービスに置き換える必要がある。

`git show master:lib/Wiki/DefaultStorage.pm`

### Wiki::HTMLParser.pm

Wiki記法で書かれたテキストを解析し、HTMLに変換するモジュール。Wiki::Parserを継承し、各記法要素に対応するメソッド内でHTMLタグを生成する。ネストされた要素やインライン要素、プラグイン、パート編集リンクの生成ロジックを含む。移植においては、このPerlコードのHTML変換ロジックをTypeScriptで再現する必要がある。

`git show master:lib/Wiki/HTMLParser.pm`

### Wiki::Parser.pm

Wiki記法テキストのパース処理の基盤を提供するモジュール。入力テキストを行単位で解析し、正規表現を用いてブロック要素やインライン要素、キーワード、WikiNameを識別する。各記法に対応するフックメソッドを呼び出し、継承クラス（例: Wiki::HTMLParser）でこれらのメソッドをオーバーライドすることで具体的な変換処理を実現する。移植においては、このモジュール内の正規表現パターンと解析ロジックをTypeScriptで再現することが重要となる。

`git show master:lib/Wiki/Parser.pm`

### Util.pm

FreeStyleWiki全体で使用されるユーティリティ関数群を提供するモジュール。文字列操作（エンコード/デコード、エスケープ、トリムなど）、ファイル操作（パス生成、設定ファイルの読み書き、ファイルロック）、データフォーマット、ネットワーク関連（HTTPリクエスト、メール送信）、ユーザーエージェント判定、MD5ハッシュ計算など、多岐にわたる共通処理を実装している。移植においては、これらのPerl関数に依存する機能をTypeScriptとWorkers環境で利用可能な代替手段で再実装する必要がある。

`git show master:lib/Util.pm`

### Wiki::Keyword.pm

Wikiテキスト中のキーワードやWikiNameを識別し、対応するURLやページ名へのリンクを生成するための正規表現を構築・管理するモジュール。`Keyword.wiki`ページやページ名からキーワード定義を読み込み、ユーザー権限レベルに応じた正規表現を生成・キャッシュする。`exists_keyword`メソッドでキーワードの検索とリンク先取得を行う。移植においては、正規表現の動的な構築とマッチングロジックの再現が課題となる。

`git show master:lib/Wiki/Keyword.pm`

### Wiki::InterWiki.pm

InterWikiリンク処理を担うモジュール。`InterWikiName.wiki`ページに定義されたInterWiki名とURLの対応関係を読み込み、Farm機能による子WikiもInterWikiとして扱いリストに追加する。Wikiテキスト中のInterWikiリンク（`[[InterWiki名:ページ名]]`形式）を識別し、対応するURLを生成する。移植においては、InterWiki定義の解析とリンク生成ロジックの再現が必要となる。

`git show master:lib/Wiki/InterWiki.pm`

## **システムアーキテクチャ**

FreestyleWiki Cloudflare Workers Migrationプロジェクトのシステムアーキテクチャは、Cloudflareのサーバーレスサービス群を中心としたマイクロサービス的な構成を採用します。

### **コアアーキテクチャの構成**

1. **Compute Layer: Cloudflare Workers**  
   * 全てのリクエスト処理の起点となります。  
   * ルーティング、データアクセス、ビジネスロジック実行、レスポンス生成を担当します。  
   * ステートレスな関数実行環境です。  
2. **Data Persistence Layer:**  
   * **Cloudflare D1 (SQLite):**  
     * 構造化された主要データの永続化に使用します。  
     * Wikiページ本文、リビジョン履歴、編集者・タイムスタンプ等のメタ情報、ページ間リンク、添付ファイルメタ情報、ユーザー情報などを保存します。  
     * リレーショナルなクエリによるデータ取得・更新に適しています。  
   * **Cloudflare KV (Key-Value):**  
     * 高速な読み取りが必要なデータのキャッシュや、結果整合性が許容されるデータの保存に使用します。  
     * 最新のページ本文（レンダリング済み）、最近の更新リストなどをキャッシュとして保持します。  
   * **Cloudflare R2 (Object Storage):**  
     * 添付ファイルなどのバイナリデータの保存に使用します。  
3. **(Optional) State Management: Cloudflare Durable Objects**  
   * 特定のエンティティ（例: Wikiページ）に対する状態を保持したい場合に使用します。  
   * ページの編集競合検出やロック機能の実装に活用できる可能性があります。  
4. **(Optional) Frontend Hosting: Cloudflare Pages**  
   * WorkersがHTMLを生成する代わりに、モダンなフレームワークで構築されたSPA/SSRフロントエンドをホストする場合に利用できます。WorkersはAPIとして機能します。

## **主要な技術的決定**

* **サーバーレスファースト:** Cloudflare Workersを主要な実行環境とし、可能な限りマネージドサービスを利用します。  
* **多層データストア:** D1, KV, R2をデータの種類とアクセスパターンに応じて使い分け、パフォーマンスとコスト効率を最適化します。  
* **JavaScript/TypeScript:** Workersの開発言語として採用します。既存のPerlコードはClineを用いてこの言語に変換します。  
* **段階的な移植:** 一度に全ての機能を移植せず、コア機能から順に実装を進めます。

### **標準実装パターン**

1. **Workers Request Handling:**  
   * fetch イベントリスナー内でリクエストを処理します。  
   * itty-router や @tsndr/cloudflare-worker-router のようなルーティングライブラリを使用して、URLパスとHTTPメソッドに基づいた処理関数にディスパッチします。  
2. **Data Access Patterns:**  
   * D1へのアクセスは、WorkersのD1 Bindingを通じて行います。SQLクエリはWorkersコード内に記述します。  
   * KVへのアクセスは、KV Bindingを通じて行います。キャッシュの読み書きや削除を行います。  
   * R2へのアクセスは、R2 Bindingを通じて行います。ファイルのアップロード、ダウンロード、削除を行います。  
3. **Error Handling:**  
   * Workersのエラーハンドリング機構 (ctx.waitUntil, try...catch) を適切に使用します。  
   * データストア操作時のエラーを捕捉し、適切なHTTPステータスコードとエラーメッセージを返します。  
4. **Clineによるコード変換:**  
   * FreestyleWikiのPerlモジュールや関数を個別に特定し、Clineを使用してJavaScript/TypeScriptコードに変換します。  
   * 変換されたコードはWorkersプロジェクト内に組み込み、必要に応じて手動で修正・調整を行います。

## **使用している設計パターン**

* **マイクロサービス:** 各Workersスクリプト（またはDurable Object）が特定の機能やデータストアへのアクセスを担当する、疎結合な設計を目指します。  
* **Cache-Aside Pattern:** ページの表示において、まずKVキャッシュを確認し、存在しない場合にD1から取得してKVに書き戻すパターンを採用します。  
* **Repository Pattern:** データストアへのアクセスロジックを抽象化し、Workersのビジネスロジックから分離することを検討します。

## **プロジェクトのディレクトリ構成 (Workers部分の例)**

.
├── src/                     \# Workersソースコード
│   ├── index.ts             \# エントリーポイント、ルーター定義
│   ├── handlers/            \# 各エンドポイントの処理関数
│   │   ├── wiki.ts          \# /wiki/\* 関連のハンドラ (表示、編集、保存)
│   │   ├── api.ts           \# /api/\* 関連のハンドラ (検索、アップロード等)
│   │   └── auth.ts          \# 認証関連のハンドラ (オプション)
│   ├── services/            \# ビジネスロジック (データストア非依存)
│   │   ├── pageService.ts   \# ページ関連ロジック (保存、リビジョン管理)
│   │   ├── renderService.ts \# テキスト整形・レンダリングロジック
│   │   └── diffService.ts   \# 差分計算ロジック
│   ├── data/                \# データストアアクセスロジック (Repository Pattern)
│   │   ├── pageRepository.ts \# D1へのページデータアクセス
│   │   ├── cacheRepository.ts \# KVへのキャッシュアクセス
│   │   └── fileRepository.ts \# R2へのファイルアクセス
│   └── types.ts             \# 型定義
├── cline\_output/          \# Clineによる変換コード出力先 (一時的または管理用)
├── wrangler.toml          \# Cloudflare Workers設定ファイル (D1, KV, R2 Binding定義含む)
├── package.json           \# Node.js/npm 設定 (依存ライブラリ管理)
└── tsconfig.json          \# TypeScript 設定

## **コンポーネント間の関係**

* Workersハンドラは、Services層を呼び出してビジネスロジックを実行します。  
* Services層は、Data層（Repository）を介してD1, KV, R2と連携します。  
* Durable Objectsを使用する場合、WorkersハンドラからDurable Object Stubを取得して呼び出します。  
* Clineによって生成されたコードは、Services層またはData層の一部として組み込まれます。