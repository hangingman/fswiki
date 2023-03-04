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

// 初回起動の場合(作業ディレクトリを引数で渡す)
$ ./setup.sh `pwd`

// Perlのアプリケーションサーバを起動
$ carton exec plackup -r
```

Run as service
==============


Docker env run for development
==============================

- デプロイの検証のため、dockerコンテナを起動する
```shell
$ make build
$ make run
$ docker ps
CONTAINER ID        IMAGE                       COMMAND                  CREATED             STATUS              PORTS                                                NAMES
ce4f157d2c1f        fswiki-db-server:latest     "entry_point.sh /usr…"   2 minutes ago       Up 2 minutes        22/tcp, 0.0.0.0:3306->3306/tcp                       fswiki_mysql_1
f6a4b9c9f246        fswiki-wiki-server:latest   "entry_point.sh /usr…"   2 minutes ago       Up 2 minutes        0.0.0.0:80->80/tcp, 22/tcp, 0.0.0.0:5000->5000/tcp   fswiki_wiki_1

// コンテナに入る
$ docker exec -it fswiki-wiki-1 bash
```

- fswikiのデプロイをローカルでテストする

```shell
$ ansible --version
ansible 2.10.8
  ...
  python version = 3.9.2 (default, Feb 28 2021, 17:03:44) [GCC 10.2.1 20210110]

$ cd ansible/
```

- varsを編集

```shell
$ vim group_vars/all.yml
$ chmod +x ./ansible-playbook.sh
$ ./ansible-playbook.sh -i [local or production] fswiki-playbook.yml
```

- docker内部でfswikiをsystemctlから操作可能

```shell
$ sudo systemctl start fswiki
$ sudo systemctl stop fswiki
$ sudo systemctl restart fswiki
```
