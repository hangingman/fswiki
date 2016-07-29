###############################################################################
#
# <p>関連、利用例を記述するためのプラグインです。</p>
# <p>内容はWiki形式の文字列で記述できますが、以下のように箇条書きを使用してください。</p>
# <pre>
# {{box 関連
# *{{link SETUP_ECLIPSE}}
# }}
# {{box 利用例
# *コマンドラインでScalaプログラムを実行した場合
# }}
# </pre>
#
###############################################################################
package plugin::book::Box;
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
	my $self    = shift;
	my $wiki    = shift;
	my $content = shift;
	my $title   = shift;
	
	return '<table class="box"><tr><th>'.Util::escapeHTML($title).'</th>'.
		'<td>'.$wiki->process_wiki($content).'</td></tr></table>';
}

1;
