############################################################
#
# <p>FreeStyleWiki上でMarkdown記法での記入を可能にします。</p>
# <pre>
# {{markdown
# something markdown text
# anything markdown text
# }}
# </pre>
# <p>なお利用するには <a href="http://search.cpan.org/~bobtfish/Text-Markdown-1.000031/lib/Text/Markdown.pm">Text::Markdown</a> が必要です。<br />
#
# 2012.07.14 A.Tatsukawa [Website](http://ctyo.info)</p>
#
############################################################
package plugin::markdown::Markdown;

use strict;
use warnings;
use Text::Markdown qw/markdown/;
#===========================================================
# コンストラクタ
#===========================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#===========================================================
# コメントフォーム
#===========================================================
sub block {
    my $self        = shift;
    my $wiki        = shift;
    my $wiki_source = shift;
    return markdown($wiki_source);
}

1;
