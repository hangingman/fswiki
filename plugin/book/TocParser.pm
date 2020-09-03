###############################################################################
#
# bookプラグインに対応したアウトラインパーサ
#
###############################################################################
package plugin::book::TocParser;
use strict;
our @ISA;
use Wiki::HTMLParser;

@ISA = qw(Wiki::HTMLParser);

#==============================================================================
# コンストラクタ
#==============================================================================
sub new {
	my $class = shift;
	my $self  = Wiki::HTMLParser->new(shift);
	my $page  = shift;
	my $level = shift;
	
	if($level ne ""){
		$self->{'display_level'} = $level;
	} else {
		$self->{'display_level'} = 3;
	}
	
	$self->{'outline_html'}  = "";
	$self->{'outline_level'} =  0;
	$self->{'outline_cnt'}   =  0;
	$self->{'outline_fix'}   =  0;
	$self->{'pagename'}      = $page;
	$self->{'section_cnt'}   =  0;
	return bless $self,$class;
}

#==============================================================================
# ヘッドラインのみ抽出
#==============================================================================
sub l_headline {
	my $self  = shift;
	my $level = shift;
	my $obj   = shift;
	
	$level = $level + $self->{'outline_fix'};
	
	if($level > $self->{'display_level'}){
		$self->{outline_cnt}++;
		return;
	}
	
	my $text = &Util::delete_tag(join("",@$obj));
	
	if($level > $self->{outline_level}){
		while($level!=$self->{outline_level}){
			if($self->{'outline_close_'.($self->{outline_level})} == 1){
				$self->{outline_html} .= "</li>\n";
				$self->{'outline_close_'.($self->{outline_level})} = 0;
			}
			$self->{outline_html} .= "<ul class=\"outline\">\n";
			$self->{outline_level}++;
		}
	} elsif($level <= $self->{outline_level}){
		while($level-1  != $self->{outline_level}){
			if($self->{'outline_close_'.($self->{outline_level})} == 1){
				$self->{outline_html} .= "</li>\n";
				$self->{'outline_close_'.($self->{outline_level})} = 0;
			}
			if($level == $self->{outline_level}){
				last;
			}
			$self->{outline_html} .= "</ul>\n";
			$self->{outline_level}--;
		}
	} else {
		$self->{outline_html} .= "</li>\n";
	}
	
	$self->{'outline_close_'.$level} = 1;
	if($self->{'outline_fix'} == 1 && $level == 1){
		$self->{outline_html} .= "<li>$text";
	} else {
		$self->{outline_html} .= "<li><a href=\"?page=".Util::url_encode($self->{pagename})."#p".$self->{outline_cnt}."\">$text</a>";
		$self->{outline_cnt}++;
	}
}

#==============================================================================
# アウトライン表示用HTMLの取得
#==============================================================================
sub outline {
	my $self   = shift;
	my $source = shift;
	$self->parse($source);
	
	while($self->{outline_level} != 0){
		if($self->{'outline_close_'.($self->{outline_level})} == 1){
			$self->{outline_html} .= "</li>\n";
		}
		$self->{outline_html} .= "</ul>\n";
		$self->{outline_level}--;
	}
	
	return $self->{outline_html};
}

#==============================================================================
# プラグインの解析を行うと無限ループしてしまうため
#==============================================================================
sub plugin{
	my $self   = shift;
	my $plugin = shift;
	
	if($plugin->{'command'} eq 'title1'){
		$self->{'title1'}++;
		$self->{'title2'} = 0;
		$self->{'title3'} = 0;
		return $self->{'chapter'}.'-'.$self->{'title1'}.'. ';
		
	} elsif($plugin->{'command'} eq 'title2'){
		$self->{'title2'}++;
		$self->{'title3'} = 0;
		return $self->{'chapter'}.'-'.$self->{'title1'}.'-'.$self->{'title2'}.'. ';
		
	} elsif($plugin->{'command'} eq 'title3'){
		$self->{'title3'}++;
		return $self->{'chapter'}.'-'.$self->{'title1'}.'-'.$self->{'title2'}.'-'.$self->{'title3'}.'. ';
		
	}
	return undef;
}

#==============================================================================
# プラグインの解析を行うと無限ループしてしまうため
#==============================================================================
sub l_plugin{
	my $self   = shift;
	my $plugin = shift;
	
	if($plugin->{'command'} eq 'chapter'){
		$self->{'chapter'} = $plugin->{'args'}->[0];
		return undef;
	}
	if($plugin->{'command'} eq 'section'){
		if($self->{'outline_fix'} == 0){
			$self->{'outline_fix'} = 1;
			$self->{'display_level'}++;
		}
		$self->{'section_cnt'}++;
		$self->l_headline(0, [$plugin->{'args'}->[0]]);
		return undef;
	}
	
	# outline以外の場合のみ処理を行う
	if($plugin->{command} ne "outline"){
		my $info = $self->{wiki}->get_plugin_info($plugin->{command});
		if($info->{FORMAT} eq "WIKI"){
			return $self->SUPER::l_plugin($plugin);
		}
	} else {
		return undef;
	}
}

1;
