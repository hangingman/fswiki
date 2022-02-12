# Herokuへのデプロイ方法

- 参考
  - [Docker Compose を使用したローカル開発](https://devcenter.heroku.com/ja/articles/local-development-with-docker-compose)
  - [Container Registry および Runtime (Docker デプロイ)](https://devcenter.heroku.com/ja/articles/container-registry-and-runtime)

## コンテナビルド

- docker-composeを使い、fswikiのアプリをdockerコンテナとしてビルドする
- これはローカルでのビルドとテストに使う

```shell
$ cd fswiki/
$ make build
```

## コンテナのプッシュ

- ビルドしたコンテナをHerokuコンテナレジストリにプッシュする

```shell
// Herokuへのログイン
$ heroku login

// Heroku Container Registryへのログイン
$ heroku container:login

// プッシュ
$ heroku container:push web --app <APP名>

// リリース
$ heroku container:release web --app <APP名>
```

