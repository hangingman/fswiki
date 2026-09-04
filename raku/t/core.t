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

    $core.add-handler('LIST', -> $wiki { 'list' });
    $core.add-user-handler('EDIT', -> $wiki { 'edit' });
    $core.add-admin-handler('ADMIN', -> $wiki { 'admin' });

    is $core.call-handler('LIST'), 'list';
    is $core.call-handler('EDIT'), 'edit';
    is $core.call-handler('ADMIN'), 'admin';
    is-deeply $core.handler-permission('LIST'), 'public';
    is-deeply $core.handler-permission('EDIT'), 'user';
    is-deeply $core.handler-permission('ADMIN'), 'admin';
};

done-testing;
