use v6.d;
use Test;
use JSON::Fast;
use lib 'raku/lib';
use FSWiki::Core;
use FSWiki::HTTP::App;

my $core = FSWiki::Core.new;
$core.save-page('Home', 'Welcome to FSWiki.');
register-api-handlers($core);

is-deeply $core.api-info('SOURCE'), {
    method => 'GET',
    path => '/api/source',
}, 'handler exposes explicit API metadata';

is-deeply $core.call-handler('SOURCE', { page => 'Home' }),
    { page => 'Home', source => 'Welcome to FSWiki.' },
    'API handler receives input through Core';

is-deeply from-json(api-source-response('Home', :$core)),
    { page => 'Home', source => 'Welcome to FSWiki.' },
    'registered API handler produces JSON';

is-deeply $core.api-info('SAVE_PAGE'), {
    method => 'POST',
    path => '/api/page/{page}',
}, 'save handler exposes explicit API metadata';
$core.call-handler('SAVE_PAGE', { page => 'Draft', source => 'json source' });
is $core.get-page('Draft'), 'json source',
    'JSON save handler persists through Core storage';

throws-like { $core.call-handler('SAVE_PAGE', { page => '', source => 'bad' }) },
    Exception,
    'JSON save handler rejects an empty page name';

done-testing;
