use v6.d;
use Test;
use lib 'raku/lib';
use FSWiki::Parser::Wiki;

my $parser = FSWiki::Parser::Wiki.new;

subtest 'block state transitions render useful HTML' => {
    my $source = "!!! Title\n\n* one\n** nested\n* two\n\n" ~
        ":term:definition\n\n,one,\"two, still\",three\n\n" ~
        "  pre <x>\n\n----\n\n\"\"quoted\n\"\"again";
    my $html = $parser.render($source, {});
    ok $html.contains('<h1> Title</h1>'), 'headings are emitted at the expected level';
    ok $html.contains('<ul><li> one<ul><li> nested</li></ul></li><li> two</li></ul>'), 'nested lists close in state order';
    ok $html.contains('<dl><dt>term</dt><dd>definition</dd></dl>'), 'definitions form a definition list';
    ok $html.contains('<td>two, still</td>'), 'quoted table commas stay in one cell';
    ok $html.contains('<pre>  pre &lt;x&gt;</pre>'), 'preformatted text is escaped';
    ok $html.contains('<hr>'), 'horizontal rules terminate the prior block';
    ok $html.contains('<blockquote><p>quoted</p><p>again</p></blockquote>'), 'consecutive quote lines share a block';
};

subtest 'inline scanner handles links, formatting, escaping, and malformed markup' => {
    my %context =
        'page-link' => -> $page, $label { '<page page="' ~ $page ~ '">' ~ $label ~ '</page>' },
        'url-link' => -> $url, $label { '<url>' ~ $label ~ '</url>' };
    my $html = $parser.render("[[Label|Home]] [Site|https://example.test] https://example.test/x " ~
        "'''bold''' ''italic'' __under__ ==gone== & <tag> \\[[literal]] [[unclosed", %context);
    ok $html.contains('<page page="Home">Label</page>'), 'page links use the injected callback';
    ok $html.contains('<url>Site</url>') && $html.contains('<url>https://example.test/x</url>'), 'explicit and bare URLs are scanned';
    ok $html.contains('<strong>bold</strong>') && $html.contains('<em>italic</em>') && $html.contains('<ins>under</ins>') && $html.contains('<del>gone</del>'), 'inline styles are cursor-scanned';
    ok $html.contains('&amp; &lt;tag&gt;'), 'plain text is HTML escaped';
    ok $html.contains('[[literal]]'), 'backslash escapes wiki syntax';
    ok $html.contains('[[unclosed'), 'unclosed markup remains safe plain text';
};

done-testing;
