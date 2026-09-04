unit module FSWiki::HTTP::App;

use Cro::HTTP::Router;
use FSWiki::Core;

sub source-response(Str:D $page = 'Home', FSWiki::Core:D :$core = FSWiki::Core.new) is export {
    $core.save-page('Home', 'Welcome to FSWiki.') unless $core.page-exists('Home');
    $core.add-hook('source', -> $wiki, $name, %state {
        %state<source> = $wiki.get-page($page);
    });

    my %state;
    $core.do-hook('source', %state);
    '<pre>' ~ (%state<source> // '') ~ '</pre>'
}

sub build-application() is export {
    route {
        get -> 'health' {
            content 'text/plain', 'ok\n';
        }
        get -> 'source', $page = 'Home' {
            content 'text/html; charset=UTF-8', source-response($page);
        }
    }
}

sub start-server(Int:D :$port = 8081, Str:D :$host = '0.0.0.0') is export {
    use Cro::HTTP::Server;

    my $application = build-application;
    my Cro::Service $server = Cro::HTTP::Server.new(:$host, :$port, :$application);
    $server.start;
    react whenever signal(SIGINT) {
        $server.stop;
        exit;
    }
}

sub MAIN(Int:D :$port = 8081, Str:D :$host = '0.0.0.0') {
    start-server(:$port, :$host);
}
