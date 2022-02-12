#!/bin/bash

pushd "${FSWIKI_HOME}" || exit
bash ./setup.sh "${FSWIKI_HOME}"

# If defined $PORT by Heroku use it, else use default
PORT=${PORT-5000}
./local/bin/start_server \
    --port="$PORT" \
    --pid-file="${FSWIKI_HOME}/fswiki.pid" \
    --status-file="${FSWIKI_HOME}/fswiki.status" -- starman --workers 4 app.psgi

