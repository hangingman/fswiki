#!/bin/sh

bash ./setup.sh "${FSWIKI_HOME}"
carton exec start_server \
    --pid-file=/tmp/fswiki.pid \
    --status-file=/tmp/fswiki.status -- starman --workers 4 app.psgi

