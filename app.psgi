use Plack::Builder;
use Plack::App::File;
use Plack::App::Directory;
use Plack::Middleware::Session;
use Plack::Middleware::Session::Cookie;
use Plack::Session::Store::File;
use lib ('./lib', './local/lib/perl5');
use Wiki;
use WikiApplication;

builder {
    # FreeStyleWiki フロントエンドPSGIモジュール
    my $wiki_app = WikiApplication->new;
    my $wiki = Wiki->new('setup.dat', $env);

	# セッション、クッキーの設定をconfig.datから取得
	my $dir   = $wiki->config('session_dir', $wiki->config('log_dir'));
	my $limit = $wiki->config('session_limit') || 30;
	my $secret = $wiki->config('secret');

	enable 'Session', store => Plack::Session::Store::File->new(dir => $dir);
	enable 'Session::Cookie',
		session_key => 'CGISESSID',
        expires => int($limit) * 60,
        secret => $secret
    ;

    # Plack::Middleware::Sessionにセッション情報を設定する
 	mount "/fswiki/wiki.cgi" => sub { $wiki_app->run_psgi(@_); };
	mount "/fswiki/theme"    => Plack::App::Directory->new({ root => './theme' })->to_app;
	mount "/fswiki/plugin"   => Plack::App::Directory->new({ root => './plugin' })->to_app;
};
