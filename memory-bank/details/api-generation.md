# API生成の設計境界

## 目的

FSWikiのプレーンHTTP/HTML実装を維持しつつ、同じCoreとPluginの処理からJSON APIを生成する。React、VueなどのクライアントはJSON APIを利用する。

## 生成対象

自動生成するのは、Coreへ明示登録されたAPIだけとする。Coreの全メソッドやStorageを反射して公開しない。

```text
Plugin / handler registration
  ↓
API metadata
  ↓
Generated HTTP route
  ↓
Core handler
  ↓
Result serializer
  ├─ HTML
  └─ JSON
```

## 登録情報

```text
name
handler
permission: public | user | admin
api:
  method
  path
  input schema
  output schema / serializer
```

## Proxy / Adapter

既存のHTML中心PluginをJSON化する場合だけ、API Proxy/Adapterを置く。Proxyは入力検証、Core権限確認、handler呼び出し、JSON変換を担当する。Storageへ直接アクセスしない。

## 導入順

1. handler recordにAPI metadataを追加。
2. Coreから公開API一覧を読み出す。
3. JSON serializerと統一エラー形式を追加。
4. `GET /api/source`を生成。
5. `POST /api/page/<page>`を生成。
6. HTML/JSONが同一handlerとStorageを通ることを実機確認。
7. 複数Pluginの重複が確認できた時点でRoleまたは共通Proxyを追加。

## 境界

- 自動: route生成、入力のCore渡し、権限適用、JSON化、JSONエラー化。
- 明示: API公開、HTTP method/path、入力契約、出力契約、権限、副作用。
- 保留: OpenAPI生成。API契約が安定してから追加する。

## 現時点の非目標

認証、CSRF、履歴、Wikiパーサー、DB Storage、デプロイ構成の確定はこの設計の対象外。

## 停止条件

一つの読み取りAPIと一つの保存APIを、HTMLとJSONの両方で同じCore経路に通せたら、基底クラスやProxyを増やさず次の機能へ進む。抽象化は重複が実測された場合だけ追加する。
