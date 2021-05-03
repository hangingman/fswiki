###############################################################################
#
#
###############################################################################
package plugin::bookmarks::Bookmarks;
use strict;
use warnings;
use Jcode;

#==============================================================================
# コンストラクタ
#==============================================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}
#==============================================================================
# パラグラフメソッド
#==============================================================================
sub paragraph {
	my $self = shift;
	my Wiki $wiki = shift;
	my $page = shift;
	my $cgi = $wiki->get_CGI();
	my $this_page_title = "";

	# 他のソーシャルブックマークサイトは軒並み無くなっていたので削除した
	# はてなブックマーク
	# https://b.hatena.ne.jp/guide/bbutton
	my $buf = "";
	$buf .= '<a href="https://b.hatena.ne.jp/entry/" class="hatena-bookmark-button" data-hatena-bookmark-layout="basic-label-counter" data-hatena-bookmark-lang="ja" title="このエントリーをはてなブックマークに追加"><img src="https://b.st-hatena.com/images/v4/public/entry-button/button-only@2x.png" alt="このエントリーをはてなブックマークに追加" width="20" height="20" style="border: none;" /></a><script type="text/javascript" src="https://b.st-hatena.com/js/bookmark_button.js" charset="utf-8" async="async"></script></a>';

	return $buf;
}

1;
