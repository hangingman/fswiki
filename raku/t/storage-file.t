use v6.d;
use Test;
use lib 'raku/lib';
use FSWiki::Storage::File;

my $dir = $*TMPDIR.add("fswiki-storage-{$*PID}");
$dir.rmdir if $dir.d;
my $storage = FSWiki::Storage::File.new(dir => $dir);

$storage.save-page('Home', "!!!FreeStyle Wiki\n");
ok $storage.page-exists('Home'), 'saved page exists';
is $storage.get-page('Home'), "!!!FreeStyle Wiki\n", 'saved page is readable';

$storage.save-page('Help/FSWiki', 'help');
ok $dir.add('Help%2FFSWiki.wiki').f, 'page names with slash are encoded';
is $storage.get-page('Help/FSWiki'), 'help', 'encoded page is readable';

$storage.save-page('../outside', 'safe');
ok !$dir.parent.add('outside.wiki').f, 'page names cannot escape storage directory';
is $storage.get-page('../outside'), 'safe', 'unsafe page name remains readable';

is-deeply $storage.get-page-list, <../outside Help/FSWiki Home>, 'pages are listed by name';
is $storage.get-page-list(:max(2)).elems, 2, 'page list honors max';
ok $storage.get-last-modified('Home') > 0, 'physical modification time is available';
ok $storage.get-last-modified2('Home') > 0, 'logical modification time is available';

sleep 1;
$storage.save-page('Home', 'updated');
is $storage.get-page-list(:sort<last_modified>)[0], 'Home', 'pages can be listed newest first';
is $storage.get-backup('Home'), "!!!FreeStyle Wiki\n", 'previous page is backed up';
is $storage.backup-type, 'single', 'file storage uses single backups by default';
$storage.delete-backup-files('Home');
is $storage.get-backup('Home'), '', 'backups can be deleted';

nok $storage.page-exists('Missing'), 'missing page is not found';
$dir.add('Home.wiki').unlink;
$dir.add('Help%2FFSWiki.wiki').unlink;
$dir.add('..%2Foutside.wiki').unlink;
$dir.add('backup').rmdir;
$dir.rmdir;

done-testing;
