# fswiki Cloudflare Workers Migration

FreestyleWikiのCloudflare Workersへの移植プロジェクトです。

## ドキュメント

プロジェクトに関する詳細なドキュメントは、`memory-bank` ディレクトリ以下に格納されています。
特に、プロジェクトの概要、製品コンテキスト、システムパターン、技術コンテキスト、現在の状況、進捗状況、および詳細な運用ルールについては、`memory-bank/core` ディレクトリ内のMarkdownファイルを参照してください。

## Cloudflare Workers Local Development

Cloudflare Workers環境でのローカル開発環境を構築し、Workerを起動する方法を説明します。

asdfを使用したNode.jsのインストール:
------------------------------------
プロジェクトではasdfを使用してNode.jsのバージョンを管理します。

1. asdfにnodejsプラグインを追加します (既にインストール済みの場合はスキップ)。
```sh
asdf plugin add nodejs
```

2. プロジェクトで使用するNode.jsのバージョンをインストールします (例: 22.13.1)。
```sh
asdf install nodejs 22.13.1
```

3. プロジェクトのルートディレクトリに`.tool-versions`ファイルを作成し、使用するNode.jsのバージョンを指定します。
```
nodejs 22.13.1
```

wrangler CLIツールのインストール:
---------------------------------
Cloudflare Workersの開発にはwrangler CLIツールを使用します。プロジェクトのローカル依存としてインストールします。
```sh
npm install --save-dev wrangler
```


ローカル開発サーバーの起動:
--------------------------
以下のコマンドでローカル開発サーバーを起動し、Workerの動作を確認できます。
```sh
npx wrangler dev
```
ブラウザで `http://localhost:8787` にアクセスしてください。
