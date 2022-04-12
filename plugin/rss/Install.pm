############################################################
#
# RSSの生成機能を提供します。
#
############################################################
package plugin::rss::Install;
use strict;
use warnings;

sub install {
	my $wiki = shift;
	$wiki->add_menu("RSS",$wiki->create_url({action=>"RSS"}),50,1);

	if($wiki->config("rss_version") eq "1"){
		$wiki->add_handler("RSS","plugin::rss::RSSMaker10");
		$wiki->add_hook("save_after" ,"plugin::rss::RSSMaker10");
		$wiki->add_hook("delete"     ,"plugin::rss::RSSMaker10");
		$wiki->add_hook("initialize" ,"plugin::rss::RSSMaker10");
	} else {
		$wiki->add_handler("RSS","plugin::rss::RSSMaker");
		$wiki->add_hook("save_after" ,"plugin::rss::RSSMaker");
		$wiki->add_hook("delete"     ,"plugin::rss::RSSMaker");
		$wiki->add_hook("initialize" ,"plugin::rss::RSSMaker");
	}

	$wiki->add_paragraph_plugin("rss" ,"plugin::rss::RSS" ,"HTML");
}

1;
