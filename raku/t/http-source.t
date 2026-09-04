use v6.d;
use Test;
use lib 'raku/lib';
use FSWiki::HTTP::App;

is source-response('Home'),
    '<pre>Welcome to FSWiki.</pre>',
    'source response passes through Core hook';

is source-response('Missing'),
    '<pre></pre>',
    'missing page has an empty source';

done-testing;
