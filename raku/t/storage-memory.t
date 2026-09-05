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
$storage.set-page-level('Draft', 2);
is $storage.get-page-level('Draft'), 2, 'page level is stored';
is $storage.get-page-level('Home'), 0, 'page level defaults to public';
$storage.freeze-page('Draft');
ok $storage.is-freeze('Draft'), 'page can be frozen';
is-deeply $storage.get-freeze-list, ('Draft',).List, 'freeze list is available';
$storage.un-freeze-page('Draft');
nok $storage.is-freeze('Draft'), 'page can be unfrozen';

is $storage.get-page-list.join('|'), 'Draft|Home', 'pages are sorted by name';
is $storage.get-page-list(:sort<name>, :max(1)).join('|'), 'Draft', 'page list honors max';
is $storage.get-page-list({ sort => 'name', max => 1 }).join('|'), 'Draft',
    'page list accepts an option hash';

my $home-physical = $storage.get-last-modified('Home');
my $home-logical = $storage.get-last-modified2('Home');
ok $home-physical > 0, 'physical modification timestamp is available';
is $home-logical, $home-physical, 'logical timestamp initially matches physical timestamp';

$storage.save-page('Home', 'updated welcome');
ok $storage.get-last-modified('Home') >= $home-physical,
    'physical timestamp changes on save';
ok $storage.get-last-modified2('Home') >= $home-logical,
    'logical timestamp changes on save';
is $storage.get-page-list(:sort<last_modified>).join('|'), 'Home|Draft',
    'pages are sorted by logical last-modified time';

is $storage.backup-type, 'single', 'memory storage uses single backups';
is $storage.get-backup('Home'), 'Welcome to FSWiki.', 'previous page source is backed up';
$storage.delete-backup-files('Home');
is $storage.get-backup('Home'), '', 'backup can be deleted';

done-testing;
