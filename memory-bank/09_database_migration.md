# FSWikiデータ移行ガイド: ファイルからTiDBへ

## 1. 目的

このドキュメントは、FSWikiのデータストレージを従来のファイルベースシステムから、スケーラブルなクラウドデータベースであるTiDBへ移行するための手順と技術的な考慮事項をまとめたものです。

## 2. 背景

FSWikiは当初、データをファイルシステム上に保存する設計でした。しかし、コミュニティの貢献により、PerlのデータベースインターフェースであるDBIを介して、リレーショナルデータベースをバックエンドとして利用する機能が追加されました (PR #7, Issue #16)。

- **DBI対応の経緯:** `plugin/dbi/StandardDatabaseStorage.pm` は、元々SQLiteをターゲットとして開発されました。しかし、その後の改修により、MySQLなどの他のデータベースにも対応できるような拡張性が考慮されています。
- **既存の移行ツール:**
    - `wikidb.cgi`: SQLiteデータベースの作成と、ファイルからのデータ移行を行うための初期ツールです。
    - `admin_export` プラグイン (PR #36): 管理画面からWikiのデータをzip形式でエクスポートする機能を提供します。

これらの既存機能を活用し、最新のクラウド環境であるFly.ioとTiDB Cloudへ対応させることが、本移行プロジェクトの目標です。

## 3. 移行戦略

移行は以下のステップで進めます。

1.  **`StandardDatabaseStorage.pm` のTiDB対応:** 既存のストレージモジュールを、TiDB Cloudの接続情報（MySQL互換）で動作するように修正します。
2.  **ローカル開発環境の整備:** `docker-compose.yml` にDBコンテナ（MySQL/MariaDB）を追加し、ローカルでDBバックエンドの動作を検証できる環境を構築します。
3.  **データのエクスポート:** `admin_export` プラグインを利用して、既存のファイルベースのデータをエクスポートします。
4.  **データのインポート:** エクスポートされたデータをTiDBにインポートするための新しいツールを開発します。
5.  **テスト:** ローカル環境で一連の移行プロセスをテストし、データの整合性を確認します。
6.  **本番環境への適用:** テスト済みの手順書に基づき、Fly.io上の本番環境をTiDBバックエンドに切り替えます。

## 4. 具体的な実装手順

### 4.1. `StandardDatabaseStorage.pm` の修正

`get_connection` メソッドを修正し、環境変数からTiDBの接続情報を読み込めるようにします。これにより、SQLiteとMySQL/TiDBの両方に対応可能になります。

**修正前 (SQLite):**
```perl
my $db_conn = "dbi:".$self->{db_driver}.":".$self->{db_dir}.$farm.'/'.$self->{db_name};
$hDB = DBI->connect($db_conn,$self->{db_user},$self->{db_pass},{PrintError=>1});
```

**修正後 (TiDB/MySQL対応):**
```perl
my $dbdriver = $self->{db_driver};
my $dsn;
if ($dbdriver eq 'mysql') {
    my $dbname = $self->{db_name};
    my $dbhost = $self->{db_host};
    my $user = $self->{db_user};
    my $pass = $self->{db_pass};
    $dsn = "dbi:$dbdriver:database=$dbname;host=$dbhost";
    $hDB = DBI->connect($dsn, $user, $pass, {PrintError=>0});
} else { # SQLite
    my $db_conn = "dbi:$dbdriver:".$self->{db_dir}.$farm.'/'.$self->{db_name};
    $hDB = DBI->connect($db_conn,$self->{db_user},$self->{db_pass},{PrintError=>1});
}
```
*（注: 上記は概念的なコードです。実際には`setup.dat`や環境変数からの設定読み込みを適切に実装する必要があります）*

### 4.2. ローカル開発環境 (`docker-compose.yml` & `Dockerfile`)

`docker-compose.yml` にMySQLサービスを追加し、`wiki`サービスから接続できるように設定します。

```yaml
services:
  mysql:
    image: mysql:8.0
    platform: linux/amd64
    environment:
      MYSQL_ROOT_PASSWORD: password
      MYSQL_DATABASE: fswiki
    ports:
      - "3306:3306"
    volumes:
      - mysql-data:/var/lib/mysql

  wiki:
    build:
      context: .
      dockerfile: docker/debian/Dockerfile
    ports:
      - "5001:8080"
    environment:
      - DB_DRIVER=mysql
      - DB_HOST=mysql
      - DB_NAME=fswiki
      - DB_USER=root
      - DB_PASS=password
    depends_on:
      mysql:
        condition: service_healthy
    volumes:
      - local-deps:/app/local # cartonがインストールするモジュールを保護

volumes:
  mysql-data:
  local-deps: {}
```

**デバッグ中に判明した重要な知見:**

*   **`docker-compose.yml`の`environment`による環境変数の上書き:**
    `docker-compose.yml`の`environment`セクションで`PATH`や`PERL5LIB`のような環境変数を定義すると、`Dockerfile`で設定された同名の環境変数を上書きしてしまい、コンテナ内のPerl実行環境が壊れる問題が発生しました。
    **解決策:** `docker-compose.yml`の`environment`セクションからは、`Dockerfile`で設定されるべき環境変数（`PATH`, `PERL5LIB`など）を削除し、アプリケーション固有の環境変数（`DB_DRIVER`, `DB_HOST`など）のみを記述するようにします。

*   **ボリュームマウントによる`local`ディレクトリの上書き:**
    `docker-compose.yml`の`volumes: - .:/app`という設定は、ホストのカレントディレクトリをコンテナの`/app`にマウントします。この際、`Dockerfile`の`RUN carton install --deployment`でインストールされたモジュールが格納される`/app/local`ディレクトリが、ホスト側の空のディレクトリで上書きされてしまい、`carton`がモジュールを見つけられなくなる問題が発生しました。
    **解決策:** `wiki`サービスの`volumes`に`local-deps:/app/local`を追加し、最下層に`local-deps: {}`を定義することで、`/app/local`ディレクトリを名前付きボリュームとして保護し、ホストからの上書きを防ぎます。

*   **PerlバージョンとXSモジュールのコンパイルバージョン不一致 (`PL_current_context`エラー):**
    `perl:5.38`のDockerイメージを使用しているにも関わらず、`apt`でインストールされる`libdbd-mysql-perl`がPerl 5.36向けにコンパイルされていたため、`PL_current_context`エラーが発生しました。また、`carton`自体がPerl 5.36でビルドされていたため、`carton install`がPerl 5.36向けのモジュールをコンパイルしてしまい、Perl 5.38の環境でロードしようとすると同様のエラーが発生しました。
    **解決策:**
    1.  `cpanfile`から`DBD::mysql`を削除し、`carton`が`DBD::mysql`のインストールに関与しないようにします。
    2.  `Dockerfile`で`cpanm`と`carton`をDebianパッケージからインストールします。
    3.  `Dockerfile`のビルドステップで、`cpanm --force Devel::CheckLib && cpanm DBD::mysql`を実行し、`DBD::mysql`をPerl 5.38環境で直接コンパイル・インストールします。`Devel::CheckLib`のテストが失敗するため、`--force`が必要です。
    4.  その後に`carton install --deployment`を実行し、`cpanfile`に記載された残りの依存関係をインストールします。

*   **`DBD::mysql`のCコンパイルエラー (MySQLクライアントライブラリの不一致):**
    `DBD::mysql`が期待するMySQLクライアントライブラリのバージョンと、コンテナにインストールされていたMariaDBクライアントライブラリ（`libmariadb-dev`）のバージョンに互換性がなく、`MYSQL_OPT_COMPRESSION_ALGORITHMS`などの未定義シンボルエラーが発生しました。
    **解決策:** `Dockerfile`でMySQL公式のAPTリポジトリを追加し、そこから`libmysqlclient-dev`（MySQL 8.0向け）をインストールするように変更しました。これには、`lsb-release`のインストールと、GPGキーの正しいインポート（`signed-by`オプションを使用）が必要でした。

*   **`carton exec`の重要性:**
    Perlスクリプトを実行する際には、`carton exec`を介して実行することが重要です。これにより、`carton`が管理しているモジュールがPerlの検索パス（`@INC`）に自動的に追加され、モジュールが見つからない問題を回避できます。

### 4.3. インポートツールの開発 (`tools/import_to_db.pl`)

`wikidb.cgi` のロジックを参考に、`admin_export` で作成されたzipファイルを展開し、中のデータをDBに登録するCLIツールを開発します。

- **テーブル定義:** `wikidb.cgi` 内の `CREATE TABLE` 文を参考に、MySQL互換のスキーマを定義します。
- **データ登録:** `Archive::Zip` でzipを読み込み、各wikiページのデータを `DBI` を使って `data_tbl` や `attr_tbl` に `INSERT` します。
- **引数:** `tools/import_to_db.pl` は、エクスポートされたzipファイルのパスを引数として受け取ります。例: `carton exec perl tools/import_to_db.pl /app/memory-bank/fswiki-dump-20250721.zip`

## 5. 移行手順のテスト

1.  `docker compose up -d --build` でローカル環境を起動します。
2.  ファイルベースのFSWiki（`storage = Wiki::DefaultStorage`）にアクセスし、テストページをいくつか作成します。
3.  管理画面から `admin_export` を実行し、`export.zip` をダウンロードします。
4.  `setup.dat` の `storage` を `plugin::dbi::StandardDatabaseStorage` に変更します。
5.  `docker compose restart wiki` でFSWikiを再起動します。
6.  開発した `tools/import_to_db.pl` を実行し、`export.zip` をDBにインポートします。
7.  ブラウザでFSWikiにアクセスし、データが正常に表示・編集できることを確認します。

## 6. 今後の課題

-   **スキーマの最適化:** `wikidb.cgi` のスキーマはSQLite向けに設計されているため、TiDBの特性に合わせてインデックスやデータ型を最適化する必要があります。
-   **ダウンタイム:** 本番環境でのデータ移行に伴うダウンタイムを最小限に抑えるための戦略を検討する必要があります。
