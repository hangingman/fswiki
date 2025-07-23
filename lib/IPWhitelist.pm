package IPWhitelist;
use strict;
use warnings;
use Plack::Component;
use Plack::Util;

# Plack::Middlewareを継承
use parent 'Plack::Middleware';

sub call {
    my ($self, $env) = @_;

    # 環境変数からホワイトリストを取得
    # カンマ区切りの文字列を想定 (例: "1.1.1.1,2.2.2.2")
    my $allowed_ips_str = $ENV{ALLOWED_IPS} || '';

    # 高速に検索できるよう、ハッシュに変換する
    my %allowed_ips = map { $_ => 1 } split /,/, $allowed_ips_str;

    # Fly.ioが提供するヘッダーを取得 (ヘッダー名はすべて大文字になり、ハイフンはアンダースコアに変換され、'HTTP_'が先頭に付与される)
    my $client_ip = $env->{HTTP_FLY_CLIENT_IP};

    # IPアドレスがホワイトリストに存在しない場合、403エラーを返す
    unless ($client_ip && $allowed_ips{$client_ip}) {
        return [
            403,
            [ 'Content-Type' => 'text/plain', 'Content-Length' => 9 ],
            [ 'Forbidden' ]
        ];
    }

    # 許可されている場合は、リクエストをアプリケーション本体に渡す
    return $self->app->($env);
}

1;
