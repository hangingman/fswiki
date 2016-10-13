requires 'perl', '5.16.3';

# test might be failed
# ------------------------------------#
# $ bin/cpanm -n -L . --installdeps . #
# ====================================#

requires 'Task::Plack';
requires 'CGI::Compile';
requires 'DBD::SQLite';
requires 'DBI';
