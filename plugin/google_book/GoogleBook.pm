package plugin::google_book::GoogleBook;
use strict;
use warnings;
###############################################################################
#
# <p>指定した書籍のプレビューをGoogleの埋め込みビュアーで表示します</p>
# <pre>
#   {{google_book asin}}
# </pre>
# オプションで埋め込みビュアーのサイズを指定することができます。
# 以下の例では幅650ピクセル、高さ400ピクセルでビュアーを表示します。
# デフォルトでは幅600ピクセル、高さ500としています。
# </p>
# <pre>
# {{google_book asin,w650,h400}}
# </pre>
#
###############################################################################

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
	my $self    = shift;
	my $wiki    = shift;
	my $asin    = shift;

	my @options = @_;
	my $width  = "600";
	my $height = "500";

	foreach my $option (@options){
		if($option =~ /^w([0-9]+)$/){
			$width = $1;
		} elsif($option =~ /^h([0-9]+)$/){
			$height = $1;
		}
	}

	$asin = Util::escapeHTML($asin);
	$script = <<EOS;
<script type="text/javascript" src="https://www.google.com/books/jsapi.js"></script>
<script type="text/javascript">
	google.books.load();

	function initialize() {
		var viewer = new google.books.DefaultViewer(document.getElementById('viewerCanvas${asin}'));
		viewer.load('ISBN:${asin}');
	}

	google.books.setOnLoadCallback(initialize);
</script>
qq(<div id="viewerCanvas${asin}" style="width: ${width}px; height: ${height}px"></div>)
EOS

	return $script;
}

1;
