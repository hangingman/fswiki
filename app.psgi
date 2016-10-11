#!/usr/bin/env perl

use strict;
use warnings;
use CGI::Emulate::PSGI;

CGI::Emulate::PSGI->handler(sub {
    do "wiki.cgi";
    CGI::initialize_globals() if &CGI::initialize_globals;
});
