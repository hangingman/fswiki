# 技術ノート

このドキュメントは、FSWikiプロジェクトにおける技術的な調査、決定、および重要な変更履歴を記録します。

## 変更履歴 (docs/changes.html より)

FSWikiのリリース履歴と主要な変更点は、`docs/changes.html` に詳細に記録されています。このファイルは、プロジェクトの進化と機能追加の経緯を理解する上で非常に有用です。

### 主要な変更点の概要

*   **2010/08/28 - Version 3.6.4:** Perl 5.10での文字化け修正、インライン書式のネスト対応、高速化、管理画面フック追加。
*   **2008/12/14 - Version 3.6.3:** 添付ファイルの上書き制限、ページ内容フィルタリング、ユーザー登録機能、HTML出力修正、インデックスファイル作成、複数行プラグインサポート、HTMLキャッシュ削除。
*   **2006/05/13 - Version 3.6.0:** インライン書式のネスト対応、差分表示の改善、バージョン復元機能、サイト全体の参照権限設定、ページ名コロン使用の柔軟化、タイムゾーン設定、MIMEタイプ設定ファイル指定、更新通知メールの複数アドレス対応、katiテーマ追加、バグフィックス。
*   **2005/12/04 - Version 3.5.10:** Farm作成時のテンプレート機能、ページリンク表示設定、新規作成ページ参照権限設定、mod_perlでのメモリリーク修正、Wiki#exit()のオーバーライド、外部リンク処理の修正、バグフィックス。
*   **2005/08/27 - Version 3.5.9:** 初期設定スクリプト同梱、PDFプラグインの数値リスト修正、attachプラグインのダウンロードカウンタ記録、管理画面のページ管理フィルタリング、Wiki.pmにadd_head_info()追加、rssプラグインのRSS Auto Discovery対応。
*   **2004/04/10 - Version 3.5.3:** フォーマットプラグイン導入（Hiki, YukiWiki対応）、HTMLキャッシュ機能、世代バックアップ機能、Tarでの一括バックアップ、管理画面からのリダイレクト設定、Locationヘッダでのリダイレクト、参照権限のないページへのNOARCHIVE METAタグ出力、携帯電話対応、プレビュー時のsageチェック引き継ぎ、高速化、フッタにPerlバージョンとmod_perl動作表示、mod_perlでのメモリリーク解消。
*   **2003/02/22 - Version 3.2.0:** パーサの全面書き換え、includeプラグイン追加、新規作成・編集禁止設定、管理者ログイン機能、AND/OR検索対応。

より詳細な変更履歴は、以下のファイルを参照してください。

[docs/changes.html](/docs/changes.html)

## Docker環境におけるPerlの複数バージョン問題と解決策

### 根本原因の再確認

問題の核心は、**Dockerイメージ内に2つの異なるバージョンのPerlが共存していること**、そして**アプリケーションサーバー（Starman）の起動スクリプトが、意図しない古い方のPerl（`/usr/bin/perl` v5.36.0）を明示的に指定してしまっていること**にあります。

  * **意図した環境**: `Dockerfile` で `FROM perl:5.38` を指定したことで導入された **Perl 5.38.4** (`/usr/local/bin/perl`)
  * **実際に使用された環境**: DebianのOSにデフォルトで含まれている **Perl 5.36.0** (`/usr/bin/perl`)

`carton install` でインストールされた `DBD::mysql` などのモジュールはPerl 5.38.4の管理下に置かれます。しかし、Starmanが古いPerl 5.36.0で起動されるため、そのモジュールパス（`@INC`）には5.38.4用のディレクトリが含まれず、「Can't locate DBD/mysql.pm」エラーが発生します。

### 解決策

この問題を解決するには、アプリケーションが常に意図したPerlバージョン（この場合は5.38.4）で実行されるように起動方法を修正します。以下にいくつかの具体的な解決策を提示します。

#### 1. Shebangを `#!/usr/bin/env perl` に変更する（推奨）

`carton` や `starman` の実行スクリプトのShebang（1行目の `#!...`）を修正するのが最もクリーンでポータブルな解決策です。

  * **変更前**: `#!/usr/bin/perl`
  * **変更後**: `#!/usr/bin/env perl`

`#!/usr/bin/env perl` は、環境変数 `PATH` を検索して最初に見つかった `perl` を使用します。Fly.ioのコンテナ環境では `/usr/local/bin` が `/usr/bin` より優先されるため、これにより自動的に `/usr/local/bin/perl` (v5.38.4) が選択されるようになります。

ローカルの `cpanfile.snapshot` や `local/` ディレクトリにあるスクリプトのShebangを修正してください。

#### 2. 実行コマンドで明示的にPerlを指定する

Shebangを直接編集できない場合や、より確実に制御したい場合は、`fly.toml` の `[processes]` (またはDockerfileの `CMD`) でPerlインタープリタを明示的に指定してスクリプトを起動します。

`carton` が管理する `PATH` を利用して `starman` を見つける `-S` オプションと組み合わせるのが効果的です。

```toml
# fly.toml

[processes]
  # 例
  web = "carton exec -- perl -S starman --port $PORT --workers 3 app.psgi"
```

このコマンドは、まず `carton` が設定した環境下で、`PATH` の通った `perl` (つまりv5.38.4) を使って、同じく `PATH` から `starman` スクリプトを探して実行します。これにより、Shebangの設定に依存せず、常に正しいPerlで起動できます。

#### 3. Dockerfileでシンボリックリンクを張る

Dockerfile内で、システムのPerlを新しいPerlへのシンボリックリンクで上書きする方法もあります。これはやや強引ですが、既存のスクリプトを一切変更したくない場合に有効です。

```dockerfile
# Dockerfile

FROM perl:5.38

# ... (他のRUNコマンドなど) ...

# システムのperlを新しいperlに強制的に差し替える
RUN ln -sf /usr/local/bin/perl /usr/bin/perl

# ... (以降のビルドステップ) ...
```

この方法を取ることで、`#!/usr/bin/perl` というShebangを持つすべてのスクリプトが、自動的に `/usr/local/bin/perl` を使うようになります。

## Docker Compose環境における環境変数の上書き問題と解決策

### 問題点

`docker-compose.yml` の `environment` セクションで定義された環境変数は、`Dockerfile` の `ENV` 命令で設定された環境変数を**上書き**します。

これにより、`Dockerfile` で `ENV PATH=/app/local/bin:$PATH` のように既存のパスに追記する形で定義していたとしても、`docker-compose.yml` の `environment` セクションに `PATH` の記述がない場合、コンテナ実行時には `Dockerfile` で追加したはずの `/app/local/bin` が `PATH` から失われてしまいます。

`PERL5LIB` など、アプリケーションのライブラリ解決に不可欠な他の環境変数についても同様の問題が発生し、結果として「モジュールが見つからない」といったエラーや、意図しないコマンドが実行される原因となります。

### 解決策

この問題を解決するには、`Dockerfile` で定義している重要な環境変数を、`docker-compose.yml` の `environment` セクションに**明示的に再定義**します。

**修正例 (`docker-compose.yml`):**

```yaml
services:
  wiki:
    # ... 他の設定 ...
    environment:
      # アプリケーション固有の環境変数
      - TZ=Asia/Tokyo
      - DB_HOST=mysql
      
      # Dockerfileから転記・再定義する環境変数
      - PERL5LIB=/app/local/lib/perl5:/app/local/lib/perl5/x86_64-linux-gnu
      - PATH=/usr/local/bin:/app/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```

**重要な注意点:**

*   **`PATH` は完全な値を記述する:** `PATH` を再定義する際は、`$PATH` のような変数は展開されないため、コンテナのデフォルトパスと `Dockerfile` で追加したパスをすべて含んだ、完全な文字列を記述する必要があります。
*   **開発環境と本番環境の両方を確認する:** `docker-compose.dev.yml` のような開発環境用のファイルが存在する場合は、そちらにも同様の修正が必要です。

この対応により、`docker compose` 経由で起動した場合でも、コンテナは常に期待された環境変数を持って動作することが保証され、開発環境と本番環境の挙動の差異をなくし、安定したアプリケーション実行環境を構築できます。
