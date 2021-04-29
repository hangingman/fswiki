###############################################################################
#
# プラグインの別名を設定するアクションハンドラ
#
###############################################################################
package plugin::layout::AdminLayoutAlias;
use strict;
use warnings;
#==============================================================================
# コンストラクタ
#==============================================================================
sub new {
	my $class = shift;
	my $self = {};
	
	# エイリアス設定ファイル
	$self->{config_file} = 'layoutalias.dat';
	
	return bless $self,$class;
}

#==============================================================================
# アクションハンドラメソッド
#==============================================================================
sub do_action {
	my $self  = shift;
	my $wiki  = shift;
	my $cgi   = $wiki->get_CGI();
	
	$wiki->set_title("プラグイン別名を設定");
	
	if($cgi->param("SAVE") ne ""){
		return $self->save_config($wiki);
	} else {
		return $self->config_form($wiki);
	}
}

#==============================================================================
# 設定フォーム
#==============================================================================
sub config_form {
	my $self = shift;
	my $wiki = shift;
	
	my $info = &Util::load_config_hash($wiki,$self->{config_file});
	
	# テンプレートにパラメータをセット
	my $tmpl = HTML::Template->new(filename=>$wiki->config('tmpl_dir')."/admin_layoutalias.tmpl",
	                               die_on_bad_params => 0);
	
	my @loop = ();
	my $num = 0;
	foreach my $alias (sort(keys(%$info))) {
		my ($command, $parameter) = split(/\t/,$info->{$alias});
		push(@loop,{NUM=>$num++,ALIAS=>$alias,PLUGIN=>$command,PARAMS=>$parameter});
	}
	$tmpl->param(
		 ITEM => \@loop
		,NUM_ADD => $num
		,SCRIPT_NAME => $wiki->config('script_name')
	);
	
	return $tmpl->output();
}

#==============================================================================
# 設定を保存
#==============================================================================
sub save_config {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;
	
	my (@alias, @plugin, @params) = ();
	push(@alias, $cgi->param("alias"));
	push(@plugin, $cgi->param("plugin"));
	push(@params, $cgi->param("params"));
	my $count = @alias;
	
	my $config;
	for (my $i=0; $i<$count; $i++) {
		next if ($alias[$i] eq "" || $plugin[$i] eq "");
		$config->{$alias[$i]} = $plugin[$i].(($params[$i] ne "")?"\t".$params[$i]:"");
	}
	
	&Util::save_config_hash($wiki,$self->{config_file},$config);
	
	$wiki->redirectURL($wiki->config('script_name')."?action=ADMINLAYOUTALIAS");
}

1;
