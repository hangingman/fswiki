############################################################
#
# mimetex.cgiを使い数式イメージを挿入するプラグイン
# Show the image of a formula with mimetex.cgi
#
############################################################
package plugin::mimetex::Install;

sub install {
	my $wiki = shift;
	$wiki->add_inline_plugin("mimetex","plugin::mimetex::Mimetex", "HTML");
	$wiki->add_inline_plugin("tex"    ,"plugin::mimetex::Mimetex", "HTML");
	$wiki->add_inline_plugin("math"   ,"plugin::mimetex::Mimetex", "HTML");
}

1;
