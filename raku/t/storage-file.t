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

nok $storage.page-exists('Missing'), 'missing page is not found';
$dir.add('Home.wiki').unlink;
$dir.add('Help%2FFSWiki.wiki').unlink;
$dir.add('..%2Foutside.wiki').unlink;
$dir.rmdir;

done-testing;
