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
    schema => { page => { required => True, type => 'Str' } },
}, 'handler exposes explicit API metadata';

is-deeply $core.call-handler('SOURCE', { page => 'Home' }),
    { page => 'Home', source => 'Welcome to FSWiki.' },
    'API handler receives input through Core';
is-deeply $core.validate-api-input('SAVE_PAGE', { page => 'Draft', source => 'json source', extra => 1 }),
    { page => 'Draft', source => 'json source' },
    'API validation returns normalized schema fields';

is-deeply from-json(api-source-response('Home', :$core)),
    { page => 'Home', source => 'Welcome to FSWiki.' },
    'registered API handler produces JSON';

is-deeply $core.api-info('SAVE_PAGE'), {
    method => 'POST',
    path => '/api/page/{page}',
    schema => {
        page => { required => True, type => 'Str' },
        source => { required => True, type => 'Str' }
    },
}, 'save handler exposes explicit API metadata';
$core.call-handler('SAVE_PAGE', { page => 'Draft', source => 'json source' });
is $core.get-page('Draft'), 'json source',
    'JSON save handler persists through Core storage';

throws-like { $core.call-handler('SAVE_PAGE', { page => '', source => 'bad' }) },
    Exception,
    'JSON save handler rejects an empty page name';

throws-like { $core.call-handler('SOURCE') }, Exception,
    'source validation rejects a missing page', message => /'page is required'/;
throws-like { $core.call-handler('SAVE_PAGE', { page => 'Draft' }) }, Exception,
    'save validation rejects a missing source', message => /'source is required'/;
throws-like { $core.call-handler('SAVE_PAGE', { page => 12, source => 'bad' }) }, Exception,
    'save validation rejects a wrong page type', message => /'page must be a string'/;
throws-like { $core.call-handler('SAVE_PAGE', { page => 'Draft', source => 12 }) }, Exception,
    'save validation rejects a wrong source type', message => /'source must be a string'/;

is-deeply from-json(api-source-response(12, :$core)),
    { error => { code => 'validation-error', message => 'Invalid API input: page must be a string' } },
    'source API returns the unified validation error shape';
is-deeply from-json(api-save-page-response('Draft', Nil, :$core)),
    { error => { code => 'validation-error', message => 'Invalid API input: source is required' } },
    'save API returns the unified missing-input error shape';

subtest 'protected API handlers use Core permission checks before invocation' => {
    my $protected = FSWiki::Core.new;
    my $calls = 0;
    $protected.add-user-handler('SOURCE', -> $wiki, %input { $calls++; { page => 'secret' } }, api => {
        method => 'GET', path => '/api/source',
        schema => { page => { required => True, type => 'Str' } }
    });

    is-deeply from-json(api-source-response('Home', :core($protected))),
        { error => { code => 'permission-denied', message => 'Permission denied' } },
        'denied API calls return a permission error';
    is $calls, 0, 'denied API handler is not invoked';
};

throws-like { $core.validate-api-input('MISSING', {}) }, Exception,
    'unknown API action is rejected clearly', message => /'Unknown action'/;

done-testing;
