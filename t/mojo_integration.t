use strict;
use warnings;
use Test::More;
use Plack::Test;
use Plack::Util;
use HTTP::Request::Common;

# Load the PSGI app
my $app = Plack::Util::load_psgi('app.psgi');

test_psgi $app, sub {
    my $cb = shift;
    
    # Test Mojolicious mount at /v2
    # Note: requests to /v2/ should be routed to Mojo '/'
    
    # /v2 might need trailing slash or not depending on mount implementation?
    # Mojo::Server::PSGI usually strips the prefix.
    # Plack::App::URLMap (mount) strips prefix.
    
    my $res = $cb->(GET '/v2'); 
    # Mojo defaults to / if path is empty? Or /v2 corresponds to / inside?
    # If mounted at /v2, request to /v2 comes as PATH_INFO='/' (sometimes) or empty.
    
    # Let's try /v2/ explicitly first if /v2 fails.
    unless ($res->code == 200) {
        $res = $cb->(GET '/v2/');
    }

    is $res->code, 200, 'Mojo root OK';
    like $res->content, qr/Hello from Mojolicious/, 'Content matches';
    
    $res = $cb->(GET '/v2/pages/TestPage');
    is $res->code, 200, 'Mojo page OK';
    like $res->content, qr/Showing page: TestPage/, 'Page content matches';
};

done_testing();
