################################################################################
#
# <p>図表番号などを出力するためのパラグラフプラグインです。</p>
# <pre>
# {{caption 表,メソッド一覧}}
# </pre>
# <p>以下のようなHTMLが出力されます。</p>
# <pre>
# &gt;div class="caption"&lt;表1: メソッド一覧&gt;/div&lt;
# </pre>
# <p>
#   linkプラグインを使用して相互参照をはる場合は第3引数にリンク用のラベルを記述します。
#   linkプラグインではこのラベルを指定してリンクを作成します。
# </p>
# <pre>
# {{caption 表,メソッド一覧,method_list}}
# ...
# 詳細については{{link method_list}}を参照してください。
# </pre>
#
################################################################################
package plugin::book::Caption;
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
	my $self    = shift;
	my $wiki    = shift;
	my $type    = shift;
	my $caption = shift;
	my $anchor  = shift;
	
	$self->{$type}++;
	
	my $plugin = $wiki->get_plugin_instance('plugin::book::Chapter');
	
	if($anchor eq ''){
		return '<div class="caption">'.
			Util::escapeHTML($type).$plugin->{'chapter'}.'-'.$self->{$type}.': '.
			Util::escapeHTML($caption).'</div>';
	} else {
		return '<div class="caption"><a name="'.Util::escapeHTML($anchor).'">'.
			Util::escapeHTML($type).$plugin->{'chapter'}.'-'.$self->{$type}.': '.
			Util::escapeHTML($caption).'</a></div>';
	}
}

#==============================================================================
# フックメソッド
#==============================================================================
sub hook {
	my $self = shift;
	foreach my $key (keys(%$self)){
		$self->{$key} = 0;
	}
}

1;
