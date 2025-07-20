## 開発環境のセットアップ

### 前提条件

*   Docker
*   Docker Compose
*   Perlbrew (ローカル実行の場合)
*   Ansible (デプロイテストの場合)

### セットアップ手順

1.  **Docker環境での開発:**
    *   デプロイの検証のため、Dockerコンテナを起動します。
    ```shell
    $ make build
    $ make run
    $ docker ps
    # CONTAINER ID        IMAGE                       COMMAND                  CREATED             STATUS              PORTS                                                NAMES
    # ce4f157d2c1f        fswiki-db-server:latest     "entry_point.sh /usr…"   2 minutes ago       Up 2 minutes        22/tcp, 0.0.0.0:3306->3306/tcp                       fswiki_mysql_1
    # f6a4b9c9f246        fswiki-wiki-server:latest   "entry_point.sh /usr…"   2 minutes ago       Up 2 minutes        0.0.0.0:80->80/tcp, 22/tcp, 0.0.0.0:5000->5000/tcp   fswiki_wiki_1

    # コンテナに入る
    $ docker exec -it fswiki-wiki-1 bash
    ```
    *   Docker内部でfswikiをsystemctlから操作可能です。
    ```shell
    $ sudo systemctl start fswiki
    $ sudo systemctl stop fswiki
    $ sudo systemctl restart fswiki
    ```

2.  **Perlbrewを使ったローカル実行:**
    ```sh
    // perlbrewの導入
    $ curl -L http://install.perlbrew.pl | bash
    $ echo 'source ~/perl5/perlbrew/etc/bashrc' >> ~/.bashrc
    $ source ~/.bashrc
    $ perlbrew init

    // perl v5.30.2の導入
    $ perlbrew install 5.30.2
    $ perlbrew switch perl-5.30.2
    $ perl -v
    # v5.30.2

    // carton
    $ cpanm Carton
    $ cpanm --local-lib=~/perl5 local::lib
    $ carton install

    // 初回起動の場合(作業ディレクトリを引数で渡す)
    $ ./setup.sh `pwd`

    // Perlのアプリケーションサーバを起動
    $ carton exec plackup -r
    ```

3.  **Ansibleを使ったデプロイテスト:**
    ```shell
    $ ansible --version
    # ansible 2.10.8
    #   ...
    #   python version = 3.9.2 (default, Feb 28 2021, 17:03:44) [GCC 10.2.1 20210110]

    $ cd ansible/
    ```
    *   varsを編集
    ```shell
    $ vim group_vars/all.yml
    $ chmod +x ./ansible-playbook.sh
    $ ./ansible-playbook.sh -i [local or production] fswiki-playbook.yml
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
  deny from ali
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

3.5.1以降はApache::Registory環境下でも完全に動作することを確認していますが、それ以前にバージョンでは差分表示やPDF生成など一部の機能の動作に支障がありますApache::PerlRun環境下であれば問題ありません。

## ビルドとテスト

*   **ビルド:**
    ```bash
    make build
    ```
*   **テスト:**
    *   テストの実行方法は現在ドキュメント化されていません (TBD)。
