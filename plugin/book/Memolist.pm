################################################################################
#
# <p>memoプラグイン、addプラグイン、delプラグインで記述した内容の一覧を表示します。</p>
# <pre>
# {{memolist}}
# </pre>
#
################################################################################
package plugin::book::Memolist;
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
	my $self   = shift;
	my $wiki   = shift;
	my $plugin = $wiki->get_plugin_instance('plugin::book::Memo');
	
	my $buf = '';
	my $count = 1;
	
	foreach my $memo (@{$plugin->{'memolist'}}){
		$buf .= '<li><a href="#todo-'.$count.'">';
		$icon = '';
		if($memo =~ /^\[comment\]/){
			$icon = 'comment.png';
		} elsif($memo =~ /^\[add\]/){
			$icon = 'add.png';
		} elsif($memo =~ /^\[delete\]/){
			$icon = 'delete.png';
		}
		if($icon ne ''){
			$buf .= '<img src="'.$wiki->{book_plugin_path_prefix}.'plugin/book/icons/'.$icon.'" style="border: 0px; position: relative; top: 4px; padding-right: 2px;">';
			$memo =~ s/^\[.+?\]//;
		}
		$buf .= Util::escapeHTML($memo).'</a></li>';
		$count++;
	}
	
	if($buf eq ''){
		return '<p>メモはありません</p>';
	} else {
		return '<ol>'.$buf.'</ol>';
	}
}

1;
