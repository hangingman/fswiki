# **rules\_extras**

## **詳細な運用方針や具体的コード例**

こちらには、.clinerules に記載するには詳細すぎるポリシー、手順、サンプルコードなどを記述します。

### **ローカル開発環境構築に関する補足**

*   **Node.jsのバージョン管理:** プロジェクトではasdfを使用してNode.jsのバージョンを管理します。`.tool-versions` ファイルを参照してください。
*   **wrangler init:** wranglerのバージョンによって初期化コマンドのオプションが異なる場合があります。既存のファイルが存在するディレクトリに初期化する際は注意が必要です。
*   **データストアバインディング:** ローカル開発およびデプロイには、`wrangler.jsonc` にD1, KV, R2などのバインディング設定が必要です。詳細はCloudflare Workersのドキュメントを参照してください。

### **テスト実行ポリシー (Workers)**

1. **テスト実行の基本ルール:**  
   * **ローカル開発:** wrangler dev コマンドを使用して、ローカル環境でWorkersを起動し、HTTPリクエストを送信して動作確認を行います。D1, KV, R2エミュレーションやリモート接続オプションを活用します。  
   * **単体テスト:** VitestやJestのようなJavaScript/TypeScriptテストフレームワークを使用して、Workersハンドラやビジネスロジックの単体テストを記述・実行します。モックやスタブを使用して依存関係（データストアアクセスなど）を分離します。  
   * **統合テスト:** 実際のCloudflare環境（テスト環境など）にデプロイし、WorkersとD1/KV/R2が連携して正しく動作するかを確認します。wrangler publish \--dry-run \--outdir dist で生成されるコードを確認することも有効です。  
   * **E2Eテスト:** PlaywrightやCypressのようなツールを使用して、ブラウザからの操作を通じてWiki全体のフロー（ページ表示→編集→保存→履歴確認など）を確認します。  
2. **テストケース作成ガイドライン:**  
   * 各エンドポイント (表示、編集、保存など) に対して、正常系と異常系のテストケースを作成します。  
   * データストア操作が意図通りに行われるかを確認するテストを含めます。  
   * FreestyleWiki独自の記法やマクロが正しく処理されるかを確認するテストを作成します (Cline変換後のコードの検証も兼ねる)。  
   * 編集競合が発生する場合のテストケースを検討します。

### **Clineによる変換コードの取り扱い**

1. **変換プロセスの手順:**  
   * FreestyleWikiのPerlソースコードから、移植対象のモジュールや関数を特定します。  
   * Clineへの入力として適切な形式にコードを準備します。  
   * Clineを実行し、JavaScriptまたはTypeScriptコードを生成します。  
   * 生成されたコードをWorkersプロジェクト内の所定のディレクトリ (cline\_output/ など) に配置します。  
2. **変換コードのレビューと修正:**  
   * Clineによって生成されたコードは、そのままではWorkers環境で動作しない場合や、非効率な場合があります。  
   * 生成コードを注意深くレビューし、Workers APIやTypeScriptのベストプラクティスに沿って手動で修正・リファクタリングを行います。  
   * 特に、Perlのグローバル変数、ファイルI/O、外部コマンド実行など、Workers環境で直接実行できない機能の代替実装が必要です。  
3. **バージョン管理:**  
   * Clineによって生成されたコードも、手動修正を加えた上でGitによるバージョン管理下に置きます。元のPerlコードとの対応関係を明確にしておくと、後々の追跡に役立ちます。

### **ソースコード修正ポリシー (Workers)**

1. **コード変更の基本ルール:**  
   * TypeScriptを使用し、型安全性を確保します。  
   * 非同期処理は async/await を使用して記述します。  
   * Workersのステートレスな性質を意識し、リクエスト間で状態を共有しないように設計します（状態が必要な場合はDurable Objectsやデータストアを利用）。  
2. **リファクタリングガイドライン:**  
   * データストアアクセス、ビジネスロジック、HTTPハンドラなどの役割を明確に分離します。  
   * 共通の処理はユーティリティ関数として抽出し、再利用性を高めます。  
   * Clineから変換されたコードで冗長な部分や非効率なパターンがあれば、積極的にリファクタリングします。  
3. **命名規則:**  
   * TypeScriptの標準的な命名規則（CamelCaseなど）に従います。  
   * Workers Bindingの変数名 (env.DB, env.CACHE, env.BUCKET) は .env ファイルや wrangler.toml の設定と一致させます。  
4. **エラー処理:**  
   * Workersハンドラ内で発生したエラーは捕捉し、適切なHTTPステータスコード (例: 400 Bad Request, 500 Internal Server Error) とエラーレスポンスを返します。  
   * データストア操作時のエラーは詳細をログに出力しつつ、ユーザーには抽象的なエラーメッセージを返します。

### **レビュー・デプロイのポリシー**

1. **コードレビューのチェックポイント:**  
   * Workersの制限 (CPU, Memory) を超える可能性のある処理がないか。  
   * データストアへのアクセスが効率的に行われているか (N+1問題など)。  
   * エラーハンドリングが適切か。  
   * Cline変換後の手動修正箇所が意図通りに動作するか。  
   * TypeScriptの型エラーやLint警告がないか。  
2. **デプロイ前の確認事項:**  
   * ローカルでの wrangler dev による動作確認。  
   * 単体テスト、統合テストの成功。  
   * wrangler publish \--dry-run で生成コードを確認し、意図しないバンドルが含まれていないかチェック。  
   * wrangler publish コマンドでCloudflare環境にデプロイします。デプロイ対象のWorkersスクリプト、関連するBinding (D1, KV, R2), Durable Objects設定などが wrangler.toml で正しく指定されていることを確認します。  
   * デプロイ後の本番環境での疎通確認。

### **D1/KV/R2 連携コード例 (TypeScript)**

// src/data/pageRepository.ts (D1 アクセス例)  
import { D1Database } from "@cloudflare/workers-types";

interface Env {  
  DB: D1Database;  
}

interface Page {  
  id: string;  
  title: string;  
  content: string; // 最新リビジョンの内容  
  // 他のメタ情報  
}

interface Revision {  
  id: string;  
  page\_id: string;  
  content: string;  
  timestamp: string;  
  editor: string;  
  comment: string;  
}

export async function getPageByTitle(env: Env, title: string): Promise\<Page | null\> {  
  const { results } \= await env.DB.prepare("SELECT \* FROM pages WHERE title \= ? LIMIT 1")  
    .bind(title)  
    .all\<Page\>();

  return results && results.length \> 0 ? results\[0\] : null;  
}

export async function saveRevision(env: Env, pageId: string, content: string, editor: string, comment: string): Promise\<void\> {  
  // D1は単一ステートメントのみの実行に制限がある場合があるため、  
  // 複雑な保存ロジック（pagesテーブル更新とrevisionsテーブル挿入をトランザクションで行うなど）は  
  // Durable Object でラップするか、Workers側で複数ステップに分けるなどの検討が必要。  
  // 以下は簡易的なリビジョン挿入例  
  await env.DB.prepare("INSERT INTO revisions (page\_id, content, timestamp, editor, comment) VALUES (?, ?, ?, ?, ?)")  
    .bind(pageId, content, new Date().toISOString(), editor, comment)  
    .run();

  // pages テーブルの最新内容更新も別途必要  
  await env.DB.prepare("UPDATE pages SET content \= ?, updated\_at \= ? WHERE id \= ?")  
    .bind(content, new Date().toISOString(), pageId)  
    .run();  
}

// src/data/cacheRepository.ts (KV アクセス例)  
import { KVNamespace } from "@cloudflare/workers-types";

interface Env {  
  CACHE: KVNamespace;  
}

const PAGE\_CACHE\_PREFIX \= "page:";

export async function getCachedPage(env: Env, title: string): Promise\<string | null\> {  
  return env.CACHE.get(PAGE\_CACHE\_PREFIX \+ title);  
}

export async function putCachedPage(env: Env, title: string, content: string, expirationTtl?: number): Promise\<void\> {  
  await env.CACHE.put(PAGE\_CACHE\_PREFIX \+ title, content, { expirationTtl });  
}

export async function deleteCachedPage(env: Env, title: string): Promise\<void\> {  
  await env.CACHE.delete(PAGE\_CACHE\_PREFIX \+ title);  
}

// src/data/fileRepository.ts (R2 アクセス例)  
import { R2Bucket } from "@cloudflare/workers-types";

interface Env {  
  BUCKET: R2Bucket;  
}

export async function uploadFile(env: Env, key: string, data: ArrayBuffer | ReadableStream | Blob | File, contentType?: string): Promise\<R2Object | null\> {  
  const object \= await env.BUCKET.put(key, data, {  
    // contentType はアップロードするファイルの種類に応じて設定  
    contentType: contentType || 'application/octet-stream',  
  });  
  return object; // object.body で ReadableStream として取得可能  
}

export async function downloadFile(env: Env, key: string): Promise\<R2ObjectBody | null\> {  
  const object \= await env.BUCKET.get(key);  
  return object; // object.body で ReadableStream として取得可能  
}

### **Cline 変換コードのサンプル (概念)**

元のPerlコード:  
sub format\_wiki\_text {  
    my ($text) \= @\_;  
    \# 簡易的な整形処理の例  
    $text \=\~ s/'''(.\*?)'''/\<b\>$1\<\\/b\>/g; \# 太字変換  
    $text \=\~ s/''(.\*?)''/\<i\>$1\<\\/i\>/g;   \# 斜体変換  
    return $text;  
}

Clineによる変換出力 (想定されるTypeScriptの一部):  
// cline\_output/formatService.ts (Cline変換 \+ 手動修正)

// 元Perl関数のシグネチャを模倣しつつ、TypeScriptの型を追加  
export function format\_wiki\_text(text: string): string {  
    let processedText \= text;

    // Perlの正規表現変換をTypeScriptのString.prototype.replaceに置き換え  
    // Clineがこの変換を自動で行うか、手動で修正  
    processedText \= processedText.replace(/'''(.\*?)'''/g, '\<b\>$1\</b\>'); // 太字変換  
    processedText \= processedText.replace(/''(.\*?)''/g, '\<i\>$1\</i\>');   // 斜体変換

    // より複雑なFreestyleWikiマクロなどは、Workers環境で動作するJavaScriptロジックに  
    // 手動で書き換えるか、Clineの変換能力に依存

    return processedText;  
}
