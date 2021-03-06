###############################################################################
#
# <p>コラムを記述するためのブロックプラグインです。</p>
# <pre>
# {{column コラムのタイトル
# コラム本文
# }}
# </pre>
# <p>コラム本文はWiki形式で記述することができます。</p>
#
###############################################################################
package plugin::book::Column;
use strict;
use warnings;
#==============================================================================
# コンストラクタ
#==============================================================================
sub new {
	my $class = shift;
	my $self = {};
	$self->{'count'} = 0;
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
	
	$self->{'count'}++;
	
	return '<div class="column"><div class="column-title">'.
		'<a name="c'.($self->{'count'} - 1).'">コラム: '.Util::escapeHTML($title).'</a></div>'.
		'<div class="column-body">'.$wiki->process_wiki($content).'</div></div>';
}

1;
