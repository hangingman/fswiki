############################################################
#
# FSWikiのデータエクスポート機能を提供します。
#
############################################################
package plugin::admin_export::Install;
use strict;
use warnings;

sub install {
	my $wiki = shift;

	my $login = $wiki->get_login_info();
	my $page = $wiki->get_CGI()->param('page');

	if(defined($login)){
		$wiki->add_menu("管理",$wiki->create_url({action=>"LOGIN"}),0);
	} else {
		if($page){
			$wiki->add_menu("ログイン",$wiki->create_url({action=>"LOGIN", page=>$page}),0);
		} else {
			$wiki->add_menu("ログイン",$wiki->create_url({action=>"LOGIN"}),0);
		}
	}
	$wiki->add_admin_menu("データのエクスポート",$wiki->create_url({action=>"ADMINEXPORT"}),999,
						  "FSWikiのデータをエクスポートします。");

	$wiki->add_admin_handler("ADMINEXPORT" ,"plugin::admin_export::AdminExportHandler");
}

1;
