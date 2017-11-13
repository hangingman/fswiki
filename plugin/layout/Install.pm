############################################################
#
# 任意のテンプレートを利用しWikiソースのパース結果を適用するプラグインを提供します。
#
############################################################
package plugin::layout::Install;
use plugin::layout::PluginHelpHandler;
use strict;
sub install {
	my $wiki = shift;
	
	$wiki->add_inline_plugin("ilayout","plugin::layout::Layout","HTML");
	$wiki->add_block_plugin("layout","plugin::layout::Layout","HTML");
	
#	$wiki->add_block_plugin("layout_loop","plugin::layout::LayoutParam","HTML");
#	$wiki->add_paragraph_plugin("layout_param","plugin::layout::LayoutParam","HTML");
	
	$wiki->add_paragraph_plugin("layouthelp","plugin::layout::LayoutHelp","HTML");
	$wiki->add_handler("LAYOUTHELP","plugin::layout::LayoutHelp");
	
	$wiki->add_editform_plugin("plugin::layout::EditHelper",10);
	
	$wiki->add_hook("initialize", "plugin::layout::LayoutAlias");
	
	$wiki->add_admin_handler("ADMINLAYOUTALIAS","plugin::layout::AdminLayoutAlias");
	$wiki->add_admin_menu("プラグイン別名の設定",$wiki->create_url({action=>'ADMINLAYOUTALIAS'}),994,
	                      "プラグインに別名を設定します。");
	
	$wiki->add_admin_handler("ADMINLAYOUTKEY","plugin::layout::AdminLayoutKey");
	$wiki->add_admin_menu("レイアウト変数の設定",$wiki->create_url({action=>'ADMINLAYOUTKEY'}),900,
	                      "レイアウト・テンプレートで利用可能な任意のキー設定を行います。");
}

1;
