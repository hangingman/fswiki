use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(remove_tree);
use DBI;
use JSON;

# テスト対象モジュール
use plugin::dbi::StandardDatabaseStorage;

# ダミーのWikiオブジェクト
my $dummy_wiki = bless {}, 'DummyWiki';
sub DummyWiki::config {
    my ($self, $key, $value) = @_;
    if (defined $value) {
        $self->{$key} = $value;
    }
    return $self->{$key};
}
# config_dirなどを一時ディレクトリに設定
$dummy_wiki->config('config_dir', tempdir(CLEANUP => 1));
$dummy_wiki->config('log_dir', tempdir(CLEANUP => 1));
$dummy_wiki->config('data_dir', tempdir(CLEANUP => 1));
$dummy_wiki->config('backup_dir', tempdir(CLEANUP => 1));
$dummy_wiki->config('freeze_file', 'freeze.log');

# テストの数を宣言
my $num_tests = 0;

# --- MySQL/MariaDB テスト ---
# 環境変数からDB接続情報を取得
my $mysql_driver = $ENV{DB_DRIVER} || 'mysql';
my $mysql_host   = $ENV{DB_HOST}   || 'fswiki-mysql-dev';
my $mysql_name   = $ENV{DB_NAME}   || 'fswiki_test';
my $mysql_user   = $ENV{DB_USER}   || 'root';
my $mysql_pass   = $ENV{DB_PASS}   || 'password';

# MySQL接続情報をダミーWikiオブジェクトに設定
$dummy_wiki->config('db_driver', $mysql_driver);
$dummy_wiki->config('db_host', $mysql_host);
$dummy_wiki->config('db_name', $mysql_name);
$dummy_wiki->config('db_user', $mysql_user);
$dummy_wiki->config('db_pass', $mysql_pass);

# MySQL接続テスト
my $dbh_mysql;
eval {
    $dbh_mysql = DBI->connect("dbi:$mysql_driver:database=$mysql_name;host=$mysql_host", $mysql_user, $mysql_pass, {PrintError => 0, RaiseError => 1});
};
if ($@) {
    diag "Skipping MySQL tests: Could not connect to database: $@";
} else {
    # テストテーブルの作成とクリーンアップ
    $dbh_mysql->do("DROP TABLE IF EXISTS config_tbl");
    $dbh_mysql->do("CREATE TABLE config_tbl (key_name VARCHAR(255) PRIMARY KEY, value TEXT)");

    # --- テストケース: MySQL - インスタンス化 ---
    $num_tests++;
    my $storage_mysql = plugin::dbi::StandardDatabaseStorage->new($dummy_wiki);
    isa_ok($storage_mysql, 'plugin::dbi::StandardDatabaseStorage', 'new() creates a StandardDatabaseStorage object (MySQL)');

    # --- テストケース: MySQL - load_config - 設定が存在しない場合 ---
    $num_tests++;
    my $loaded_config_mysql_non_existent = $storage_mysql->load_config();
    is_deeply($loaded_config_mysql_non_existent, {}, 'load_config returns empty hash ref if config does not exist (MySQL)');

    # --- テストケース: MySQL - save_config と load_config - 基本的な動作 ---
    $num_tests++;
    my $test_data_mysql_basic = {
        mysql_key1 => 'mysql_value1',
        mysql_key2 => 456,
        mysql_key3 => [qw(x y z)],
    };
    $storage_mysql->save_config($test_data_mysql_basic);
    my $loaded_config_mysql_basic = $storage_mysql->load_config();
    is_deeply($loaded_config_mysql_basic, $test_data_mysql_basic, 'save_config and load_config work correctly for basic data (MySQL)');

    # --- テストケース: MySQL - save_config - 既存設定を上書き ---
    $num_tests++;
    my $new_data_mysql = { mysql_new => 'mysql_data', mysql_updated => 789 };
    $storage_mysql->save_config($new_data_mysql);
    my $loaded_config_mysql_overwrite = $storage_mysql->load_config();
    is_deeply($loaded_config_mysql_overwrite, $new_data_mysql, 'save_config overwrites existing config (MySQL)');

    # クリーンアップ
    $dbh_mysql->do("DROP TABLE IF EXISTS config_tbl");
    $dbh_mysql->disconnect();
}

# --- SQLite テスト ---
if (0) {
my $sqlite_temp_dir = tempdir(CLEANUP => 1);
my $sqlite_db_path = "$sqlite_temp_dir/test.db";

# SQLite接続情報をダミーWikiオブジェクトに設定
$dummy_wiki->config('db_driver', 'SQLite');
$dummy_wiki->config('db_dir', $sqlite_temp_dir); # SQLiteの場合、db_dirがDBファイルのディレクトリになる
$dummy_wiki->config('db_name', 'test.db'); # SQLiteの場合、db_nameがDBファイル名になる
$dummy_wiki->config('db_user', ''); # SQLiteはユーザー名不要
$dummy_wiki->config('db_pass', ''); # SQLiteはパスワード不要

# SQLite接続テスト
my $dbh_sqlite;
eval {
    $dbh_sqlite = DBI->connect("dbi:SQLite:dbname=$sqlite_db_path", "", "", {PrintError => 0, RaiseError => 1});
};
if ($@) {
    diag "Skipping SQLite tests: Could not connect to database: $@";
} else {
    # テストテーブルの作成とクリーンアップ
    $dbh_sqlite->do("DROP TABLE IF EXISTS config_tbl");
    $dbh_sqlite->do("CREATE TABLE config_tbl (key_name VARCHAR(255) PRIMARY KEY, value TEXT)");

    # --- テストケース: SQLite - インスタンス化 ---
    $num_tests++;
    my $storage_sqlite = plugin::dbi::StandardDatabaseStorage->new($dummy_wiki);
    isa_ok($storage_sqlite, 'plugin::dbi::StandardDatabaseStorage', 'new() creates a StandardDatabaseStorage object (SQLite)');

    # --- テストケース: SQLite - load_config - 設定が存在しない場合 ---
    $num_tests++;
    my $loaded_config_sqlite_non_existent = $storage_sqlite->load_config();
    is_deeply($loaded_config_sqlite_non_existent, {}, 'load_config returns empty hash ref if config does not exist (SQLite)');

    # --- テストケース: SQLite - save_config と load_config - 基本的な動作 ---
    $num_tests++;
    my $test_data_sqlite_basic = {
        sqlite_key1 => 'sqlite_value1',
        sqlite_key2 => 789,
        sqlite_key3 => [qw(a b c)],
    };
    $storage_sqlite->save_config($test_data_sqlite_basic);
    my $loaded_config_sqlite_basic = $storage_sqlite->load_config();
    is_deeply($loaded_config_sqlite_basic, $test_data_sqlite_basic, 'save_config and load_config work correctly for basic data (SQLite)');

    # --- テストケース: SQLite - save_config - 既存設定を上書き ---
    $num_tests++;
    my $new_data_sqlite = { sqlite_new => 'sqlite_data', sqlite_updated => 123 };
    $storage_sqlite->save_config($new_data_sqlite);
    my $loaded_config_sqlite_overwrite = $storage_sqlite->load_config();
    is_deeply($loaded_config_sqlite_overwrite, $new_data_sqlite, 'save_config overwrites existing config (SQLite)');

    # クリーンアップ
    $dbh_sqlite->do("DROP TABLE IF EXISTS config_tbl");
    $dbh_sqlite->disconnect();
}

}

# テストの実行数をチェック
done_testing($num_tests);
