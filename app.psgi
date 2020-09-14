use Plack::Builder;
use Plack::App::WrapCGI;
use Plack::App::File;
use Plack::App::Directory;
use lib ('./lib', './local/lib/perl5');
use WikiApplication;

builder {
    my $wiki = sub {
        my $app = WikiApplication->new;
        $app->run_psgi(@_);
    };

 	mount "/fswiki/wiki.cgi" => $wiki;
	mount "/fswiki/theme" => Plack::App::Directory->new({ root => './theme' })->to_app;
	mount "/fswiki/plugin" => Plack::App::Directory->new({ root => './plugin' })->to_app;
};
