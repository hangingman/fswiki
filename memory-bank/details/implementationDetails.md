## FSWikiの機能

### 文法

FreeStyleWikiの文法は、インストール後のHelpページで参照できます。
バージョン3.5.3からは、formatプラグインによりFSWiki以外の文法（YukiWiki、Hiki）での編集も可能です。ただし、プラグインの記法やプラグイン名はFSWikiのものを使用します。

### 特殊なページ名

*   **Header, Footer, Menu:** それぞれヘッダ、フッタ、サイドバーとして表示されます。
*   **EditHelper:** ページの作成・編集画面に表示され、編集時のヘルプとして利用できます。
*   **Template/ で始まるページ:** ページの作成画面でテンプレートとして選択できます。

### テーマ

tDiaryのテーマを使用して見た目を変更できます。テーマは `/theme` ディレクトリ配下に配置し、管理画面の「スタイル設定」で選択します。

### サイトテンプレート

CSSだけでは実現できないデザインのためにサイトテンプレート機能があります。HTML::Templateを拡張したもので、`/tmpl/site` 配下に配置します。デフォルトは `default` ディレクトリの内容が使用されます。独自のテンプレートは `hoge.tmpl`, `hoge_handyphone.tmpl` の2種類を用意し、`/tmpl/site/hoge` ディレクトリに配置します。管理画面の「スタイル設定」で選択できます。

### 管理画面

画面上部のログインメニューから管理者ユーザ（デフォルトID:admin, Pass:admin）でログインすると使用できます。ページの凍結・削除、ユーザ管理、Wiki動作設定などが行えます。
ユーザには管理ユーザと一般ユーザがいます。管理ユーザは凍結ページ編集や、作成・編集禁止時でも操作可能です。一般ユーザは管理画面を使用できません。

### プラグイン

FreeStyleWikiのディストリビューションには様々なプラグインが含まれており、インストール直後から使用可能です。詳細はpluginhelpを参照します。
管理画面でパッケージごとにプラグインの有効/無効を設定できますが、coreパッケージやadminパッケージを無効にするとWikiが正常に動作しなくなる可能性があります。

### WikiFarmの利用について

1つのWikiで複数のWikiサイトを運用できる機能です。デフォルトのWikiサイトをルートとしたツリー構造を形成します。
利用するには管理画面の「WikiFarmの設定」で「使用する」を選択します。画面上部のメニューに「Farm」が表示され、現在のWikiサイト配下のWikiサイト一覧や新規作成フォームが表示されます。

```
* ルートのWiki
    * 子Wiki1
    * 子Wiki2
        * 孫Wiki
```

## プラグイン開発

### プラグインのインストール

プラグインはパッケージごとにディレクトリを作成し、`plugin` ディレクトリに配置します。有効化は管理画面で行います。
プラグイン開発では、パッケージごとに `パッケージ名::Install` モジュールを作成し、その `install` メソッド内でプラグインのインストール処理を行います。

```perl
package plugin::test::Install;
sub install {
  my $wiki = shift;
  $wiki->add_inline_plugin("helio","plugin::test::TestPlugin");
}
```

有効なパッケージの `install` メソッドは自動的に呼び出されます。

### アクションハンドラ

`action` リクエストパラメータに応じてクライアントにレスポンスを返すプラグインです。`do_action` メソッドを実装し、表示内容（HTML）を返します。

```perl
sub do_action {
  my $self = shift;
  my $wiki = shift;
  return "アクションハンドラプラグインからの出力";
}
```

登録はインストールスクリプトで `Wiki#add_handler` メソッドを使用します。

```perl
$wiki->add_handler("EDIT","plugin::core::EditPage");
```

管理者のみ使用可能なアクションハンドラは `Wiki#add_admin_handler` で登録し、ログイン・権限チェックが自動化されます。

```perl
$wiki->add_admin_handler("ADMINPAGE","plugin::admin::AdminPageHandler");
```

### フックプラグイン

特定の契機でメソッドを実行するプラグインです。メニューON/OFFやページ保存時などに使用します。`hook` メソッドを実装します。

```perl
sub hook {
  my $self   = shift;
  my $wiki   = shift;
  my $name   = shift;
  my @params = @_;
  ...
}
```

`hook` メソッドの第3引数にフック名、第4引数以降にパラメータが渡されます。
登録はインストールスクリプトで `Wiki#add_hook` メソッドを使用します。

```perl
$wiki->add_hook("show","plugin::core::BBS");
```

主なフック: `show`, `save_before`, `save_after`, `delete`, `create_wiki`, `remove_wiki`, `initialize`。

### インラインプラグイン

Wiki文書中に `{{プラグイン名 [引数...]}}` で埋め込み、特殊な出力を生成します。`inline` メソッドを実装し、Wiki形式またはHTML文字列を返します。

HTMLを返す例:

```perl
sub inline {
  my $self = shift;
  my $wiki = shift;
  return "<B>簡単なプラグインです。</B>";
}
```

Wiki形式テキストを返す例:

```perl
sub inline {
  my $self   = shift;
  my $wiki   = shift;
  my $parser = shift;
  return "[[FrontPage]]";
}
```

登録はインストールスクリプトで `Wiki#add_inline_plugin` メソッドを使用します。引数にプラグイン名、クラス名、戻り値の形式（HTMLまたはWIKI）を指定します。

```perl
$wiki->add_inline_plugin("edit","plugin::core::Edit","HTML");
```

### パラグラフプラグイン

Wiki文書中に `{{プラグイン名 [引数...]}}` で埋め込み、特殊な出力を生成します。インラインプラグインと異なり、1行にプラグインのみ記述し、Pタグ補完は行われません。`paragraph` メソッドを実装します。

HTMLを返す例:

```perl
sub paragraph {
  my $self = shift;
  my $wiki = shift;
  return "<p>パラグラフプラグインです。</p>";
}
```

Wiki形式文字列を返す例:

```perl
sub paragraph {
  my $self   = shift;
  my $wiki   = shift;
  return "*[[FrontPage]]\n*[[Help]]\n";
}
```

登録はインストールスクリプトで `Wiki#add_paragraph_plugin` メソッドを使用します。引数にプラグイン名、クラス名、戻り値の形式を指定します。

```perl
$wiki->add_paragraph_plugin("bbs","plugin::bbs::BBS","HTML");
```

### ブロックプラグイン

複数行の引数を取ることができるパラグラフプラグインです。`{{プラグイン名 引数1,引数2,\n引数3\n}}` のように使用します。`block` メソッドを実装します。複数行の引数は第1引数に渡されます。

```perl
sub block {
  my $self = shift;
  my $wiki = shift;
  my $text = shift;
  return "<p>".Util::escapeHTML($text)."</p>";
}
```

登録はインストールスクリプトで `Wiki#add_block_plugin` メソッドを使用します。引数にプラグイン名、クラス名、戻り値の形式を指定します。

```perl
$wiki->add_block_plugin("pre","plugin::core::PRE","HTML");
```

### エディットフォームプラグイン

ページの編集画面に表示されるプラグインです。`editform` メソッドを実装し、編集画面に表示するHTMLを返します。

登録はインストールスクリプトで `Wiki#add_editform_plugin` メソッドを使用します。第3引数に表示優先度を指定します。

```perl
$wiki->add_editform_plugin("plugin::core::EditHelper",0);
```

### フォーマットプラグイン

FSWiki以外のWiki書式での編集を可能にするプラグインです。以下のメソッドを実装します。

*   `convert_from_fswiki` (FSWikiから各フォーマットへ)
*   `convert_from_fswiki_line` (FSWikiから各フォーマットへ、インライン要素のみ)
*   `convert_to_fswiki` (各フォーマットからFSWiki形式へ)
*   `convert_to_fswiki_line` (各フォーマットからFSWiki形式へ、インライン要素のみ)

登録はインストールスクリプトで `Wiki#add_format_plugin` メソッドを使用します。

```perl
$wiki->add_format_plugin("Hiki","plugin::format::HikiFormat");
```

### メニューアイテム

画面上部のメニューアイテムを追加します。`Wiki#add_menu` メソッドを使用します。

```perl
$wiki->add_menu(名称,URL,優先度);
```

第3引数に表示優先度を指定します。URLを省略または空文字列にすると無効なメニューが登録されます。

### 管理者メニュー

管理者ログイン時に表示されるメニューを追加します。`Wiki#add_admin_menu` メソッドを使用します。管理者のみ表示されます。

```perl
$wiki->add_admin_menu(名称,URL);
```
