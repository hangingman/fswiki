################################################################################
#
# <p>見出し3に付与することで見出し番号を付与するインラインプラグインです。</p>
# <pre>
# !{{title3}}見出し3
# </pre>
#
################################################################################
package plugin::book::Title3;
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
	my $self   = shift;
	my $wiki   = shift;
	my $anchor = shift;
	
	my $chapter = $wiki->get_plugin_instance('plugin::book::Chapter');
	my $title1 = $wiki->get_plugin_instance('plugin::book::Title1');
	my $title2 = $wiki->get_plugin_instance('plugin::book::Title2');
	
	$self->{'count'}++;
	
	if($anchor eq ''){
		return $chapter->{'chapter'}.'-'.$title1->{'count'}.'-'.$title2->{'count'}.'-'.$self->{'count'}.'. ';
	} else {
		return '<a name="'.Util::escapeHTML($anchor).'">'.$chapter->{'chapter'}.'-'.$title1->{'count'}.'-'.$title2->{'count'}.'-'.$self->{'count'}.'. </a>';
	}
}

#==============================================================================
# フックメソッド
#==============================================================================
sub hook {
	my $self = shift;
	$self->{'count'} = 0;
}

1;
