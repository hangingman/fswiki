################################################################################
#
# <p>columnプラグインで記述したコラムの一覧を出力します。</p>
# <pre>
# {{column}}
# </pre>
# <p>
#   ページ名を指定することで他のページのコラム一覧を出力することができます。
#   ページ名は複数指定することもできます。
# </p>
# <pre>
# {{toc ページ名1,ページ名2,...}}
# </pre>
#
################################################################################
package plugin::book::ColumnList;
#==============================================================================
# コンストラクタ
#==============================================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#==============================================================================
# パラグラフメソッド
#==============================================================================
sub paragraph {
	my $self  = shift;
	my $wiki  = shift;
	my @pages = @_;

	my $parser = plugin::book::ColumnListParser->new($wiki);
	if($#pages == -1){
		my $page = $wiki->get_CGI->param('page');
		$parser->parse('', $wiki->get_page($page));
	} else {
		foreach my $page (@pages){
			$parser->parse($page, $wiki->get_page($page));
		}
	}
	
	return $parser->columnlist;
}

#==============================================================================
# コラム抽出用のパーサ
#==============================================================================
package plugin::book::ColumnListParser;
use Wiki::HTMLParser;

@ISA = qw(Wiki::HTMLParser);

sub new {
	my $class = shift;
	my $self  = Wiki::HTMLParser->new(shift);
	$self->{columnlist} = '';
	return bless $self,$class;
}

sub parse {
	my $self   = shift;
	my $page   = shift;
	my $source = shift;
	$self->{pagename} = $page;
	$self->{column} = 0;
	$self->SUPER::parse($source);
}
sub columnlist {
	my $self = shift;
	if($self->{columnlist} eq ''){
		return "<p>コラムはありません</p>";
	} else {
		return "<ol>".$self->{columnlist}."</ol>";
	}
}

sub plugin{
	my $self   = shift;
	my $plugin = shift;
	return undef;
}

sub l_plugin{
	my $self   = shift;
	my $plugin = shift;
	
	if($plugin->{'command'} eq 'column'){
		$self->{column}++;
		$self->{columnlist} .= "<li>";
		if($self->{pagename} ne ''){
			$self->{columnlist} .= "（".Util::escapeHTML($self->{pagename})."）";
		}
		$self->{columnlist} .= "<a href=\"?page=".Util::url_encode($self->{pagename}).
			"#c".$self->{column}."\">".Util::escapeHTML($plugin->{'args'}->[1])."</a></li>";
	}
	return undef;
}

1;
