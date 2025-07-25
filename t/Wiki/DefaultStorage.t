use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(remove_tree);
use JSON;

# テスト対象モジュール
use Wiki::DefaultStorage;

# ダミーのWikiオブジェクト
# configメソッドを持つようにする
my $dummy_wiki = bless {}, 'DummyWiki';
sub DummyWiki::config {
    my ($self, $key, $value) = @_;
    if (defined $value) {
        $self->{$key} = $value;
    }
    return $self->{$key};
}
# config_dirとlog_dirを設定
$dummy_wiki->config('config_dir', tempdir(CLEANUP => 1));
$dummy_wiki->config('log_dir', tempdir(CLEANUP => 1));
$dummy_wiki->config('data_dir', tempdir(CLEANUP => 1));
$dummy_wiki->config('backup_dir', tempdir(CLEANUP => 1));
$dummy_wiki->config('freeze_file', 'freeze.log'); # freeze_fileも必要

# テストの数を宣言
my $num_tests = 0;

# --- テストケース: インスタンス化 ---
$num_tests++;
my $storage = Wiki::DefaultStorage->new($dummy_wiki); # ダミーWikiオブジェクトを渡す
isa_ok($storage, 'Wiki::DefaultStorage', 'new() creates a DefaultStorage object');

# --- テストケース: load_config - ファイルが存在しない場合 ---
$num_tests++;
my $temp_dir_non_existent = tempdir(CLEANUP => 1);
my $non_existent_config_path = "$temp_dir_non_existent/non_existent_config.dat";
# ダミーWikiオブジェクトのconfig_fileを一時的なパスに設定
$dummy_wiki->config('config_file', $non_existent_config_path);
my $loaded_config_non_existent = $storage->load_config(); # 引数なしで呼び出す
is_deeply($loaded_config_non_existent, {}, 'load_config returns empty hash ref if file does not exist');

# --- テストケース: save_config と load_config - 基本的な動作 ---
$num_tests++;
my $temp_dir_basic = tempdir(CLEANUP => 1);
my $basic_config_path = "$temp_dir_basic/basic_config.dat";
$dummy_wiki->config('config_file', $basic_config_path); # ダミーWikiオブジェクトのconfig_fileを一時的なパスに設定
my $test_data_basic = {
    key1 => 'value1',
    key2 => 123,
    key3 => [qw(a b c)],
};
$storage->save_config($test_data_basic); # 引数なしで呼び出す
my $loaded_config_basic = $storage->load_config(); # 引数なしで呼び出す
is_deeply($loaded_config_basic, $test_data_basic, 'save_config and load_config work correctly for basic data');

# --- テストケース: load_config - 無効なJSONファイルの場合 ---
$num_tests++;
my $temp_dir_invalid = tempdir(CLEANUP => 1);
my $invalid_config_path = "$temp_dir_invalid/invalid_config.dat";
$dummy_wiki->config('config_file', $invalid_config_path); # ダミーWikiオブジェクトのconfig_fileを一時的なパスに設定
open my $fh_invalid, '>', $invalid_config_path or die "Cannot open $invalid_config_path: $!";
print $fh_invalid "this is not json";
close $fh_invalid;
my $loaded_config_invalid = $storage->load_config(); # 引数なしで呼び出す
is_deeply($loaded_config_invalid, {}, 'load_config returns empty hash ref for invalid JSON');

# --- テストケース: save_config - 既存ファイルを上書き ---
$num_tests++;
my $temp_dir_overwrite = tempdir(CLEANUP => 1);
my $overwrite_config_path = "$temp_dir_overwrite/overwrite_config.dat";
$dummy_wiki->config('config_file', $overwrite_config_path); # ダミーWikiオブジェクトのconfig_fileを一時的なパスに設定
my $initial_data = { initial => 'data' };
$storage->save_config($initial_data); # 引数なしで呼び出す
my $new_data = { new => 'data', updated => 456 };
$storage->save_config($new_data); # 引数なしで呼び出す
my $loaded_config_overwrite = $storage->load_config(); # 引数なしで呼び出す
is_deeply($loaded_config_overwrite, $new_data, 'save_config overwrites existing file');

# テストの実行数をチェック
done_testing($num_tests);