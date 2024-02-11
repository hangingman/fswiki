# 使用例

Deno をインストールした後、このプロジェクトのスクリプト/モジュールを使用できるようになります。

## CLI

このプロジェクトには、次のように実行できる CLI モジュールが付属しています。
ターミナル。

```console
$ deno runindex.ts --config tsconfig.json --name "friend"
Hello, friend!
```

これはバイナリ実行可能ファイルにコンパイルすることもできます - 詳細については [docs](/docs/) を参照してください。
使い方について。

また、単一のコマンドを使用して Deno パッケージを CLI ツールとしてインストールできるように指示を追加することもできます。 これらの [CLI ツール][] の手順を参照してください。

[CLI ツール]: https://michaelcurrin.github.io/dev-cheatsheets/cheatsheets/javascript/deno/cli/install-cli-tool.html

### 注記

これを使用してツール、ゲーム、または REST API を作成することができます。

ただし、「ドキュメント」や「ドキュメント」の操作など、JavaScript に関するフロントエンド機能を使用していない場合は、
ウェブサイトを作成する場合、JavaScript と Deno (または Node) の代わりに、
ブラウザではなくサーバー側で実行される別の言語を使用します。

_Go_ 言語は、C++ や Rust ほど低レベルではなく、パフォーマンスとタイプ セーフの点で優れています。 Python はその簡単さで素晴らしいです
学び、取り組む - そして
[JS ワット？！](https://github.com/MichaelCurrin/learn-to-code/blob/master/en/topics/scripting_langages/JavaScript/wat.md) の問題を回避していきましょう。

## ブラウザ

このプロジェクトは、Deno で TypeScript モジュールをバンドルできるようにセットアップされています。
単一の JS ファイル。 これは、Web アプリのブラウザーで実行できます。

[public](/public/) ディレクトリを見ると、JS ファイルが
タイプを「module」として設定した「script」タグを使用してブラウザにロードされます。

詳細については、[使用法](https://github.com/MichaelCurrin/deno-project-template/blob/main/docs/usage.md) ドキュメントを参照してください。