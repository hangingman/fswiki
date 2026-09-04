unit module FSWiki::HTTP::App;

use Cro::HTTP::Router;
use Cro::HTTP::Response;
use FSWiki::Core;

sub build-application() is export {
    my $core = FSWiki::Core.new;
    $core.add-hook('health', -> $wiki, $name, %state {
        %state<status> = 'ok';
    });

    route {
        get -> 'health' {
            my %state;
            $core.do-hook('health', %state);
            content 'text/plain', %state<status> ~ "\n";
        }
    }
}

sub start-server(Int:D :$port = 8080, Str:D :$host = '0.0.0.0') is export {
    use Cro::HTTP::Server;

    my $application = build-application;
    my Cro::Service $server = Cro::HTTP::Server.new(:$host, :$port, :$application);
    $server.start;
    react whenever signal(SIGINT) {
        $server.stop;
        exit;
    }
}

sub MAIN(Int:D :$port = 8080, Str:D :$host = '0.0.0.0') {
    start-server(:$port, :$host);
}
