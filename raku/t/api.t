use v6.d;
use Test;
use JSON::Fast;
use lib 'raku/lib';
use FSWiki::Core;
use FSWiki::HTTP::App;

my $core = FSWiki::Core.new;
$core.save-page('Home', 'Welcome to FSWiki.');
my &handler = -> $wiki, %input { { page => %input<page>, source => $wiki.get-page(%input<page>) } };
$core.add-handler('SOURCE', &handler, api => {
    method => 'GET',
    path => '/api/source',
});

is-deeply $core.api-info('SOURCE'), {
    method => 'GET',
    path => '/api/source',
}, 'handler exposes explicit API metadata';

is-deeply $core.call-handler('SOURCE', { page => 'Home' }),
    { page => 'Home', source => 'Welcome to FSWiki.' },
    'API handler receives input through Core';

is api-source-response('Home', :$core),
    to-json({ page => 'Home', source => 'Welcome to FSWiki.' }),
    'registered API handler produces JSON';

done-testing;
