use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use lib './lib';

my $t = Test::Mojo->new('FSWiki::Mojo');

$t->get_ok('/')
  ->status_is(200)
  ->content_like(qr/Hello from Mojolicious/);

$t->get_ok('/pages/TestPage')
  ->status_is(200)
  ->content_like(qr/Showing page: TestPage/);

$t->get_ok('/pages/TestPage/edit')
  ->status_is(200)
  ->content_like(qr/Editing page: TestPage/);

done_testing();
