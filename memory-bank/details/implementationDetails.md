## FSWikiの機能 (TypeScript実装)

FreestyleWikiのTypeScript移植版では、元のPerl版の主要な機能とインターフェースを維持しつつ、TypeScriptとCloudflare Workersの特性を活かした設計を行います。

### 文法

FreestyleWiki独自のWiki文法は、TypeScriptで実装されるパーサーによって解析され、HTMLに変換されます。バージョン3.5.3以降でサポートされた他の文法（YukiWiki、Hiki）についても、対応するパーサーモジュールをTypeScriptで実装または移植することでサポートを維持します。プラグイン記法はFSWikiのものを基本としますが、TypeScriptのプラグインシステムに合わせてインターフェースを調整します。

### 特殊なページ名

以下の特殊なページ名は、TypeScriptのルーティングおよびデータ取得ロジックで特別扱いされます。

*   **Header, Footer, Menu**: これらのページの内容は、ページのレンダリング時に取得され、共通のヘッダ、フッタ、サイドバーとして組み込まれます。
*   **EditHelper**: ページの作成・編集画面を表示する際に、このページの内容を取得し、編集ヘルプとして表示します。
*   **Template/ で始まるページ**: 新規ページ作成時にテンプレートとして選択肢に表示されるよう、`Template/`プレフィックスを持つページを識別します。

### テーマ

tDiaryテーマのサポートは、TypeScriptのテンプレートエンジンやフロントエンドのレンダリングロジックに組み込む形で実現します。テーマファイル（CSSなど）はR2に配置し、Workersから提供することを検討します。管理画面でのテーマ選択機能もTypeScriptで実装します。

### サイトテンプレート

HTML::Templateを使用したサイトテンプレート機能は、TypeScriptで別のテンプレートエンジン（例: EJS, Handlebars）を使用するか、WorkersでのHTML生成ロジックとして再実装します。テンプレートファイルはR2またはKVに配置し、動的に読み込んで使用します。管理画面でのサイトテンプレート選択機能もTypeScriptで実装します。

### 管理画面

管理画面は、認証された管理者ユーザーのみがアクセスできるTypeScriptで実装された一連のHTTPハンドラとして提供されます。ユーザー管理、Wiki設定変更、ページ管理（凍結、削除）などの機能を含みます。認証・認可はCloudflare Workersの環境と連携して行います。

### プラグイン

FreestyleWikiの拡張性の核となるプラグインシステムは、TypeScriptで再設計します。プラグインはTypeScriptモジュールとして実装され、Workersの起動時にロードまたは動的にインポートされる仕組みを検討します。管理画面でのプラグイン有効/無効設定機能も移植します。

### WikiFarmの利用について

WikiFarm機能は、単一のWorkersスクリプトで複数のWikiサイトをホストする機能として実現します。ルーティングロジックでWikiサイトを識別し、D1データベース内でサイトごとにデータを分離して管理する設計が必要です。

## プラグイン開発 (TypeScript)

TypeScriptでのプラグイン開発は、明確に定義されたインターフェースに基づき行われます。

### プラグインの構造と登録

プラグインは通常、特定のインターフェースを実装するクラスまたは関数として定義されます。プラグインの登録は、Workersの起動スクリプト内で、中央のプラグインマネージャーオブジェクトに対して行います。

```typescript
// 例: アクションハンドラの登録
import { WikiPluginManager } from './pluginManager';
import { EditPageHandler } from './plugins/EditPageHandler';

const pluginManager = new WikiPluginManager();
pluginManager.addHandler('EDIT', new EditPageHandler());
```

Perl版の`install`メソッドに相当する初期化ロジックは、TypeScriptプラグインのコンストラクタや初期化関数で行います。

### アクションハンドラ

`IActionHandler`のようなインターフェースを実装します。`handle`メソッドは`Request`オブジェクトを受け取り、`Response`オブジェクトを返します。

```typescript
interface IActionHandler {
  handle(request: Request, env: Env, ctx: ExecutionContext): Promise<Response>;
}

class EditPageHandler implements IActionHandler {
  async handle(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    // 編集画面表示ロジック
    return new Response('編集画面');
  }
}
```

### フックプラグイン

`IHookPlugin`のようなインターフェースを実装します。`execute`メソッドはフック名と関連データを引数に取ります。

```typescript
interface IHookPlugin {
  execute(hookName: string, data: any): Promise<void>;
}

class SaveBeforeHook implements IHookPlugin {
  async execute(hookName: string, data: any): Promise<void> {
    if (hookName === 'save_before') {
      // 保存前処理
    }
  }
}
```

### インライン/パラグラフ/ブロックプラグイン

Wikiテキストのパース時に呼び出される関数またはクラスメソッドとして実装します。パーサーはプラグインの記法を検知すると、対応するプラグインのメソッドを呼び出し、返されたHTMLフラグメントやWikiテキストを結果に組み込みます。

```typescript
interface IInlinePlugin {
  render(args: string[], wikiContext: WikiContext): Promise<string>; // HTMLまたはWikiテキストを返す
}

class SimplePlugin implements IInlinePlugin {
  async render(args: string[], wikiContext: WikiContext): Promise<string> {
    return `<b>Args: ${args.join(', ')}</b>`;
  }
}
```

### エディットフォームプラグイン

編集画面のレンダリング時に呼び出され、追加のHTMLフォーム要素などを生成する関数またはクラスメソッドとして実装します。

```typescript
interface IEditFormPlugin {
  render(pageData: PageData, wikiContext: WikiContext): Promise<string>; // HTMLフラグメントを返す
}
```

### フォーマットプラグイン

異なるWiki記法間の変換ロジックを持つクラスとして実装します。`convertToFswiki`, `convertFromFswiki`などのメソッドを持ちます。

```typescript
interface IFormatPlugin {
  name: string;
  convertToFswiki(text: string): string;
  convertFromFswiki(text: string): string;
  // インライン変換メソッドなども含む
}
```

### メニューアイテム

メニューアイテムの追加は、プラグインまたはコアコードから、メニューマネージャーオブジェクトに対して行います。メニューマネージャーは、登録されたアイテムに基づいてナビゲーションHTMLを生成します。

```typescript
interface IMenuItem {
  label: string;
  url: string;
  order: number;
  isAdmin?: boolean; // 管理者メニューかどうか
}

// メニューアイテムの登録
pluginManager.addMenuItem({ label: '新しい機能', url: '/new-feature', order: 10 });
pluginManager.addMenuItem({ label: '管理者設定', url: '/admin/settings', order: 20, isAdmin: true });
```

## TypeScriptでのインターフェース設計

FreestyleWikiの移植版では、以下の主要なインターフェースやクラスを設計します。

- `WikiContext`: 現在のリクエスト、環境変数、D1/KV/R2バインディング、認証情報などを保持するコンテキストオブジェクト。
- `PageData`: Wikiページのタイトル、本文、リビジョン情報などを保持するデータ構造。
- `DatabaseService`: D1データベースへのアクセスを抽象化するサービス。
- `CacheService`: KVへのアクセスを抽象化するサービス。
- `StorageService`: R2へのアクセスを抽象化するサービス。
- `Parser`: Wikiテキストを解析し、中間表現またはHTMLを生成するクラス。
- `Renderer`: 中間表現またはパース結果から最終的なHTMLを生成するクラス。
- `PluginManager`: プラグインの登録、検索、実行を管理するクラス。
- 各プラグインタイプのインターフェース (`IActionHandler`, `IHookPlugin`, `IInlinePlugin`など)。

これらのインターフェースとクラスを適切に設計することで、コードのモジュール性とテスト容易性を高め、将来的な機能拡張やメンテナンスを容易にします。
