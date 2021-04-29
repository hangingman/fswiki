############################################################
#
# HTMLで記述されたページをインクルードするプラグインです。
#
############################################################
package plugin::include_html::Install;
use strict;
use warnings;

sub install {
	my $wiki  = shift;

	$wiki->add_inline_plugin("include_html","plugin::include_html::IncludeHtml","HTML");
}

1;
