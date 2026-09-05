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
    return '' unless $core.can-show($page);
    my %context =
        'page-link' => -> $target, $label { '<a href="/source/' ~ escape-html($target) ~ '" class="wikipage">' ~ escape-html($label) ~ '</a>' },
        'url-link' => -> $url, $label { '<a href="' ~ escape-html($url) ~ '">' ~ escape-html($label) ~ '</a>' };
    $core.process-wiki($core.get-page($page), |%context);
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
    $core.add-handler('SOURCE', &handler, api => {
        method => 'GET', path => '/api/source',
        schema => { page => { required => True, type => 'Str' } }
    });
    $core.add-handler('SAVE_PAGE', -> $wiki, %input {
        die 'page name is required' if (%input<page> // '') eq '';
        $wiki.save-page(%input<page>, %input<source> // '');
        { page => %input<page>, saved => True }
    }, api => {
        method => 'POST', path => '/api/page/{page}',
        schema => {
            page => { required => True, type => 'Str' },
            source => { required => True, type => 'Str' }
        }
    });
    $core
}

sub api-error($exception --> Str:D) {
    my $message = $exception.message;
    my ($code, $safe-message) = do given $message {
        when /'Unknown action'/       { 'unknown-action', 'Unknown API action' }
        when /'Invalid API input'/    { 'validation-error', $message }
        when /'Login required'|'Admin permission required'/ {
            'permission-denied', 'Permission denied'
        }
        default                       { 'api-error', 'API request failed' }
    };
    to-json({ error => { code => $code, message => $safe-message } })
}

sub api-call-response(Str:D $action, %input, FSWiki::Core:D :$core --> Str:D) {
    my $response;
    try {
        $response = to-json($core.call-handler($action, %input));
        CATCH { default { $response = api-error($_) } }
    }
    $response
}

sub api-source-response(Mu $page = 'Home', FSWiki::Core:D :$core = FSWiki::Core.new --> Str:D) is export {
    $core.save-page('Home', 'Welcome to FSWiki.') unless $core.page-exists('Home');
    register-api-handlers($core) unless $core.api-info('SOURCE');
    api-call-response('SOURCE', { page => $page }, :$core)
}

sub api-save-page-response(Mu $page = Nil, Mu $source = Nil, FSWiki::Core:D :$core = FSWiki::Core.new --> Str:D) is export {
    register-api-handlers($core) unless $core.api-info('SAVE_PAGE');
    api-call-response('SAVE_PAGE', { :$page, :$source }, :$core)
}

sub api-routes(FSWiki::Core:D $core) {
    return route {
        get -> 'api', 'source', :$page = 'Home' {
            content 'application/json', api-source-response($page, :$core);
        }
        post -> 'api', 'page', $page {
            request-body -> %json {
                content 'application/json', api-save-page-response($page, %json<source>, :$core);
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
