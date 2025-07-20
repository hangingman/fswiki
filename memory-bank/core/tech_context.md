# 技術コンテキスト

このドキュメントでは、FSWikiプロジェクトで使用されている主要な技術要素と、`cpanfile` に記載されている主要なPerlモジュールの役割について説明します。

## 主要なPerlモジュールとその役割

*   **Starman**:
    *   PSGI (Perl Web Server Gateway Interface) アプリケーションを実行するための高速なPerl HTTPサーバー。本番環境でのアプリケーション実行に使用されます。
*   **Server::Starter**:
    *   ソケットの引き渡しをサポートする汎用的なサーバー起動ツール。アプリケーションのゼロダウンタイムデプロイや、複数のワーカープロセスの管理に利用されます。
*   **Plack::Middleware::Session**:
    *   Plackアプリケーションでセッション管理機能を提供するミドルウェア。ユーザーの状態を維持するために使用されます。
*   **Plack::Middleware::CSRFBlock**:
    *   PlackアプリケーションでCSRF (Cross-Site Request Forgery) 攻撃からの保護を提供するミドルウェア。セキュリティ強化のために使用されます。
*   **Plack::Middleware::ReverseProxy**:
    *   リバースプロキシ環境下で、クライアントの実際のIPアドレスを正しく取得するためのPlackミドルウェア。
*   **DBI**:
    *   Perlのデータベース独立インターフェース。様々なデータベース（MySQL, PostgreSQLなど）に統一された方法でアクセスするためのAPIを提供します。
*   **DBD::mysqlPP**:
    *   DBIを通じてMySQLデータベースに接続するためのドライバー。
*   **HTML::Template**:
    *   PerlでHTMLテンプレートを扱うためのモジュール。フロントエンドのレンダリングに使用されます。
*   **UUID::Tiny**:
    *   UUID (Universally Unique Identifier) を生成するためのモジュール。セッションIDの生成などに使用されます。
*   **JSON**:
    *   JSONデータのエンコード/デコードを行うためのモジュール。API通信やデータ保存に利用される可能性があります。
*   **Archive::Zip**:
    *   ZIPアーカイブの作成、読み込み、操作を行うためのモジュール。ファイルの圧縮・解凍機能に利用される可能性があります。
*   **LWP (libwww-perl)**:
    *   PerlでWebコンテンツを取得するためのライブラリ群。外部リソースへのアクセスなどに使用されます。
*   **Algorithm::Diff**:
    *   2つのデータセット間の差分（diff）を計算するためのモジュール。Wikiの変更履歴表示などに利用される可能性があります。

## FSWikiコアモジュールAPIリファレンス

FSWikiのコア機能を提供する主要なPerlモジュールのAPIリファレンスは、`docs/API/` ディレクトリにHTML形式で生成されています。これらのドキュメントは、`makedoc.pl` スクリプトによってPerlモジュールのPOD（Plain Old Documentation）から自動生成されたものです。

*   **Wiki.pm**: FSWikiの主要なAPIを提供します。ページ操作、ユーザー管理、プラグイン管理、URL生成など、Wikiの核となる機能のほとんどがこのモジュールに集約されています。
    *   [詳細APIリファレンス (docs/API/Wiki.pm.html)](/docs/API/Wiki.pm.html)
*   **Util.pm**: FSWiki全体で使用されるユーティリティ関数群を提供します。URLエンコード/デコード、HTMLエスケープ、設定ファイルの読み書き、メール送信など、様々な補助機能が含まれます。
    *   [詳細APIリファレンス (docs/API/Util.pm.html)](/docs/API/Util.pm.html)
*   **Wiki::Parser.pm**: Wikiフォーマットの文字列をパースし、書式に対応したフックメソッドの呼び出しを行います。Wiki::Parserを継承し、これらのフックメソッドをオーバーライドすることで任意のフォーマットへの変換が可能です。
    *   [詳細APIリファレンス (docs/API/Parser.pm.html)](/docs/API/Parser.pm.html)

これらのAPIドキュメントは、FSWikiの内部動作を理解し、プラグイン開発などを行う上で非常に重要です。