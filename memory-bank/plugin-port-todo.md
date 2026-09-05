# Plugin移植計画 TODO

## 目的

Perl版FSWiki Pluginを逐語移植せず、Raku Coreの明示的な登録契約、Processor契約、Storage/API境界へ機能移植する。

MVPの終了条件は、ブラウザでWikiページを表示・編集し、HTTP APIとAJAX APIの両方で同じCore操作を確認できることとする。

## 基本方式

### 1. Pluginの分類

| 区分 | Raku登録方式 | 代表的な責務 |
|---|---|---|
| Inline | `add-inline-plugin` | Wiki本文内の値・リンク・表示部品 |
| Paragraph | `add-paragraph-plugin` | 独立した段落の表示・入力 |
| Block | `add-block-plugin` | 複数行入力、表、コード、引用など |
| Handler | `add-handler` / `add-user-handler` / `add-admin-handler` | HTTP/AJAX操作 |
| Hook | `add-hook` | 保存・削除・表示などのイベント反応 |
| Format | `add-format-plugin` | FSWiki以外の文法との相互変換 |
| UI | menu/editform/admin-menu | 画面の導線と編集フォーム拡張 |

### 2. 変換規則

- Perlのクラスローダー、グローバル変数、CGI直接参照は移植しない。
- Pluginは明示CallableまたはRaku型として登録する。
- HTML文字列を返す既存Pluginは、最初はRenderer境界に閉じ込める。Core/Storageを直接迂回しない。
- 入力値、認証、権限、ページ可視性はCore/API境界で検証する。
- 副作用はHandlerまたはHookに限定する。Inline/Paragraph/Blockは原則として表示結果を返す。
- 同じ操作をHTMLとJSON/AJAXで共有し、HTTP層に業務処理を複製しない。
- API公開は明示metadata登録のみとする。自動公開しない。

### 3. zef利用方針

| 用途 | 第一選択 | 導入条件 |
|---|---|---|
| HTTP | 既存Cro | 追加ライブラリ不要。現行ルートを再利用 |
| JSON | `JSON::Fast` | 既存利用を継続 |
| URI/入力検証 | Raku標準機能または既存実装 | zef追加は重複がない場合のみ |
| Markdown | まずProcessor Callable契約で差し替え検証 | CommonMark互換が必要になった時点でzef候補を比較 |
| HTML sanitization | 導入前に要件化 | 外部HTMLを受け入れるPluginを追加する時だけ調査 |
| DB/ORM | 現行Storageでは追加しない | 永続Pluginの受入れ要件と性能計測後に選定 |

zefの採用判断は、候補名、ライセンス、保守状況、依存数、Raku/Rakudo互換性、テスト有無、既存機能との差分を記録してから行う。依存追加だけを目的に導入しない。

## API設計の共通契約

各Pluginは次の情報を持つ。

```text
plugin name
kind: inline | paragraph | block | handler | hook | format
permission: public | user | admin
input schema
output shape
side effects
HTML capability
JSON/AJAX capability
registration/install function
```

API metadataには最低限以下を含める。

```raku
{
    method => 'POST',
    path   => '/api/plugin/example',
    schema => {
        page   => { required => True, type => 'Str' },
        value  => { required => True, type => 'Str' },
    },
}
```

エラーは既存の統一JSON形式を使う。

```json
{"error":{"code":"validation-error","message":"..."}}
```

AJAXでは、HTML redirectを返さず、成功時のデータとエラーコードを返す。認証・認可・CSRFの適用点はHTTP transportの前段またはCore handler境界に固定する。

## マイルストーン

### M0: 画面表示の基盤確認

**目的**: 現在のRaku実装をブラウザで確認できる状態に固定する。

- [x] `GET /source/<page>` をブラウザで確認する。
- [x] `GET /api/source?page=<page>` をブラウザまたはcurlで確認する。
- [x] HTML表示とJSON表示が同じStorage/Core結果を使うことを確認する。
- [x] 開発サーバー起動、停止、ログ、dataディレクトリの扱いを確認する。
- [x] 画面確認用の最小FrontPage fixtureを用意する。ただし本番dataは変更しない。

**検証**:

```text
make raku-test
raku -c raku/dev-server.raku
ブラウザで /source/Home と /api/source?page=Home を確認
```

### M1: Wikiページ表示MVP

**目的**: Wiki本文をHTMLとして画面表示する。

- [x] `FSWiki::Parser::Wiki`をHTTP表示経路へ接続する。
- [x] ページリンクのURL生成をCore callbackから提供する。
- [x] 可視性・凍結状態を表示経路へ適用する。
- [x] malformed markup、HTML escape、存在しないページリンクをブラウザで確認する。
- [ ] 表示専用の最小Pluginを1つ登録し、ProcessorとPlugin境界を確認する。

**検証**:

```text
GET /source/Home
GET /api/source?page=Home
browser: heading / list / link / escaped text
```

### M2: HTTP編集MVP

**目的**: ブラウザからWikiページを編集・保存する。

- [x] `GET`編集画面を追加する。
- [x] `POST`保存を既存`SAVE_PAGE` handlerへ接続する。
- [x] ページ権限・凍結・認証の拒否を画面で確認する。
- [x] 成功後に表示画面へ戻り、保存結果を読み戻す。
- [ ] 保存失敗時に本文を失わずエラーを表示する。

**検証**:

```text
GET edit page
POST form
GET source page
GET API source
```

### M3: AJAX境界

**目的**: HTTP画面を維持したまま、ページ一覧・取得・保存をAJAXで実行する。

- [ ] `GET /api/pages` を追加する。sort、limit、visibilityをschemaで検証する。
- [ ] `GET /api/page/{page}` を追加する。HTMLではなくsourceとmetadataを返す。
- [ ] `POST /api/page/{page}` の成功・validation・permission errorを確定する。
- [ ] ブラウザ側に依存のない最小JavaScriptを追加し、一覧選択→取得→編集→保存を実行する。
- [ ] AJAXとHTTP formが同じCore handlerを呼ぶことをテストする。
- [ ] HTTP redirectとAJAX JSON responseを混在させない。
- [ ] CSRF token、Content-Type、Origin/同一サイト制約の適用点を決める。実装前に契約化する。

**検証**:

```text
browser DevTools: request/response/status/content-type
AJAX success
AJAX validation error
AJAX permission error
```

### M4: Plugin SDK最小形

**目的**: 新規Pluginを1つの手順で追加できるようにする。

- [ ] Plugin descriptorと登録関数の最小形式を決める。
- [ ] InlineまたはParagraph Pluginを1つRakuで実装する。
- [ ] HTML表示とJSON/AJAX操作の両方を持つHandler Pluginを1つ実装する。
- [ ] input schema、permission、output shape、side effectをテストする。
- [ ] 失敗install、未知Plugin、権限拒否をテストする。
- [ ] zef依存なしで実装できる範囲を確認する。

### M5: 優先Plugin移植

以下の順で、各Pluginごとに「調査→失敗テスト→Raku実装→HTTP QA→AJAX QA→コミット」を行う。

1. **core表示系**: `ShowPage`, `Source`, `ListPage`, `NewPage`, `EditPage`, `Raw`, `Pre`, `Blockquote`（最小表示経路を実装）
2. **core操作系**: `Edit`, `Diff`, `RemoveWikiHandler`, `CreateWikiHandler`, `WikiList`（最小HTTP操作を実装）
3. **検索・参照系**: `SearchForm`, `SearchHandler`, `Category`, `CategoryList`, `Sitemap`
4. **履歴・活動系**: `EditLog`, `LastEdit`, `Actives`, `Recent`, `RecentDays`
5. **入力系**: `Comment`, `BBS`, `Vote`, `BugTrack`, `ToDo`
6. **管理系**: `Login`, `AccountHandler`, `UserRegisterHandler`, `PermissionForm`, admin handlers
7. **Format系**: `FSWikiFormat`, `YukiWikiFormat`, `HikiFormat`, `WalWikiFormat`
8. **外部・重依存系**: `Amazon`, `Google`, `MathJax`, `Mimetex`, `PDF`, `DBI`

移植停止条件:

- Raku標準機能と既存Cro/JSONで実装できる場合、zef導入を止める。
- 外部コマンド、DB、外部HTTPが必要な場合は、先にAPI境界と失敗時動作を固定する。
- HTML専用PluginをAJAX対応にする価値がない場合、HTTPのみで完了と記録する。
- 1つのPluginで3つ以上の共通処理が重複するまで基底クラスを追加しない。

## Pluginごとの完了条件

- Perl責務と既存呼び出し元を調査済み。
- Raku登録方式とAPI schemaを記録済み。
- HTML表示またはHTTP操作のテストがある。
- AJAX化対象ならJSON成功/失敗/権限テストがある。
- Storageを直接参照せずCore経由で動作する。
- zef依存の採否と理由を記録済み。
- `make raku-test`、対象テスト、`git diff --check`が通る。
- ブラウザまたは実HTTPで1回確認済み。
- 1マイルストーン単位でコミットする。

## 現時点の非目標

- 全166個のPerlモジュールの一括移植。
- Perlクラス名・CGI状態・HTML文字列の逐語再現。
- AJAX化前のフロントエンドフレームワーク導入。
- CommonMark完全実装の先行導入。
- DB/ORM、認証基盤、CSRF実装の先行導入。
- OpenAPI生成。API契約が安定するまで追加しない。

## 次の一手

1. M0として開発サーバーを起動し、ブラウザで`/source/Home`と`/api/source?page=Home`を確認する。
2. M1としてWiki ProcessorをHTML表示経路へ接続する。
3. M2でHTTP編集、M3でAJAX編集へ進む。
4. M4でPlugin SDK最小形を固定してから、M5の順序で移植する。
