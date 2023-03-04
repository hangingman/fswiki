############################################################
#
# 指定した書籍の書影をgoogle bookから取得して表示し、amazonの書評ページへリンクをはります。
#
############################################################
package plugin::amazon::Install;
use strict;
use warnings;

sub install {
	my $wiki = shift;
	$wiki->add_inline_plugin("amazon","plugin::amazon::Amazon", "HTML");
}

1;
