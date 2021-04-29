################################################################################
#
# <p>見出しや図表へのリンクを出力するためのインラインプラグインです。</p>
# <p>引数にはtitle1〜title3プラグインやcaptionプラグインで記述した参照用のラベルを指定します。</p>
# <pre>
# !!!{{title1 installation}}インストール方法
# ...
# インストール方法については{{link installation}}を参照してください。
# </pre>
# <p>第2引数でページを指定することで、別ページの見出しや図表を参照することもできます。</p>
# <pre>
# インストール方法については{{link installation,Chapter1}}を参照してください。
# </pre>
#
################################################################################
package plugin::book::Link;
use strict;
use warnings;
#==============================================================================
# コンストラクタ
#==============================================================================
sub new {
	my $class = shift;
	my $self = {};
	my $self->{cache} = {};
	return bless $self,$class;
}

#==============================================================================
# インラインメソッド
#==============================================================================
sub inline {
	my $self   = shift;
	my $wiki   = shift;
	my $anchor = shift;
	my $page   = shift;
	
	$page = $wiki->get_CGI->param('page') unless $page;
	my $source = $wiki->get_page($page);
	
	unless(defined($self->{cache}->{$page})){
		$self->{cache}->{$page} = {};
		my $source = $wiki->get_page($page);

		my $text = '';
	
		my @lines = split(/\n/,$wiki->get_page($page));
		my $chapter = '';
		my $count = {};
		my $title1Count = 0;
		my $title2Count = 0;
		my $title3Count = 0;
		
		# TODO {{pre}}プラグイン内の記述は飛ばさないとダメ！！パーサを作らないとダメっぽい？
		foreach my $line (@lines){
			if($line =~ /^{{(chapter.+}})$/){
				my $plugin = $wiki->parse_inline_plugin($1);
				$chapter = $plugin->{'args'}->[0];
				$title1Count = 0;
				$title2Count = 0;
				$title3Count = 0;
				foreach my $key (keys(%$count)){
					$count->{$key} = 0;
				}
			} elsif($line =~ /^!!!{{(title1.+}})(.+)$/){
				my $plugin = $wiki->parse_inline_plugin($1);
				$title1Count++;
				$title2Count = 0;
				$title3Count = 0;
				$text= $chapter.'-'.$title1Count.'. '.Util::trim($2);
				$self->{cache}->{$page}->{$plugin->{'args'}->[0]} = $text;
				
			} elsif($line =~ /^!!{{(title2.+}})$/){
				my $plugin = $wiki->parse_inline_plugin($1);
				$title2Count++;
				$title3Count = 0;
				$text= $chapter.'-'.$title1Count.'-'.$title2Count.'. '.Util::trim($2);
				$self->{cache}->{$page}->{$plugin->{'args'}->[0]} = $text;
				
			} elsif($line =~ /^!{{(title3.+}})$/){
				my $plugin = $wiki->parse_inline_plugin($1);
				$title3Count++;
				$text= $chapter.'-'.$title1Count.'-'.$title2Count.'-'.$title3Count.'. '.Util::trim($2);
				$self->{cache}->{$page}->{$plugin->{'args'}->[0]} = $text;
				
			} elsif($line =~ /^{{(caption.+}})$/){
				my $plugin = $wiki->parse_inline_plugin($1);
				my $type = $plugin->{'args'}->[0];
				$count->{$type}++;
				$text = $type.$chapter.'-'.$count->{$type}.': '.Util::trim($plugin->{'args'}->[1]);
				$self->{cache}->{$page}->{$plugin->{'args'}->[2]} = $text;
			}
		}
	}
	if(defined($self->{cache}->{$page}->{$anchor})){
		my $text = $self->{cache}->{$page}->{$anchor};
		return '<a href="?page='.Util::url_encode($page).'#'.Util::escapeHTML($anchor).'" class="xref">'.Util::escapeHTML($text).'</a>';
	} else {
		return '<span class="xref-error">参照先が見つかりません！</span>';
	}
}

1;
