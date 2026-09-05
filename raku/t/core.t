use v6.d;
use Test;
use lib 'raku/lib';
use FSWiki::Core;

subtest 'hooks run in registration order and receive event arguments' => {
    my $core = FSWiki::Core.new;
    my @events;

    $core.add-hook('save-after', -> $wiki, $name, |args {
        @events.push(['first', $name, |args]);
    });
    $core.add-hook('save-after', -> $wiki, $name, |args {
        @events.push(['second', $name, |args]);
    });

    $core.do-hook('save-after', 'Home', 'body');

    is-deeply @events,
        [['first', 'save-after', 'Home', 'body'],
         ['second', 'save-after', 'Home', 'body']],
        'hooks preserve registration order and arguments';
};

subtest 'plugin metadata has a type and normalized format' => {
    my $core = FSWiki::Core.new;
    my &plugin = -> |args { 'ok' };

    $core.add-inline-plugin('include', &plugin, 'wiki');
    $core.add-paragraph-plugin('note', &plugin);
    $core.add-block-plugin('table', &plugin, 'html');

    is-deeply $core.plugin-info('include'),
        { CLASS => &plugin, TYPE => 'inline', FORMAT => 'WIKI' };
    is-deeply $core.plugin-info('note'),
        { CLASS => &plugin, TYPE => 'paragraph', FORMAT => 'HTML' };
    is-deeply $core.plugin-info('table'),
        { CLASS => &plugin, TYPE => 'block', FORMAT => 'HTML' };
};

subtest 'action handlers retain permission and return handler result' => {
    my $core = FSWiki::Core.new;
    $core.add-user('admin', 'admin-pass', 0);

    $core.add-handler('LIST', -> $wiki { 'list' });
    $core.add-user-handler('EDIT', -> $wiki { 'edit' });
    $core.add-admin-handler('ADMIN', -> $wiki { 'admin' });

    is $core.call-handler('LIST'), 'list';
    $core.set-login-info($core.login-check('admin', 'admin-pass'));
    is $core.call-handler('EDIT'), 'edit';
    is $core.call-handler('ADMIN'), 'admin';
    is-deeply $core.handler-permission('LIST'), 'public';
    is-deeply $core.handler-permission('EDIT'), 'user';
    is-deeply $core.handler-permission('ADMIN'), 'admin';
};

subtest 'users can be registered and checked by exact credentials' => {
    my $core = FSWiki::Core.new;

    nok $core.user-exists('alice'), 'unknown user does not exist';
    $core.add-user('alice', 'secret', 1);
    ok $core.user-exists('alice'), 'registered user exists';
    is-deeply $core.login-check('alice', 'secret'),
        { id => 'alice', pass => 'secret', type => 1 },
        'matching credentials return login info';
    nok $core.login-check('alice', 'wrong'), 'wrong password is rejected';
    nok $core.login-check('unknown', 'secret'), 'unknown user is rejected';
};

subtest 'login state can be set, read, and cleared' => {
    my $core = FSWiki::Core.new;
    my %login := { id => 'alice', type => 1 };

    nok $core.get-login-info.defined, 'login state starts empty';
    $core.set-login-info(%login);
    is-deeply $core.get-login-info, %login, 'login state is available';
    $core.logout;
    nok $core.get-login-info.defined, 'logout clears login state';
};

subtest 'handler permissions deny before invocation and allow the right users' => {
    my $core = FSWiki::Core.new;
    my $user-calls = 0;
    my $admin-calls = 0;

    $core.add-handler('PUBLIC', -> $wiki { 'public' });
    $core.add-user-handler('USER', -> $wiki { $user-calls++; 'user' });
    $core.add-admin-handler('ADMIN', -> $wiki { $admin-calls++; 'admin' });

    is $core.call-handler('PUBLIC'), 'public', 'public handler is available anonymously';
    throws-like { $core.call-handler('USER') }, Exception,
        'user handler rejects anonymous callers', message => /'Login required'/;
    is $user-calls, 0, 'denied user handler was not invoked';
    throws-like { $core.call-handler('ADMIN') }, Exception,
        'admin handler rejects anonymous callers', message => /'Admin permission required'/;
    is $admin-calls, 0, 'denied admin handler was not invoked';

    $core.set-login-info({ id => 'alice', type => 1 });
    is $core.call-handler('USER'), 'user', 'ordinary user can call user handler';
    throws-like { $core.call-handler('ADMIN') }, Exception,
        'ordinary user cannot call admin handler', message => /'Admin permission required'/;
    is $admin-calls, 0, 'ordinary-user denial does not invoke admin handler';

    $core.set-login-info({ id => 'admin', type => 0 });
    is $core.call-handler('ADMIN'), 'admin', 'admin can call admin handler';
    is $admin-calls, 1, 'admin handler is invoked once';
};

subtest 'page visibility and freezing use the current login level' => {
    my $core = FSWiki::Core.new;

    ok $core.can-show('Home'), 'public pages are visible anonymously';
    $core.set-page-level('Home', 1);
    nok $core.can-show('Home'), 'logged-in pages are hidden anonymously';
    nok $core.can-modify-page('Home'), 'hidden pages cannot be modified';

    $core.set-login-info({ id => 'alice', type => 1 });
    ok $core.can-show('Home'), 'ordinary users can see level-one pages';
    ok $core.can-modify-page('Home'), 'ordinary users can modify visible pages';
    $core.freeze-page('Home');
    nok $core.can-modify-page('Home'), 'ordinary users cannot modify frozen pages';
    ok $core.is-freeze('Home'), 'page is frozen';
    is-deeply $core.get-freeze-list, ('Home',).List, 'freeze list contains the page';

    $core.set-login-info({ id => 'admin', type => 0 });
    ok $core.can-show('Home'), 'admins can see level-one pages';
    ok $core.can-modify-page('Home'), 'admins can modify frozen pages';
    $core.un-freeze-page('Home');
    nok $core.is-freeze('Home'), 'page can be unfrozen';
};

subtest 'plugin lifecycle caches instances and records only successful installs' => {
    my $core = FSWiki::Core.new;
    my $installs = 0;
    my $instances = 0;

    ok $core.install-plugin('sample', -> $wiki { $installs++; Nil }), 'successful install returns true';
    ok $core.is-installed('sample'), 'successful install is recorded';
    is $installs, 1, 'installer runs once';
    throws-like { $core.install-plugin('broken', -> $wiki { die 'failed' }) }, Exception,
        'installer failure is propagated';
    nok $core.is-installed('broken'), 'failed install is not recorded';
    throws-like { $core.install-plugin('', -> { Nil }) }, Exception,
        'empty plugin name is rejected';

    my $first = $core.get-plugin-instance('sample', -> { $instances++; { id => $instances } });
    my $second = $core.get-plugin-instance('sample', -> { $instances++; { id => $instances } });
    is-deeply $first, $second, 'plugin instance is cached';
    is $instances, 1, 'instance factory runs once';
};

subtest 'format plugins register, sort, cache, convert, and fall back' => {
    class FormatPlugin {
        has $.instances is rw;

        method convert-to-fswiki($source) { "to:$source" }
        method convert-to-fswiki-line($source) { "line-to:$source" }
        method convert-from-fswiki($source) { "from:$source" }
        method convert-from-fswiki-line($source) { "line-from:$source" }
    }
    class EmptyFormatPlugin { }

    my $core = FSWiki::Core.new;
    my $created = 0;
    $core.add-format-plugin('Zeta', -> { $created++; FormatPlugin.new });
    $core.add-format-plugin('Alpha', EmptyFormatPlugin.new);

    is-deeply $core.get-format-names, ('Alpha', 'FSWiki', 'Zeta').List,
        'format names include FSWiki and are sorted';
    is $core.convert-to-fswiki("a\r\nb", 'Zeta'), "to:a\nb",
        'full conversion normalizes line endings';
    is $core.convert-to-fswiki("a\r\nb", 'Zeta', inline => True), "line-to:a\nb",
        'inline conversion uses the line method';
    is $core.convert-from-fswiki("a\r\nb", 'Zeta'), "from:a\nb",
        'reverse full conversion uses the reverse method';
    is $core.convert-from-fswiki("a\r\nb", 'Zeta', inline => True), "line-from:a\nb",
        'reverse inline conversion uses the reverse line method';
    is $created, 1, 'factory result is cached';
    is $core.convert-to-fswiki('unchanged', 'Unknown'), 'unchanged',
        'unknown format falls back to source';
    is $core.convert-to-fswiki('unchanged', 'Alpha', inline => True), 'unchanged',
        'missing conversion method falls back to source';
    is $core.convert-to-fswiki("a\r\nb", 'FSWiki'), "a\r\nb",
        'built-in format returns source unchanged';
};

subtest 'edit format defaults to FSWiki and can be selected' => {
    my $core = FSWiki::Core.new;
    is $core.get-edit-format, 'FSWiki', 'default edit format is FSWiki';
    $core.set-edit-format('Markdown');
    is $core.get-edit-format, 'Markdown', 'selected edit format is returned';
    is $core.get-edit-format(from => True), 'Markdown', 'optional from flag is accepted';
};

subtest 'plugin menus and editform plugins are ordered and menus update' => {
    my $core = FSWiki::Core.new;
    $core.add-editform-plugin('low', 1);
    $core.add-editform-plugin('high', 10);
    is-deeply $core.get-editform-plugins».<plugin>, ('high', 'low').List,
        'editform plugins sort by descending weight';
    $core.add-admin-menu('Admin low', '/low', 1, 'low');
    $core.add-user-menu('User high', '/high', 5, 'high');
    is-deeply $core.get-admin-menu».<label>, ('User high', 'Admin low').List,
        'admin menu entries sort by descending weight';
    $core.add-menu('Home', '/old', 1, False);
    $core.add-menu('Help', '/help', 5, True);
    $core.add-menu('Home', '/new', 9, True);
    is-deeply $core.get-menu».<name>, ('Home', 'Help').List, 'same-name menu entries are updated';
    is-deeply $core.get-menu[0], { name => 'Home', href => '/new', weight => 9, nofollow => True },
        'updated menu entry replaces its values';
};

subtest 'processor registry makes Wiki replaceable without Core changes' => {
    my $core = FSWiki::Core.new;
    is $core.current-processor, 'wiki', 'Wiki is the default processor';
    ok $core.process-wiki('! Title').contains('<h3> Title</h3>'), 'default processor renders Wiki notation';

    $core.register-processor('markdown', -> $source, %context { '# ' ~ $source ~ ' ' ~ (%context<suffix> // '') });
    $core.select-processor('markdown');
    is $core.process-wiki('hello', suffix => 'ok'), '# hello ok', 'a callable processor receives source and context';
    is $core.process-wiki('hello', processor => 'wiki'), '<p>hello</p>', 'a named processor can be selected per call';
};

subtest 'configuration values can be read and updated' => {
    my $core = FSWiki::Core.new;

    nok $core.config('missing').defined, 'missing configuration returns Nil';
    $core.config('site-name', 'FSWiki');
    is $core.config('site-name'), 'FSWiki', 'configuration round-trips';
};

subtest 'runtime WikiFarm tracks safe child wikis and admin credentials' => {
    my $core = FSWiki::Core.new;

    nok $core.farm-is-enable, 'farm is disabled by default';
    $core.config('farm-enabled', True);
    ok $core.farm-is-enable, 'farm enable flag is configurable';

    for '', '/wiki', 'wiki/name', 'wiki\\name', 'wiki:name', '..', 'a..b' -> $name {
        throws-like { $core.create-wiki($name) }, Exception,
            "invalid wiki name '$name' is rejected";
    }

    ok $core.create-wiki('zeta', 'admin', 'secret'), 'wiki with admin credentials is created';
    ok $core.create-wiki('alpha'), 'wiki without admin credentials is created';
    throws-like { $core.create-wiki('zeta') }, Exception,
        'duplicate wiki names are rejected';
    is-deeply $core.get-wiki-list, ('alpha', 'zeta').List,
        'wiki list contains sorted direct children';
    is-deeply $core.search-child, ('alpha', 'zeta').List,
        'empty prefix finds all direct children';
    is-deeply $core.search-child('ze'), ('zeta',).List,
        'prefix search returns sorted matching children';
    is-deeply $core.wiki-child('zeta'),
        { name => 'zeta', admin => { id => 'admin', password => 'secret' } },
        'admin credentials are kept in the child record';

    ok $core.remove-wiki('zeta'), 'existing wiki is removed';
    nok $core.wiki-exists('zeta'), 'removed wiki no longer exists';
    nok $core.remove-wiki('missing'), 'removing an unknown wiki returns false';
};

subtest 'title state stores the title without generating metadata' => {
    my $core = FSWiki::Core.new;

    nok $core.get-title.defined, 'title starts empty';
    $core.set-title('Edit page', True);
    is $core.get-title, 'Edit page', 'title is returned after setting it';
};

subtest 'URLs use the script name, sorted keys, and URI encoding' => {
    my $core = FSWiki::Core.new(config => { 'script-name' => 'wiki.cgi' });

    is $core.create-page-url('A page/日本'), 'wiki.cgi?page=A%20page%2F%E6%97%A5%E6%9C%AC',
        'page URL encodes the page name';
    is $core.create-url({ z => 'two words', a => 'x&y' }),
        'wiki.cgi?a=x%26y&z=two%20words',
        'URL query keys are sorted and values are encoded';
    is FSWiki::Core.new.create-page-url('Home'), '?page=Home',
        'default script name produces a query URL';
};

subtest 'redirect helpers return plain redirect data' => {
    my $core = FSWiki::Core.new;

    is-deeply $core.redirect('Home'),
        { status => 302, location => '?page=Home' },
        'page redirect points to the page URL';
    is-deeply $core.redirect-url('/login?next=Home'),
        { status => 302, location => '/login?next=Home' },
        'URL redirect preserves the supplied location';
};

subtest 'head information preserves registration order' => {
    my $core = FSWiki::Core.new;

    $core.add-head-info('<meta name="one">');
    $core.add-head-info('<link rel="two">');
    is-deeply $core.get-head-info,
        ('<meta name="one">', '<link rel="two">').List,
        'head information is returned in registration order';
};

done-testing;
