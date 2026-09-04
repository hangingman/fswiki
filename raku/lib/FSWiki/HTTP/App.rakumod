unit module FSWiki::HTTP::App;

use Cro::HTTP::Router;
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

sub build-application(IO::Path:D :$data-dir = IO::Path.new('data')) is export {
    my $core = FSWiki::Core.new(storage => FSWiki::Storage::File.new(dir => $data-dir));
    $core.save-page('Home', 'Welcome to FSWiki.') unless $core.page-exists('Home');

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
