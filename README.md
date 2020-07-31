fswiki
======

FreeStyleWiki powered by PSGI


Local run with carton
======================

```sh
$ carton install
$ carton exec starman -r
```


Run as service
==============

- supervisorのインストール

```sh
$ sudo yum install python-setuptools
$ sudo easy_install pip
$ sudo pip install supervisor
```

- supervisorの設定

```sh
// ログ保存用ディレクトリ作成
$ sudo mkdir /var/log/supervisord/

// 個別設定を格納するディレクトリを作成
$ sudo mkdir /etc/supervisord.d/

// supervisorの設定ファイルをコピー
$ sudo cp ./etc/fswiki.ini /etc/supervisord.d/fswiki.ini

// supervisorの起動
$ sudo start supervisord
$ sudo enable supervisord
```
