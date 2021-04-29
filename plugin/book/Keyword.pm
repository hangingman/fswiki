################################################################################
#
# <p>キーワードを記述するためのプラグインです。</p>
#
################################################################################
package plugin::book::Keyword;
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
# パラグラフメソッド
#==============================================================================
sub paragraph {
	my $self = shift;
	my $wiki = shift;
	my @keywords = @_;
	my $buf = "";
	
	foreach my $keyword (@keywords){
		$buf .= ' | ' if($buf ne '');
		$buf .= '<a href="?action=SEARCH&t=and&c=true&word='.Util::url_encode($keyword).'">'.Util::escapeHTML($keyword).'</a>';
	}
	
	return '<div class="keyword"><span class="keyword">'.$buf.'</span></div>';
}

1;
