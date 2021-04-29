############################################################
#
# Google Chart APIを使い数式イメージを挿入するプラグイン
#
############################################################
package plugin::gtex::Install;
use strict;
use warnings;

sub install {
	my $wiki = shift;
	$wiki->add_inline_plugin("gtex","plugin::gtex::Gtex", "HTML");
}

1;
