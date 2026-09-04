# アーキテクチャ

## 1. 境界

```text
HTTP request
  ↓
HTTP adapter / generated route
  ↓
FSWiki::Core
  ├─ action handler / plugin
  ├─ hook execution
  ├─ permission policy
  └─ Storage delegation
       ↓
FSWiki::Storage
  ├─ File
  └─ Memory
```

CoreはHTTPフレームワークとStorage実装を直接結合しない。HTTP層は入力をCoreのリクエスト形式へ変換し、Coreの結果をHTMLまたはJSONへ変換する。

## 2. Perl版FSWikiから引き継ぐ契約

Perl版`Wiki.pm`の以下の責務をリファレンスとする。

| Perl API | Rakuの責務 |
|---|---|
| `add_hook` / `do_hook` | 名前付きイベントへのコールバック登録と登録順実行 |
| `add_handler` | 名前付きアクションのハンドラ登録 |
| `add_user_handler` | ユーザー権限付きハンドラ登録 |
| `add_admin_handler` | 管理者権限付きハンドラ登録 |
| `add_inline_plugin` / `add_paragraph_plugin` / `add_block_plugin` | プラグイン種別・出力形式の登録 |
| `call_handler` | 登録済みハンドラの実行と権限判断 |
| `get_page` / `save_page` / `page_exists` | Storageへの委譲 |

Rakuでは、Perlのクラスローダーやハッシュ構造をそのまま移植せず、Role、Callable、値オブジェクト、明示的な登録情報で表現する。

## 3. HTMLとJSONの二重出力

FSWikiの元実装はプレーンHTTPでHTMLを返す。Raku版はこの経路を廃止せず、同じCore処理にJSON出力を追加する。

```text
同じ操作定義
  ├─ HTML route → HTML response
  └─ JSON route → JSON response
```

Pluginは可能な限りHTML文字列を直接返さず、操作結果をデータとして返す。Rendererがその結果をHTMLまたはJSONへ変換する。

- HTML: 既存ブラウザ向け。テンプレート、`<pre>`、Wiki表示など。
- JSON: React/Vueなどのクライアント向け。API契約に従うオブジェクトをシリアライズする。
- 既存PluginがHTMLしか返せない場合は、JSON API用Proxy/Adapterで包む。ただし、CoreとStorageを迂回しない。

## 4. 明示的API登録

Core内部メソッドを自動公開しない。API公開する操作だけを登録情報に明示する。

概念モデル：

```text
handler record
  ├─ action name
  ├─ handler
  ├─ permission: public | user | admin
  └─ api metadata (optional)
       ├─ path
       ├─ method
       ├─ input schema
       └─ output schema / serializer
```

Raku APIの候補：

```raku
$core.add-handler(
    'SOURCE',
    handler    => &source-handler,
    permission => 'public',
    api        => {
        path   => '/api/source',
        method => 'GET',
    },
);
```

最初は既存`add-handler`を拡張する。基底クラスを先に作らない。Plugin数と契約が増え、共有Roleが実際に重複を減らす段階でRoleを導入する。

## 5. 自動生成と半自動化の境界

### 自動化する責務

- APIメタデータからHTTP routeを生成する。
- HTTP入力をCore handlerへ渡す。
- Coreの権限を適用する。
- 成功結果をJSONへシリアライズする。
- 失敗結果を統一JSONエラーへ変換する。

### Pluginが明示する責務

- APIとして公開するか。
- HTTP methodとpath。
- 入力名、必須項目、型、制約。
- 戻り値のデータ形状。
- 権限と副作用。

ルート生成は自動化するが、公開契約は明示する。これにより、内部APIの偶発的公開と将来の内部変更によるAPI破壊を避ける。

## 6. Proxy/Adapter

Proxyは、既存のHTML中心PluginをJSON APIへ接続する境界として使う。

```text
JSON request
  ↓
API proxy
  ├─ 入力検証
  ├─ Core権限確認
  ├─ Core handler呼び出し
  └─ ResultをJSON化
       ↓
JSON response
```

Proxyが直接Storageへアクセスしてはいけない。既存PluginがJSONに適したデータを返せない場合は、専用の結果変換を実装する。

## 7. 現在のエンドポイント

| HTTP | 処理 |
|---|---|
| `GET /health` | 生存確認 |
| `GET /source/<page>` | Core hook経由でページソースを取得しHTMLで返す |
| `POST /page/<page>` | form bodyの`source`をCore経由で保存 |

保存処理は以下の順序を維持する。

```text
POST /page/<page>
  → route input parsing
  → Core save-page
  → Storage save-page
  → response
```

## 8. 次の実装段階

1. Coreのhandler recordにAPI metadataを保持する。
2. `api-handlers`などの読み取りAPIを追加する。
3. JSON serializerを導入し、外部依存を最小限に抑える。
4. `GET /api/source`を1つだけ登録情報から生成する。
5. `POST /api/page/<page>`を既存保存処理へ接続する。
6. 実機HTTPでHTML経路とJSON経路が同じCore/Storage処理を通ることを検証する。
7. 複数Pluginで重複が確認できた時点でRoleまたはProxy基底実装を導入する。

## 9. 保留

- 認証・セッション・CSRF。
- 履歴世代API。
- Wiki本文の構文解析。
- OpenAPIドキュメントの自動生成。
- DB StorageとFly.io向けデプロイ構成。

これらはJSON APIの最小契約と権限モデルを検証した後に決める。
