#!/usr/bin/env perl

use strict;
use warnings;
use Cwd;
use Plack::Builder;
use Plack::App::WrapCGI;
use Plack::App::File;

my $fswiki = cwd();

builder {
  mount "/fswiki/wiki.cgi"   => Plack::App::WrapCGI->new(script => './wiki.cgi'  , execute => 1)->to_app;
  mount "/fswiki/wikidb.cgi" => Plack::App::WrapCGI->new(script => './wikidb.cgi', execute => 1)->to_app;
  mount "/fswiki"            => Plack::App::File->new(root => "$fswiki")->to_app;
};
