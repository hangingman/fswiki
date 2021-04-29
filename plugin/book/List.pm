################################################################################
#
# <p>プログラムリストをシンタックスハイライトして出力するための複数行プラグイン。</p>
# <pre>
# {{list
# public class HelloWorld {
# &nbsp;&nbsp;public static void main(String[] args){
# &nbsp;&nbsp;&nbsp;&nbsp;System.out.println("Hello World!");
# &nbsp;&nbsp;}
# }
# }}
# </pre>
# <p>
#   シンタックスハイライトには<a href="http://code.google.com/p/google-code-prettify/">google-code-prettify</a>を使用します。
#   表示は次のようになります。
# </p>
# <link href="plugin/book/google-code-prettify/sunburst.css" type="text/css" rel="stylesheet" />
# <script type="text/javascript" src="plugin/book/google-code-prettify/prettify.js"></script>
# <script type="text/javascript">window.onload = function(){ prettyPrint(); }</script>
# <pre class="prettyprint">
# public class HelloWorld {
# &nbsp;&nbsp;public static void main(String[] args){
# &nbsp;&nbsp;&nbsp;&nbsp;System.out.println("Hello World!");
# &nbsp;&nbsp;}
# }
# <p>
#   また、プログラムを&lt;&lt;&lt;...&gt;&gt;&gt;で囲むと囲んだ部分が強調して表示されます。
# </p>
# </pre>
#
################################################################################
package plugin::book::List;
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
# ブロックメソッド
#==============================================================================
sub block {
	my $self = shift;
	my $wiki = shift;
	my $code = shift;
	my $buf  = '';
	
	$code = Util::escapeHTML($code);
	$code =~ s/&lt;&lt;&lt;((.|\s)+?)&gt;&gt;&gt;/<strong>$1<\/strong>/g;
	
	return $buf.'<pre class="prettyprint">'.$code.'</pre>';
}

1;
