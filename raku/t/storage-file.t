use v6.d;
use Test;
use lib 'raku/lib';
use FSWiki::Storage::File;

my $dir = $*TMPDIR.add("fswiki-raku-storage-{$*PID}");
$dir.rmdir if $dir.e;
mkdir $dir;

my $storage = FSWiki::Storage::File.new(:$dir);
$storage.save-page('FrontPage', "!!!FreeStyle Wiki\n");
$storage.save-page('Help/FSWiki', 'help');

ok $storage.page-exists('FrontPage'), 'saved page exists';
is $storage.get-page('FrontPage'), "!!!FreeStyle Wiki\n", 'saved page is readable';
is $storage.get-page('Help/FSWiki'), 'help', 'page names with slash are encoded';
nok $storage.page-exists('Missing'), 'missing page is not found';

$dir.add('FrontPage.wiki').unlink;
$dir.add('Help%2FFSWiki.wiki').unlink;
$dir.rmdir;

done-testing;
