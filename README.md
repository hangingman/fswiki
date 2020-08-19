fswiki
======

FreeStyleWiki powered by PSGI


Local run with carton
======================

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
v5.30.2

// carton
$ cpanm Carton
$ cpanm --local-lib=~/perl5 local::lib
$ carton install

// 初回起動の場合
$ ./setup.sh

// Perlのアプリケーションサーバを起動
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
