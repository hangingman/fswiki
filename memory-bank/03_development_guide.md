## 開発環境のセットアップ

### 前提条件

*   Docker
*   Docker Compose

### セットアップ手順

1.  **Docker環境での開発:**
    *   FSWikiをDocker環境で動作させるための設定を行います。

    *   **`docker/debian/Dockerfile` の設定:**
        `docker/debian/Dockerfile` は、FSWikiアプリケーションをDockerコンテナ内で実行するためのイメージをビルドします。
        このDockerfileは、`perl:5.38` をベースイメージとして使用し、必要なシステムパッケージとPerlモジュールをインストールします。
        特に、`carton install --deployment` を実行することで、`cpanfile.snapshot` に基づいて依存関係を厳密にインストールし、再現可能なビルドを保証します。
        また、イメージサイズを最適化するために、`apt-get install` に `--no-install-recommends` オプションを使用し、ビルド後に不要なaptキャッシュをクリーンアップします。
        最終的に、`Starman` を使用してPSGIアプリケーション (`app.psgi`) をポート `8080` で起動します。

    *   **`docker-compose.yml` の設定:**
        `docker-compose.yml` は、ローカル開発環境でFSWikiアプリケーションを起動するための設定を提供します。
        この設定では、`docker/debian/Dockerfile` を使用して `wiki` サービスをビルドし、ホストのポート `5001` をコンテナのポート `8080` にマッピングします。
        これにより、ブラウザから `http://localhost:5001` でFSWikiにアクセスできるようになります。
        `command` フィールドでは、`plackup` を使用してアプリケーションを起動し、ローカル開発に適した設定（例: 自動リロード機能）を提供します。

    *   **Dockerコンテナのビルドと起動:**
        ```shell
        docker compose down && docker compose up -d --build
        ```

    *   **初期設定の実行:**
        `setup.sh` はCGI環境向けのため、PSGI環境では手動で必要なディレクトリを作成します。
        ```shell
        docker compose exec wiki bash -c "mkdir -p /app/backup /app/attach /app/pdf /app/log /app/data /app/config /app/theme /app/tmpl /app/tools"
        docker compose exec wiki bash -c "touch /app/log/access.log /app/log/attach.log /app/log/freeze.log /app/log/download_count.log"
        ```

    *   **FSWikiへのアクセス:**
        ブラウザから `http://localhost:5001` にアクセスします。

2.  **Perlbrewを使ったローカル実行:**
    ```sh
    # perlbrewの導入
    $ curl -L http://install.perlbrew.pl | bash
    $ echo 'source ~/perl5/perlbrew/etc/bashrc' >> ~/.bashrc
    $ source ~/.bashrc
    $ perlbrew init

    # perl v5.30.2の導入
    $ perlbrew install 5.30.2
    $ perlbrew switch perl-5.30.2
    $ perl -v
    # v5.30.2

    # carton
    $ cpanm Carton
    $ cpanm --local-lib=~/perl5 local::lib
    $ carton install

    # 初回起動の場合(作業ディレクトリを引数で渡す)
    $ ./setup.sh `pwd`

    # Perlのアプリケーションサーバを起動
    $ carton exec plackup -r
    ```

### setup.datの設定

データ保管場所などFreeStyle Wikiの基本的な設定はsetup.datを編集することで行います。

FreeStyle Wikiでは、ページが変更された場合に管理者にメールで通知する機能があります。この機能を有効にするにはsetup.datの設定内容にsendmailのパスかSMTPサーバのホスト名を設定します。

また、デフォルトではバックアップは一世代のみですが、backupというパラメータにバックアップする世代数を指定することができます。0を指定すると無制限にバックアップを行います。世代バックアップを行う場合、画面上部の「差分」メニューを選択すると過去の編集履歴が表示され、それぞれについて現在のソースとの差分を閲覧することができます。

また、rssやamazonなど、一部のプラグインはプログラム中からHTTPで外部のサーバに接続します。プロキシを使用している場合はproxy_host、proxy_port、proxy_user、proxy_passを設定しておく必要があります（proxy_userとproxy_passは認証が必要な場合のみ）。

### セキュリティ

上記で解説したインストール方法ではsetup.datや各種データを保存しているディレクトリをHTTPで参照できてしまいます。セキュリティ上問題になるようであれば.htaccessを使用してアクセス制限を行ってください。

```
<FilesMatch "\.(pm|dat|wiki|log)$">
  deny from all
</FilesMatch>
```

なお、データディレクトリに関してはHTTPでは見えない場所に配置することも可能です。その場合はsetup.datのディレクトリ指定部分を変更してください。

### バージョンアップ時の設置方法

設置ディレクトリ直下にあるsetup.dat、dataディレクトリ、backupディレクトリ、pdfディレクトリ、logディレクトリ、configディレクトリ以外のファイルおよびディレクトリをいったん削除し、配布ファイルで置き換えてください。また、dataディレクトリ内のhelp.wikiはヘルプで表示されるページですのでこれも最新版のファイルで上書きしてください。

setup.datはできるだけバージョン間で相違のないよう配慮していますが、止むを得ずバージョンアップ時に内容を変更する必要がある場合があります。できれば最新のファイルで上書きしたあと、設定内容を修正するようにしてください。

また、3.4.0以降ではバージョンアップによって管理画面での設定項目が追加されている場合があります。一度管理ユーザにてログインし、設定の更新を行ってください。

### データのバックアップ方法

dataディレクトリ、attachディレクトリ、configディレクトリをコピーしてください。差分表示が必要であればbackupディレクトリ、PDFも必要であればpdfディレクトリもコピーしてください（PDFファイルはPDFアンカ押下時に生成することができるのでバックアップしなくても構いません）。

ログは、デフォルトではlogディレクトリにaccess.log（アクセスログ）、freeze.log（凍結用のログ）、attach.log（添付ファイルのログ）が出力されていますので、必要に応じてこれらもコピーしておいてください。

### mod_perlで使用する場合

Ver3.4.1よりmod_perlにも対応しています。wiki.cgiの先頭部分を編集し、chdirの引数にFSWikiのインストールディレクトリを指定してください。例えばFSWikiをC:/Apache/htdocs/fswikiに配置した場合は以下のようになります。

```
BEGIN {
  if(exists $ENV{MOD_PERL}){
    # カレントディレクトリの変更
    use Cwd;
    chdir("C:/Apache/htdocs/fswiki");
```

3.5.1以降はApache::Registry環境下でも完全に動作することを確認していますが、それ以前のバージョンでは差分表示やPDF生成など一部の機能の動作に支障があります。Apache::PerlRun環境下であれば問題ありません。

## ビルドとテスト

*   **ビルド:**
    ```bash
    make build
    ```
*   **テスト:**
    *   テストの実行方法は現在ドキュメント化されていません (TBD)。

### 補助ツールのセットアップ

#### flymcp (fly.io操作用)

fly.ioを操作するためのMCPサーバー `flymcp` をインストールします。

**前提条件:**

*   Go 1.21以上
*   `flyctl` CLIがインストールされ、PATHが通っていること

**インストール手順:**

1.  **ソースコードのクローン:**
    ```bash
    git clone https://github.com/superfly/flymcp.git /tmp/flymcp
    ```

2.  **ビルド:**
    ```bash
    cd /tmp/flymcp
    go mod download
    go build -o flymcp
    ```

3.  **インストール:**
    ```bash
    sudo mv /tmp/flymcp/flymcp /usr/local/bin/
    rm -rf /tmp/flymcp
    ```
