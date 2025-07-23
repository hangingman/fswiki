use Plack::Builder;
use Plack::App::File;
use Plack::App::Directory;
use Plack::Middleware::Session;
use Plack::Middleware::Session::Cookie;
use Plack::Middleware::ReverseProxy;
use Plack::Session::Store::File;
use lib ('./lib', './local/lib/perl5');
use Wiki;
use WikiApplication;
use UUID::Tiny ':std';

builder {
    # Redirect middleware
    enable sub {
        my $app = shift;
        return sub {
            my $env = shift;
            my $primary_host = $ENV{'PRIMARY_HOST'};
            my $custom_domain = $ENV{'CUSTOM_DOMAIN'};

            if ($primary_host && $custom_domain && $env->{HTTP_HOST} eq $primary_host) {
                my $location = 'https://' . $custom_domain . $env->{REQUEST_URI};
                return [ 301, [ 'Location' => $location ], [ 'Redirecting to ' . $location ] ];
            }

            return $app->($env);
        };
    };

    # reverse-proxy環境で実際のIPアドレスを取得する対応
    enable_if { $_[0]->{REMOTE_ADDR} eq '127.0.0.1' }
        'ReverseProxy';

	# セッション、クッキーの設定をconfig.datから取得
	my $wiki = Wiki->new('setup.dat', $env);
	my $dir = $wiki->config('session_dir', $wiki->config('log_dir'));
	my $limit = $wiki->config('session_limit') || 30;
	my $secret = $wiki->config('secret') || create_uuid(UUID_V4);

	# PSGIを呼び出す前のPlack側の準備
	enable Session => (
		store => Plack::Session::Store::File->new(dir => $dir),
		state => Plack::Session::State::Cookie->new(
			session_key => 'CGISESSID',
			expires => int($limit) * 60,
			secret => $secret,
			sid_generator => sub { 'cgisess_' . Digest::SHA1::sha1_hex(rand() . $$ . {} . time); },
			sid_validator => qr/\Acgisess_[0-9a-f]{40}\Z/,  # cgisess_[SHA1文字列40桁]
		)
	);

	enable 'CSRFBlock', meta_tag => 'csrf-token';
	# FreeStyleWiki フロントエンドPSGIモジュール
	my WikiApplication $wiki_app = WikiApplication->new;

	# Plack::Middleware::Sessionにセッション情報を設定する
	mount "/fswiki/wiki.cgi" => sub {$wiki_app->run_psgi(@_);};
	mount "/fswiki/theme" => Plack::App::Directory->new({ root => './theme' })->to_app;
	mount "/fswiki/plugin" => Plack::App::Directory->new({ root => './plugin' })->to_app;
};
