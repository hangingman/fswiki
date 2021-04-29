###############################################################################
#
# レイアウト・テンプレートで利用可能な任意のキーを設定する
#
###############################################################################
package plugin::layout::AdminLayoutKey;
use strict;
use warnings;
#==============================================================================
# コンストラクタ
#==============================================================================
sub new {
	my $class = shift;
	my $self = {};
	
	# 設定ファイル
	$self->{config_file} = 'layoutkey.dat';
	
	return bless $self,$class;
}

#==============================================================================
# アクションハンドラメソッド
#==============================================================================
sub do_action {
	my $self  = shift;
	my $wiki  = shift;
	my $cgi   = $wiki->get_CGI();
	
	$wiki->set_title("レイアウト変数の設定");
	
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
	my $tmpl = HTML::Template->new(filename=>$wiki->config('tmpl_dir')."/admin_layoutkey.tmpl",
	                               die_on_bad_params => 0);
	
	my @loop = ();
	my $num = 0;
	foreach my $key (sort(keys(%$info))) {
		push(@loop,{NUM=>$num++,KEY=>$key,VALUE=>$info->{$key}});
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
	
	my (@keys, @values) = ();
	push(@keys, $cgi->param("key"));
	push(@values, $cgi->param("value"));
	my $count = @keys;
	
	my $config;
	for (my $i=0; $i<$count; $i++) {
		next if ($keys[$i] eq "" || $values[$i] eq "");
		$config->{$keys[$i]} = $values[$i];
	}
	
	&Util::save_config_hash($wiki,$self->{config_file},$config);
	
	$wiki->redirectURL($wiki->config('script_name')."?action=ADMINLAYOUTKEY");
}

1;
