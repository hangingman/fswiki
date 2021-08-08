###############################################################################
#
# ソースを表示するプラグイン
#
###############################################################################
package plugin::core::Source;
use strict;
use warnings;
#==============================================================================
# コンストラクタ
#==============================================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#==============================================================================
# アクションの実行
#==============================================================================
sub do_action {
	my $self = shift;
	my $wiki = shift;
	my $cgi = $wiki->get_CGI;

	my $pagename = $cgi->param("page");
	if($pagename eq ""){
		$pagename = $wiki->config("frontpage");
	}
	unless($wiki->can_show($pagename)){
		return $wiki->error("参照権限がありません。");
	}
	my $gen = $cgi->param("generation");
	my $source;
	if($gen eq ''){
		$source = $wiki->get_page($pagename);
	} else {
		$source = $wiki->get_backup($pagename,$gen);
	}
	my $format = $wiki->get_edit_format();
	$source = $wiki->convert_from_fswiki($source,$format);

	my Plack::Response $res = Plack::Response->new(200);
	$res->content_type('text/html;charset=UTF-8');
    $res->content_encoding('UTF-8');
	# HTMLの出力
	$res->body('<pre>' . $source . '</pre>');  # FIXME: 文字列結合ではなくどこかで<pre>タグを作っていそうだが見つからず
	return $res;
}

#==============================================================================
# ページ表示時のフックメソッド
# 「ソース」メニューを有効にします
#==============================================================================
sub hook {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;

	my $pagename = $cgi->param("page");
	if($pagename eq ""){
		$pagename = $wiki->config("frontpage");
	}

	$wiki->add_menu("ソース",$wiki->create_url({ action=>"SOURCE",page=>$pagename }));
}

1;
