use v6.d;
use Test;
use lib 'raku/lib';
use FSWiki::HTTP::App;

my $application = build-application;
ok $application.defined, 'HTTP application is constructed';

done-testing;
