################################################################################
#
# <p>ページにメモを記述するためのインラインプラグインです。</p>
# <pre>
# {{memo ここにメモを記述します。}}
# </pre>
# <p>
#   記述したメモは強調されて表示されます。
#   また、memolistプラグインを使用して一覧表示することができます。
# </p>
# <p>コメントした人の名前を第一引数で指定することもできます。</p>
# <pre>
# {{memo 名前,ここにメモを記述します。}}
# </pre>
# <p>
#   この場合、画面上には「<b>名前</b> - コメント」と表示されます。
#   またspanタグのclass属性に名前が追加されて出力されるので、
#   管理画面のスタイル設定で以下のようなCSSを追加しておくことで
#   ユーザによって色を変えることができます。
# </p>
# <pre>
# span.名前 {
#   background-color: #EEEEFF;
#   border: 1px solid #0000FF;
# }
# </pre>
#
################################################################################
package plugin::book::Memo;
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
	my $name = shift;
	my $text = shift;
	
	if($text eq ''){
		$text = $name;
		$name = '';
	}
	
	if($name ne ''){
		push(@{$self->{'memolist'}}, "[comment]".$name." - ".$text);
	} else {
		push(@{$self->{'memolist'}}, "[comment]".$text);
	}
	my @list = @{$self->{'memolist'}};
	
	if($name ne ''){
		return '<span class="memo '.Util::escapeHTML($name).'"><a name="todo-'.($#list + 1).'"></a><b>'.Util::escapeHTML($name).'</b> - '.Util::escapeHTML($text).'</span>';
	} else {
		return '<span class="memo"><a name="todo-'.($#list + 1).'"></a>'.Util::escapeHTML($text).'</span>';
	}
}

1;
