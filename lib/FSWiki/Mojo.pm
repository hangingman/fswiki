package FSWiki::Mojo;
use Mojo::Base 'Mojolicious', -signatures;

sub startup ($self) {
    # ルーター設定
    my $r = $self->routes;

    # 基本ルート
    $r->get('/')->to('page#index');
    $r->get('/pages/:name')->to('page#show');
    $r->get('/pages/:name/edit')->to('page#edit');
}

1;
