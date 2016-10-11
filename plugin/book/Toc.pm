################################################################################
#
# <p>bookプラグインの見出し番号に対応したページのアウトラインを表示します。</p>
# <pre>
# {{toc}}
# </pre>
# <p>ページ名を指定することで他のページのアウトラインを表示することもできます。</p>
# <pre>
# {{toc ページ名}}
# </pre>
# <p>
#   アウトラインに表示する見出しのレベルを指定することもできます。
#   以下の例では見出し2までをアウトラインとして表示します。
# </p>
# <pre>
# {{toc 2}}
# {{toc ページ名,2}}
# </pre>
#
################################################################################
package plugin::book::Toc;
#==============================================================================
# コンストラクタ
#==============================================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#==============================================================================
# ブロックメソッド
#==============================================================================
sub paragraph {
	my $self  = shift;
	my $wiki  = shift;
	my $page  = shift;
	my $level = shift;
	my $cgi   = $wiki->get_CGI;
	my $p_cnt = 0;

	if($level eq "" && $page =~ /^[0-9]+$/){
		$level = $page;
		$page = "";
	}
	$page = $cgi->param("page") unless $page;
	
	# ページの参照権限があるかどうか調べる
	unless($wiki->can_show($page)){
		return undef;
	}
	my $parser = plugin::book::TocParser->new($wiki, $page, $level);
	return $parser->outline($wiki->get_page($page));
}

1;