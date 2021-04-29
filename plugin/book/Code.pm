################################################################################
#
# <p>引数の内容をcodeタグで囲んで出力します。</p>
# <pre>
# {{code Util::escapeHTML()}}でHTMLタグのエスケープを行います。
# </pre>
# <p>上記の場合、出力されるHTMLは以下のようになります。</p>
# <pre>
# &lt;code&gt;Util::escapeHTML()&lt;/code&gt;でHTMLタグのエスケープを行います。
# </pre>
#
################################################################################
package plugin::book::Code;
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
# インラインメソッド
#==============================================================================
sub inline {
	my $self = shift;
	my $wiki = shift;
	my $text = shift;
	
	return '<code>'.Util::escapeHTML($text).'</code>';
}

1;
