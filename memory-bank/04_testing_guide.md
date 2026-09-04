# テストガイド

## 実行

```sh
make raku-test
raku -c raku/dev-server.raku
git diff --check
```

## 対象

- Core: hook、handler、権限、Storage委譲。
- Storage: Memory、File、ページ名の安全性。
- HTTP: routeからCore、Storage、responseまで。
- JSON API追加時: HTML経路とJSON経路が同じCore handlerを利用すること。
- 実機確認: 開発サーバへHTTPリクエストを送り、status、content-type、bodyを確認する。

新機能はテストを先に追加し、REDを確認してから最小実装を行う。

## APIテストの最低条件

1. 公開APIの登録情報をCoreから取得できる。
2. 登録情報からJSON routeが生成される。
3. JSON入力がCore handlerへ渡る。
4. Storageの結果がJSONに変換される。
5. 未登録API、入力不正、権限不足がJSONエラーになる。
