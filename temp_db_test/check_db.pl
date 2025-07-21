#!/usr/bin/perl
use strict;
use warnings;
use DBI;

# 環境変数から接続情報を取得
my $db_host = $ENV{'DB_HOST'};
my $db_name = $ENV{'DB_NAME'};
my $db_user = $ENV{'DB_USER'};
my $db_pass = $ENV{'DB_PASS'};

my $dsn = "DBI:mysql:database=$db_name;host=$db_host;port=3306";

# データベースへ接続
print "MySQL ($db_host) へ接続を試みます...\n";
my $dbh;
eval {
    # 接続試行を数回繰り返す（DBの起動待ちのため）
    for (1..30) {
        $dbh = DBI->connect($dsn, $db_user, $db_pass, { RaiseError => 1, PrintError => 0 });
        last if $dbh;
        sleep 5;
    }
};

if ($@ || !$dbh) {
    die "❌ データベース接続に失敗しました: $@\n";
}

print "✅ データベース '$db_name' への接続に成功しました！\n";

# バージョン情報を取得して表示
my $version = $dbh->selectrow_array("SELECT VERSION()");
print "   MySQL Server Version: $version\n";

$dbh->disconnect;

exit 0;
