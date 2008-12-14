################################################################################
#
# <p>blockquoteタグを出力する複数行プラグイン。</p>
# <pre>
# {{bq
# ここに記述した内容は引用テキストとして出力されます。
# 引数は複数行に渡って記述することができます。
# }}
# </pre>
# <p>表示は次のようになります。</p>
# <blockquote>
# <p>ここに記述した内容は引用テキストとして出力されます。</p>
# <p>引数は複数行に渡って記述することができます。</p>
# </blockquote>
#
################################################################################
package plugin::core::Blockquote;
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
sub block {
	my $self = shift;
	my $wiki = shift;
	my $text = shift;
	my $buf = "<blockquote>";
	foreach my $line (split(/(\r\n)|\n|\r/,Util::escapeHTML($text))){
		$buf .= "<p>$line<p>";
	}
	$buf .= "</blockquote>";
	return $buf;
}

1;
