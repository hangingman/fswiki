############################################################
#
# 各種ソーシャルブックマークへ登録するリンクボタン（アイコン）を表示します。
#
############################################################
package plugin::bookmarks::Install;
use strict;
use warnings;

sub install {
	my $wiki = shift;
	$wiki->add_paragraph_plugin("bookmarks","plugin::bookmarks::Bookmarks", "HTML");
}

1;
