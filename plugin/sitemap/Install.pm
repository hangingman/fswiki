############################################################
#
# sitemap.xmlを自動作成するプラグイン
#
############################################################
package plugin::sitemap::Install;
use strict;
use warnings;

sub install {
	my $wiki = shift;
	$wiki->add_hook("save_after","plugin::sitemap::Sitemap");
	$wiki->add_hook("delete"    ,"plugin::sitemap::Sitemap");
}

1;
