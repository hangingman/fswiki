use v6.d;
use Test;
use lib 'raku/lib';
use FSWiki::Core;
use FSWiki::Storage::Memory;
use FSWiki::HTTP::App;

is source-response('Home'),
    '<pre>Welcome to FSWiki.</pre>',
    'source response passes through Core hook';

is source-response('Missing'),
    '<pre></pre>',
    'missing page has an empty source';

my $core = FSWiki::Core.new(storage => FSWiki::Storage::Memory.new);
$core.save-page('Unsafe', '<script>alert("x")</script> & text');
is source-response('Unsafe', :$core),
    '<pre>&lt;script&gt;alert(&quot;x&quot;)&lt;/script&gt; &amp; text</pre>',
    'source response escapes HTML characters';

done-testing;
