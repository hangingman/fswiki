unit module FSWiki::HTTP::App;

use Cro::HTTP::Router;
use JSON::Fast;
use FSWiki::Core;
use FSWiki::Storage::File;

sub escape-html(Str:D $source --> Str:D) {
    $source.subst('&', '&amp;', :g)
        .subst('<', '&lt;', :g)
        .subst('>', '&gt;', :g)
        .subst('"', '&quot;', :g)
}

sub source-response(Str:D $page = 'Home', FSWiki::Core:D :$core = FSWiki::Core.new) is export {
    $core.save-page('Home', 'Welcome to FSWiki.') unless $core.page-exists('Home');
    $core.add-hook('source', -> $wiki, $name, %state {
        %state<source> = $wiki.get-page($page);
    });

    my %state;
    $core.do-hook('source', %state);
    '<pre>' ~ escape-html(%state<source> // '') ~ '</pre>'
}

sub save-page-response(Str:D $page, Str:D $source, FSWiki::Core:D :$core = FSWiki::Core.new --> Str:D) is export {
    die 'page name is required' if $page eq '';
    $core.save-page($page, $source);
    "saved\n"
}

sub register-api-handlers(FSWiki::Core:D $core --> FSWiki::Core:D) is export {
    my &handler = -> $wiki, %input {
        { page => %input<page>, source => $wiki.get-page(%input<page>) }
    };
    $core.add-handler('SOURCE', &handler, api => { method => 'GET', path => '/api/source' });
    $core.add-handler('SAVE_PAGE', -> $wiki, %input {
        die 'page name is required' if (%input<page> // '') eq '';
        $wiki.save-page(%input<page>, %input<source> // '');
        { page => %input<page>, saved => True }
    }, api => { method => 'POST', path => '/api/page/{page}' });
    $core
}

sub api-source-response(Str:D $page = 'Home', FSWiki::Core:D :$core = FSWiki::Core.new --> Str:D) is export {
    $core.save-page('Home', 'Welcome to FSWiki.') unless $core.page-exists('Home');
    register-api-handlers($core) unless $core.api-info('SOURCE');
    to-json($core.call-handler('SOURCE', { page => $page }))
}

sub api-save-page-response(Str:D $page, Str:D $source, FSWiki::Core:D :$core = FSWiki::Core.new --> Str:D) is export {
    register-api-handlers($core) unless $core.api-info('SAVE_PAGE');
    to-json($core.call-handler('SAVE_PAGE', { :$page, :$source }))
}

sub api-routes(FSWiki::Core:D $core) {
    return route {
        get -> 'api', 'source', :$page = 'Home' {
            content 'application/json', api-source-response($page, :$core);
        }
        post -> 'api', 'page', $page {
            request-body -> %json {
                content 'application/json', api-save-page-response($page, %json<source> // '', :$core);
            }
        }
    }
}

sub build-application(IO::Path:D :$data-dir = IO::Path.new('data')) is export {
    my $core = FSWiki::Core.new(storage => FSWiki::Storage::File.new(dir => $data-dir));
    $core.save-page('Home', 'Welcome to FSWiki.') unless $core.page-exists('Home');
    register-api-handlers($core);

    route {
        get -> 'health' {
            content 'text/plain', 'ok\n';
        }
        get -> 'source', $page = 'Home' {
            content 'text/html; charset=UTF-8', source-response($page, :$core);
        }
        post -> 'page', $page {
            request-body -> %form {
                content 'text/plain', save-page-response($page, %form<source> // '', :$core);
            }
        }
        include api-routes($core);
    }
}

sub start-server(Int:D :$port = 8081, Str:D :$host = '0.0.0.0', IO::Path:D :$data-dir = IO::Path.new('data')) is export {
    use Cro::HTTP::Server;

    my $application = build-application(:$data-dir);
    my Cro::Service $server = Cro::HTTP::Server.new(:$host, :$port, :$application);
    $server.start;
    react whenever signal(SIGINT) {
        $server.stop;
        exit;
    }
}

sub MAIN(Int:D :$port = 8081, Str:D :$host = '0.0.0.0', Str :$data-dir = 'data') {
    start-server(:$port, :$host, data-dir => IO::Path.new($data-dir));
}
