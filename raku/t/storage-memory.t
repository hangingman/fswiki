use v6.d;
use Test;
use lib 'raku/lib';
use FSWiki::Storage::Memory;

my $storage = FSWiki::Storage::Memory.new(
    pages => { Home => 'Welcome to FSWiki.' }
);

ok $storage.page-exists('Home'), 'existing page is found';
nok $storage.page-exists('Missing'), 'missing page is not found';
is $storage.get-page('Home'), 'Welcome to FSWiki.', 'page can be read';
is $storage.get-page('Missing'), '', 'missing page reads as empty';

$storage.save-page('Draft', 'draft body');
is $storage.get-page('Draft'), 'draft body', 'saved page can be read';
ok $storage.page-exists('Draft'), 'saved page exists';

done-testing;
