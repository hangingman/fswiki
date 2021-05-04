############################################################
#
# FreeStyleWiki上でMarkdown記法での記入を可能にします。
#
############################################################
package plugin::markdown::Install;
use strict;
use warnings;

sub install {
    my Wiki $wiki = shift;
    $wiki->add_block_plugin("markdown", "plugin::markdown::Markdown", "HTML");
}

1;
