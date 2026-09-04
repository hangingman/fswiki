use v6.d;
use Test;
use lib 'raku/lib';
use FSWiki::Core;
use FSWiki::Storage::Memory;
use FSWiki::HTTP::App;

my $core = FSWiki::Core.new(storage => FSWiki::Storage::Memory.new);
is save-page-response('Draft', "draft source\n", :$core),
    "saved\n",
    'save response reports success';
is $core.get-page('Draft'), "draft source\n",
    'save response persists through Core storage';

throws-like { save-page-response('', 'source', :$core) },
    Exception,
    'empty page names are rejected';

done-testing;
