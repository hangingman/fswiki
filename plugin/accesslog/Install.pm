############################################################
#
# アクセスログを整形して表示するプラグインを提供します
#
############################################################
package plugin::accesslog::Install;
use strict;
sub install {
	my $wiki = shift;
	$wiki->add_admin_handler("ACCESSLOG","plugin::accesslog::AccessLog");
	$wiki->add_admin_menu("アクセスログ閲覧",$wiki->config('script_name')."?action=ACCESSLOG",900,"アクセスログ閲覧");

	$wiki->add_admin_handler("ACCESSLOG_SEARCH","plugin::accesslog::AccessLogSearch");
	$wiki->add_admin_menu("アクセスログ検索",$wiki->config('script_name')."?action=ACCESSLOG_SEARCH",900,"アクセスログ検索");
}

1;
