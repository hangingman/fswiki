###############################################################################
#
# <p>HTMLで記載したページを読み込みます。（HTMLタグ挿入プラグインの代替用です）</p>
# <pre>
# {{include_html ページ名[, パート名]}}
# </pre>
# <p>
# HTML形式のソースをWikiページ内に取り込んで表示します。
# リンクバナーや任意のJavaScript等を埋め込むのに利用できます。<br>
# <br>
# 使用方法：<br>
# まず、予めHTMLタグ形式で記述したページを（Wikiページとして）作成します。
# そしてこのページを「ユーザ」以上の参照権限に変更するか、又はページを凍結します。
# 最後に、表示させたいページで、本プラグインを用いてHTML形式で作成した
# Wikiページ名を引数に指定して記述します。
# HTMLで記述するページと、それを読み込んで表示するページを分けてページを作成
# することになります。<br>
# <br>
# rev01からパートの指定に対応しました。<br>
# 一つのページに、パートを分けて複数のHTMLを定義しておけるようになりました。<br>
# <br>
# ページ：banner_html
# <pre>
# !バナー１
# &lt;a href="http://aaa.bbb.com"&gt;
# &lt;img border="0" src="http://aaa.bbb.com/theme/banner.gif" alt="aaa.bbb.comのバナー"&gt;
# &lt;/a&gt;
# !バナー２
# &lt;a href="http://ccc.ddd.com"&gt;
# &lt;img border="0" src="http://ccc.ddd.com/theme/banner.gif" alt="ccc.ddd.comのバナー"&gt;
# &lt;/a&gt;
# </pre>
# 表示させるページ
# <pre>
# {{include_html banner_html, "!バナー１"}}
# {{include_html banner_html, "!バナー２"}}
# </pre>
# 上記のように、頭に「!」を付けてパート名を記述するとパート名として扱われます。
# パート名を省略すると初版どおりページの全内容が対象となります。<br>
# <br>
# 補足：<br>
# HTMLで記述するページの参照権限をユーザ以上、又は凍結されたページのみに制限する
# ことにより、悪意のある閲覧者によるページの改竄を防止します。<br>
# HTMLで記載したページは、通常のWikiページとして表示させる価値は全くありません。
# （HTML形式のソースを定義するためだけのページとなります）
# 本プラグインはインラインプラグインです。
# </p>
#
###############################################################################
package plugin::include_html::IncludeHtml;
use strict;
use warnings;
#==============================================================================
# コンストラクタ
#==============================================================================
sub new {
  my $class = shift;
  my $self = {};
  return bless $self,$class;
}

#==============================================================================
# インライン関数
#==============================================================================
sub inline {
  my ($self, $wiki, $page, $part) = @_;

  # エラーチェック
  if($page eq ""){
    return &Util::inline_error("ページ名が指定されていません。");
  }
  if(!$wiki->page_exists($page)){
    return &Util::inline_error("ページが存在しません。");
  }
  if(!$wiki->get_page_level($page) && !$wiki->is_freeze($page)){
    return &Util::inline_error("読み込むページの参照権限はユーザ以上か、又は凍結されたページでなければなりません。");
  }

  #パートが指定されていなければ、初版どおりページの全内容を返す
  unless($part){
    return $wiki->get_page($page);
  }

  #パートが見出し形式だった場合、そのパートだけを取り出す
  if($part =~ /^\s*\"?(!.*?)\"?\s*$/){
    if($wiki->get_page($page) =~ /(^|\n)$1\n(.*?)(\n!|$)/s){
      return $2;
    }
    return &Util::inline_error("指定されたパートは存在しません。");
  }
  return &Util::inline_error("パートの指定形式が不正です。");
}

1;
