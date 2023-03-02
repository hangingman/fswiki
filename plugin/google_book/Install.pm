############################################################
#
# 指定した書籍のプレビューをGoogleの埋め込みビュアーで表示します。
#
############################################################
package plugin::google_book::Install;
use strict;
use warnings;

sub install {
	my $wiki = shift;
	$wiki->add_inline_plugin("google_book","plugin::google_book::GoogleBook", "HTML");
}

1;
