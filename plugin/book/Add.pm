################################################################################
#
# <p>ページに追加した部分を示すためのインラインプラグインです。</p>
# <pre>
# {{add ここに追加する内容を記述します。}}
# </pre>
# <p>
#   追加した内容は赤字 + 下線で表示されます。
#   また、memolistプラグインを使用して一覧表示することができます。
# </p>
#
################################################################################
package plugin::book::Add;
use strict;
use warnings;
#==============================================================================
# コンストラクタ
#==============================================================================
sub new {
	my $class = shift;
	my $self = {};
	$self->{'todo'} = [];
	return bless $self,$class;
}

#==============================================================================
# パラグラフメソッド
#==============================================================================
sub inline {
	my $self = shift;
	my $wiki = shift;
	my $text = shift;
	
	my $plugin = $wiki->get_plugin_instance('plugin::book::Memo');
	push(@{$plugin->{'memolist'}}, "[add]".$text);
	my @list = @{$plugin->{'memolist'}};
	
	return '<span class="add"><a name="todo-'.($#list + 1).'"></a>'.Util::escapeHTML($text).'</span>';
}

1;
