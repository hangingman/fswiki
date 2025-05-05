import { parseWikiText } from './renderService';

// data/Help%252FFSWiki.wiki の内容をここに貼り付けます
const testWikiText = `!FSWikiとは
FSWikiは、FreestyleWikiをベースに開発されたWikiクローンです。

!!特徴
* 軽量で高速に動作します。
* プラグインによる機能拡張が可能です。
* テキスト整形ルールが豊富です。

!!基本的な使い方
テキストを記述するだけで、自動的に整形されます。

'''太字'''、''斜体''、__下線__、==取り消し線==などのインライン書式が利用できます。

[[ページ名]]で他のページへのリンクを作成できます。
[[表示名|ページ名]]で表示名付きのリンクを作成できます。
[表示名|URL]で表示名付きのURLリンクを作成できます。

---

// コメント行は無視されます。
// これはコメントです。

""引用文は二重引用符で囲みます。""

:説明リストの用語::説明文
::複数行の説明文も記述できます。
:::さらに複数行の説明文。

,テーブルのセル1,テーブルのセル2
,セル3,セル4

{{プラグイン名}}
{{プラグイン名(引数)}}
{{プラグイン名(引数1,引数2)}}

{{#block
ブロックプラグインの内容
複数行にわたる場合
}}

`;

console.log("Running parseWikiText test...");
parseWikiText(testWikiText);
console.log("parseWikiText test finished. Check console logs for parsing output.");
