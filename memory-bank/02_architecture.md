# アーキテクチャの文書化

FSWikiアプリケーションの主要なコンポーネントとその関係性を以下に示します。

## 概要

FSWikiはPerlで書かれたWikiアプリケーションであり、`Starman` と `Plack` を利用して動作します。データストアとしてMySQL互換データベースを使用します。

## コンポーネント図

```mermaid
graph TD
    A[クライアント (Webブラウザ)] --> B(Webサーバー);
    B --> C{Perlアプリケーション};
    C --> D[データベース];

    subgraph Webサーバー
        B1(Server::Starter)
        B2(Starman)
    end

    subgraph Perlアプリケーション
        C1(Plack)
        C2(WikiApplication.pm)
        C3(Wiki.pm)
        C4(プラグイン/テーマ)
    end

    subgraph データベース
        D1(MySQL互換DB)
    end

    B1 -- プロセス管理 --> B2;
    B2 -- PSGIインターフェース --> C1;
    C1 -- リクエスト処理 --> C2;
    C2 -- コア機能呼び出し --> C3;
    C3 -- データアクセス --> D1;
    C3 -- 機能拡張 --> C4;
```

## 各コンポーネントの説明

*   **クライアント (Webブラウザ):** ユーザーがFSWikiにアクセスし、コンテンツを閲覧・編集するためのインターフェースです。
*   **Webサーバー:**
    *   **Server::Starter:** アプリケーションプロセスの起動、停止、再起動を管理し、リクエストをワーカープロセスに分散します。
    *   **Starman:** PSGI (Perl Web Server Gateway Interface) アプリケーションを実行するための高速なPerl HTTPサーバーです。
*   **Perlアプリケーション:**
    *   **Plack:** PSGIアプリケーションを実行するためのフレームワークです。`app.psgi` がエントリポイントとなり、ミドルウェア（セッション管理、CSRF保護など）を提供し、リクエストをアプリケーション本体にルーティングします。
    *   **WikiApplication.pm:** `app.psgi` から呼び出される主要なPSGIアプリケーションモジュールです。`Wiki.pm` のインスタンスを初期化し、リクエストの処理フロー（ユーザー認証、プラグインのロード、アクションハンドラの呼び出し、HTMLレンダリングなど）を統括します。
    *   **Wiki.pm:** FSWikiのコア機能を提供するモジュールです。設定管理、ユーザー認証・認可、多様なプラグインの管理、Wikiコンテンツの処理（ページの取得、保存、存在チェックなど）、URL生成、そしてマルチWiki（ファーム）機能まで、広範な機能を提供します。データ永続化の責務は `Wiki::DefaultStorage` などのストレージモジュールに委譲しています。
    *   **プラグイン/テーマ:** FSWikiの機能を拡張したり、見た目をカスタマイズしたりするためのモジュールです。`Wiki.pm` を通じてロードされ、アプリケーションの様々な処理にフックしたり、特定のアクションを処理したりします。
*   **データベース:** Wikiのページコンテンツ、ユーザー情報、設定などの永続データを格納します。現在はMySQL互換データベース（将来的にはTiDB Cloud）を使用します。

## ディレクトリ構造

FSWikiプロジェクトの主要なディレクトリ構造は以下の通りです。

```
.
├── アプリケーションコアファイル
│   ├── app.psgi
│   ├── cpanfile
│   ├── Procfile
│   ├── setup.dat
│   ├── setup.sh
│   └── wikidb.cgi
├── 設定・データ関連
│   ├── config/
│   ├── data/
│   │   ├── favicon.ico
│   │   └── favicon.png
│   └── log/
├── ドキュメント・ガイドライン
│   ├── AGENTS.md
│   ├── GEMINI.md
│   ├── README.md
│   ├── docs/
│   │   ├── changes.html
│   │   ├── default.css
│   │   ├── gpl.txt
│   │   ├── makedoc.bat
│   │   ├── makedoc.sh
│   │   └── API/
│   │       ├── makedoc.bat
│   │       ├── makedoc.pl
│   │       ├── makedoc.sh
│   │       ├── Parser.pm.html
│   │       ├── Util.pm.html
│   │       └── Wiki.pm.html
│   └── memory-bank/
│       ├── 01_project_overview.md
│       ├── 02_architecture.md
│       ├── 03_development_guide.md
│       ├── 04_testing_guide.md
│       ├── 05_coding_guidelines.md
│       ├── 06_git_workflow.md
│       ├── 07_ai_workflow.md
│       ├── 08_conversation_guidelines.md
│       ├── basic_guidelines.md
│       ├── core/
│       │   ├── data_flow.md
│       │   ├── project_brief.md
│       │   ├── system_patterns.md
│       │   └── tech_context.md
│       └── details/
│           ├── implementation_details.md
│           └── technical_notes.md
├── モジュール・プラグイン・テーマ
│   ├── lib/
│   │   ├── CGI2.pm
│   │   ├── PDFJ.pm
│   │   ├── Util.pm
│   │   ├── Wiki.pm
│   │   ├── WikiApplication.pm
│   │   └── Wiki/
│   │       ├── DefaultStorage.pm
│   │       ├── HTMLParser.pm
│   │       ├── InterWiki.pm
│   │       ├── Keyword.pm
│   │       └── Parser.pm
│   ├── plugin/
│   │   ├── access/
│   │   ├── accesslog/
│   │   ├── admin/
│   │   │   ├── AccountHandler.pm
│   │   │   ├── AdminConfigHandler.pm
│   │   │   ├── AdminDeletedPageHandler.pm
│   │   │   ├── AdminLogHandler.pm
│   │   │   ├── AdminPageHandler.pm
│   │   │   ├── AdminPluginHandler.pm
│   │   │   ├── AdminSpamHandler.pm
│   │   │   ├── AdminStyleHandler.pm
│   │   │   ├── AdminUserHandler.pm
│   │   │   ├── DeleteCache.pm
│   │   │   ├── Install.pm
│   │   │   ├── Login.pm
│   │   │   ├── PermissionForm.pm
│   │   │   └── UserRegisterHandler.pm
│   │   ├── admin_export/
│   │   ├── amazon/
│   │   ├── attach/
│   │   ├── bbs/
│   │   ├── book/
│   │   ├── bookmarks/
│   │   ├── bugtrack/
│   │   ├── calendar/
│   │   ├── category/
│   │   ├── comment/
│   │   ├── core/
│   │   ├── dbi/
│   │   ├── editlog/
│   │   ├── footnote/
│   │   ├── format/
│   │   ├── google/
│   │   ├── gtex/
│   │   ├── include_html/
│   │   ├── info/
│   │   ├── layout/
│   │   ├── loginstate/
│   │   ├── mathjax/
│   │   ├── mimetex/
│   │   ├── pdf/
│   │   ├── recent/
│   │   ├── rename/
│   │   ├── rss/
│   │   ├── search/
│   │   ├── sitemap/
│   │   ├── todo/
│   │   └── vote/
│   ├── theme/
│   │   ├── blue_pipe/
│   │   ├── default/
│   │   ├── kati/
│   │   ├── kugi01/
│   │   └── resources/
│   └── tmpl/
│       ├── admin_config.tmpl
│       ├── admin_layoutalias.tmpl
│       ├── admin_layoutkey.tmpl
│       ├── admin_spam.tmpl
│       ├── admin_style.tmpl
│       ├── bbs.tmpl
│       ├── bugtrack.tmpl
│       ├── comment.tmpl
│       ├── editform.tmpl
│       ├── footer.tmpl
│       ├── header.tmpl
│       ├── login.tmpl
│       ├── redirect.tmpl
│       ├── layout/
│       └── site/
├── ビルド・デプロイ・ユーティリティ
│   ├── .editorconfig
│   ├── .gitignore
│   ├── .perl-version
│   ├── Makefile
│   ├── release.sh
│   ├── ansible/
│   │   ├── ansible-playbook.sh
│   │   ├── ansible.cfg
│   │   ├── fswiki-playbook.yml
│   │   ├── local
│   │   ├── production
│   │   ├── requirements.yml
│   │   ├── environments/
│   │   │   └── prod/
│   │   ├── group_vars/
│   │   │   └── all.yml
│   │   └── roles/
│   │       ├── fswiki/
│   │       ├── fswiki_common/
│   │       └── fswiki_webserver/
│   ├── docker/
│   │   ├── centos/
│   │   │   └── Dockerfile
│   │   └── debian/
│   │       └── Dockerfile
│   ├── docker-compose.yml
│   └── tools/
│       ├── default.css
│       ├── sample.bat
│       ├── wiki2html.pl
│       └── wiki2pdf.pl
├── その他
│   ├── .gemini/
│   │   └── extensions/
│   │       └── github/
│   ├── .git/
│   ├── .vscode/
│   │   └── settings.json
│   ├── get_accesslog.cgi
│   └── LogSearch.js
```