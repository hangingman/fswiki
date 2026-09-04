use lib 'raku/lib';
use FSWiki::HTTP::App;

start-server(
    host => %*ENV<FSWIKI_DEV_HOST> // '127.0.0.1',
    port => (%*ENV<FSWIKI_DEV_PORT> // 8081).Int,
    data-dir => IO::Path.new(%*ENV<FSWIKI_DATA_DIR> // 'data'),
);
