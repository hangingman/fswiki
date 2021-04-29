############################################################
# 
# <p>Layoutプラグイン・テンプレートの一覧およびヘルプを表示します。</p>
# 
# <h3>利用方法</h3>
# <pre>
# {{layouthelp}}
# {{layouthelp <テンプレート名>}}
# </pre>
# 
############################################################
package plugin::layout::LayoutHelp;
use strict;
use warnings;
use plugin::layout::LayoutUtil;
use Util;
use strict;
#===========================================================
# コンストラクタ
#===========================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#==============================================================================
# パラグラフ関数
#==============================================================================
sub paragraph {
	my $self   = shift;
	my $wiki   = shift;
	my $tmpl   = shift;
	
	my $html = "";
	my $source = "";
	
	if ( defined($tmpl) ) {
		my $tmplinfo = &plugin::layout::LayoutUtil::get_tmpl_info($wiki,$tmpl);
##		foreach (@{$tmplinfo->{PARAMETERLIST}}) {
##			$source .= "*$_\n";
##		}
		if ( $tmplinfo->{HELP_STYLE} eq 'HTML' ) {
			$html .= $tmplinfo->{HELP};
		} else {
			$source .= $tmplinfo->{HELP};
		}
	} else {
		my @tmpllist = &plugin::layout::LayoutUtil::get_tmpl_list($wiki);
		foreach (@tmpllist) {
			my $tmplinfo = &plugin::layout::LayoutUtil::get_tmpl_info($wiki,$_);
			$source .= "::[".$_."|".$wiki->create_url({action=>'LAYOUTHELP',tmpl=>$_})."]\n";
			$source .= ":::".$tmplinfo->{TITLE}."\n";
		}
	}
	
	if ( $source ne "" ) {
		$html .= $wiki->process_wiki($source);
	}
	return $html;
}

#===============================================================================
# アクションハンドラメソッド
#===============================================================================
sub do_action {
	my $self  = shift;
	my $wiki  = shift;
	my $cgi   = $wiki->get_CGI();
	
	my $html = "";
	my $tmpl = $cgi->param("tmpl");
	
	if ( !defined($tmpl) ) {
		$wiki->set_title("レイアウト・テンプレート一覧");
		$html .= "<h2>レイアウト・テンプレート一覧</h2>\n";
	} else {
		my $tmplinfo = &plugin::layout::LayoutUtil::get_tmpl_info($wiki,$tmpl);
		return $wiki->error("テンプレート[".$tmpl."]が見つかりません。") if (!defined($tmplinfo));
		$wiki->set_title($tmplinfo->{TITLE});
		$html .= "<h2>".$tmplinfo->{TITLE}."</h2>\n";
	}
	$html .= $self->paragraph($wiki, $tmpl);
	return $html;
}

1;
