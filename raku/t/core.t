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

done-testing;
