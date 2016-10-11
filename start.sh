#!/bin/bash

PERL5DIR=`pwd`"/lib/perl5"
export PERL_CPANM_OPT="--local-lib=${PERL5DIR}"
export PERL5LIB=${PERL5DIR}:$PERL5LIB
export PATH=`pwd`/bin:${PERL5DIR}/bin:$PATH;

bin/plackup app.psgi
