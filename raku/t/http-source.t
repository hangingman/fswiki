use v6.d;
use Test;
use lib 'raku/lib';
use FSWiki::Core;
use FSWiki::Storage::Memory;
use FSWiki::HTTP::App;

my $core = FSWiki::Core.new(storage => FSWiki::Storage::Memory.new);
$core.save-page('Markup', "!!! Title\n\nHello [[world|Home]].");
is source-response('Markup', :$core),
    "<h1> Title</h1>\n<p>Hello <a href=\"/source/Home\" class=\"wikipage\">world</a>.</p>",
    'source response renders Wiki markup through the Core processor';

$core.save-page('Private', 'secret');
$core.set-page-level('Private', 1);
is source-response('Private', :$core), '',
    'source response does not render pages hidden from the current user';

is source-response('Home'),
    '<p>Welcome to FSWiki.</p>',
    'source response renders the default page';

is source-response('Missing'),
    '',
    'missing page has an empty source';

$core.save-page('Unsafe', '<script>alert("x")</script> & text');
is source-response('Unsafe', :$core),
    '<p>&lt;script&gt;alert(&quot;x&quot;)&lt;/script&gt; &amp; text</p>',
    'source response escapes HTML characters';

is list-pages-response(:$core),
    '<ul><li><a href="/source/Home">Home</a></li><li><a href="/source/Markup">Markup</a></li><li><a href="/source/Unsafe">Unsafe</a></li></ul>',
    'page list renders visible pages';

is raw-page-response('Markup', :$core),
    "!!! Title\n\nHello [[world|Home]].",
    'raw page returns source without rendering';

is pre-page-response('Unsafe', :$core),
    '<pre>&lt;script&gt;alert(&quot;x&quot;)&lt;/script&gt; &amp; text</pre>',
    'pre page renders escaped source';

is blockquote-response('Markup', :$core),
    '<blockquote><p>!!! Title</p><p></p><p>Hello [[world|Home]].</p></blockquote>',
    'blockquote page renders source lines as a quote';

done-testing;
