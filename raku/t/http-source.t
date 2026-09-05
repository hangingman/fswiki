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

done-testing;
