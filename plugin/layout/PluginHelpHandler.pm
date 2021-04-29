##############################################################
#
# PluginHelpのアクションハンドラ。
#
##############################################################
package plugin::layout::PluginHelpHandler;
use strict;
use warnings;
use plugin::info::PluginHelpHandler;
use strict;

1;

package plugin::info::PluginHelpHandler;
use strict;
use warnings;
use Util;

#=============================================================
# アクションハンドラメソッド
#=============================================================
sub do_action {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;
	my $name   = $cgi->param("name");
	my $plugin = $cgi->param("plugin");
	my $comment = "";
	if ( $name =~ /^@/ ) {
		$comment = &get_alias_comment($wiki, $name);
	} else {
		$comment = &get_comment($wiki,$plugin);
	}

	$wiki->set_title(&Util::escapeHTML($name)."プラグイン");
	return $comment;
}

sub get_alias_comment {
	my $wiki   = shift;
	my $name   = shift;

	my $layoutalias = 'layoutalias.dat';
	my $info = &Util::load_config_hash($wiki,$layoutalias);
	my ($command, $parameter) = split(/\t/,$info->{$name});
	my $plugin = $wiki->get_plugin_info($command);
	my $url = $wiki->create_url({action=>'PLUGINHELP',name=>$command,plugin=>$plugin->{CLASS}});
	my $comment = "<p>".$name." は <a href=\"".$url."\">".$command."</a> プラグインのエイリアスです。</p>\n";
	$comment .= "<p>\n";
	$comment .= "エイリアスは以下のように定義されています。\n";
	$comment .= "</p>\n";
	$comment .= "<pre>";
	$comment .= "{{".$command." ".$parameter."}}";
	$comment .= "</pre>\n";
	my $layouttmpl = undef;
	if ( $command eq 'ilayout' || $command eq 'ilayout' ) {
		$layouttmpl = $1 if ( $parameter =~ /^([^,]+)/ );
		$comment .= "<p>\n";
		$comment .= "レイアウト・テンプレートのヘルプは<a href=\"".$wiki->create_url({action=>'LAYOUTHELP',tmpl=>$layouttmpl})."\">こちら</a>を参照してください。\n";
		$comment .= "</p>\n";
	}
	return $comment;
}

1;
