use Plack::Builder;
use Plack::App::WrapCGI;
use Plack::App::File;
use Plack::App::Directory;

builder {
	mount "/fswiki/wiki.cgi" => Plack::App::WrapCGI->new({ script => './wiki.cgi', execute => 1 })->to_app;
	mount "/fswiki/theme" => Plack::App::Directory->new({ root => './theme' })->to_app;
	mount "/fswiki/plugin" => Plack::App::Directory->new({ root => './plugin' })->to_app;
};
