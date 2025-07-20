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
