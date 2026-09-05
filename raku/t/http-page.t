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

is edit-page-response('Draft', :$core),
    "<form method=\"post\" action=\"/page/Draft\"><textarea name=\"source\">draft source\n</textarea><button type=\"submit\">Save</button></form>",
    'edit page renders the current source';

is edit-page-response('NewPage', :$core),
    '<form method="post" action="/page/NewPage"><textarea name="source"></textarea><button type="submit">Save</button></form>',
    'edit page renders an empty form for a new page';

is edit-save-response('Draft', "changed\n", :$core),
    '<p>changed</p>',
    'edit save returns the rendered saved page';

$core.set-page-level('Private', 1);
throws-like { edit-page-response('Private', :$core) }, Exception,
    'edit page rejects hidden pages';
$core.freeze-page('Draft');
throws-like { edit-save-response('Draft', 'blocked', :$core) }, Exception,
    'edit save rejects frozen pages';

is create-page-response('Created', 'new source', :$core),
    '<p>new source</p>',
    'create page saves and renders a new page';
throws-like { create-page-response('Created', 'again', :$core) }, Exception,
    'create page rejects an existing page';

is diff-page-response('Draft', :$core),
    '<del>draft source</del><ins>changed</ins>',
    'diff page compares the previous backup with current source';

is remove-page-response('Created', :$core),
    "removed\n",
    'remove page deletes a page';
is $core.page-exists('Created'), False, 'removed page no longer exists';

is wiki-list-response(:$core),
    '<ul><li>Draft</li><li>Home</li></ul>',
    'wiki list reports remaining pages';

done-testing;
