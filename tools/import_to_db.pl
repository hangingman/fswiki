#!/usr/bin/env perl
use strict;
use warnings;
use Cwd;
use Getopt::Long; # 追加
use URI::Escape; # 追加

use DBI;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use File::Spec;
use File::Path qw(make_path remove_tree);
use Encode qw(decode FB_CROAK);

# --- オプション解析 ---
my $schema_only = 0;
GetOptions('schema-only' => \$schema_only);

# --- 設定 ---
my $zip_file = shift @ARGV; # zipファイルへのパスを受け取る
if (!$schema_only) {
    die "Usage: $0 <path_to_export.zip>" unless $zip_file;
}

my $tmp_dir = File::Spec->catdir(Cwd::cwd(), 'tmp_import');

# --- DB接続情報 (環境変数から取得) ---
my $db_driver = $ENV{'DB_DRIVER'} || 'mysql';
my $db_name   = $ENV{'DB_NAME'}   || die "DB_NAME not set";
my $db_host   = $ENV{'DB_HOST'}   || die "DB_HOST not set";
my $db_user   = $ENV{'DB_USER'}   || die "DB_USER not set";
my $db_pass   = $ENV{'DB_PASS'}   || '';

# --- メイン処理 ---

# 1. DB接続
print "1. Connecting to database...\n";
my $dsn = "dbi:$db_driver:database=$db_name;host=$db_host;mysql_ssl=1"; # SSL接続を有効化
my $dbh = DBI->connect($dsn, $db_user, $db_pass, { PrintError => 1, RaiseError => 1, AutoCommit => 0 });
die "DBI connect failed: $DBI::errstr" unless $dbh;
$dbh->do('SET NAMES utf8mb4');
print "Database connected.\n";

# 2. テーブル作成
print "2. Creating tables...\n";
create_tables($dbh);
print "Tables created.\n";

# --schema-onlyが指定されている場合はここで終了
if ($schema_only) {
    $dbh->disconnect();
    print "Done (schema only).\n";
    exit 0;
}

# 3. zipファイルを解凍
print "3. Unzipping $zip_file to $tmp_dir...\n";
remove_tree($tmp_dir) if -d $tmp_dir;
make_path($tmp_dir);

my $zip = Archive::Zip->new();
die 'Error reading zip file' unless $zip->read($zip_file) == AZ_OK;
$zip->extractTree('', "$tmp_dir/");
print "Unzip completed.\n";

# 4. データインポート
print "4. Importing data...\n";
my $data_dir = File::Spec->catdir($tmp_dir, 'data');
import_data($dbh, $data_dir);
print "Data import completed.\n";

# 5. クリーンアップ
print "5. Cleaning up temporary files...\n";
# remove_tree($tmp_dir);
print "Cleanup completed.\n";

$dbh->disconnect();
print "Done.\n";

# --- サブルーチン ---

sub create_tables {
    my ($dbh) = @_;
    my $sql = {
        # Drop
        data_drp     => "DROP TABLE IF EXISTS `data_tbl`",
        backup_drp   => "DROP TABLE IF EXISTS `backup_tbl`",
        attr_drp     => "DROP TABLE IF EXISTS `attr_tbl`",
        # Table
        data_tbl     => "CREATE TABLE `data_tbl` (`page` VARCHAR(255) NOT NULL, `source` LONGTEXT, `lastmodified` BIGINT, PRIMARY KEY (`page`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4",
        backup_tbl   => "CREATE TABLE `backup_tbl` (`page` VARCHAR(255) NOT NULL, `source` LONGTEXT, `lastmodified` BIGINT, INDEX `idx_page_modified` (`page`, `lastmodified` DESC)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4",
        attr_tbl     => "CREATE TABLE `attr_tbl` (`page` VARCHAR(255) NOT NULL, `key` VARCHAR(255) NOT NULL, `value` TEXT, `lastmodified` BIGINT, PRIMARY KEY (`page`, `key`), INDEX `idx_key_page` (`key`, `page`)) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4",
    };

    eval {
        $dbh->do($sql->{data_drp});
        $dbh->do($sql->{backup_drp});
        $dbh->do($sql->{attr_drp});
        $dbh->do($sql->{data_tbl});
        $dbh->do($sql->{backup_tbl});
        $dbh->do($sql->{attr_tbl});
        $dbh->commit();
    };
    if ($@) {
        warn "Table creation failed: $@";
        $dbh->rollback();
        die;
    }
}

sub import_data {
    my ($dbh, $data_dir) = @_;
    opendir(my $dh, $data_dir) || die "Can't open $data_dir: $!";
    my @files = readdir($dh);
    closedir($dh);

    my $data_ins_sql = "REPLACE INTO `data_tbl` (`page`, `source`, `lastmodified`) VALUES (?, ?, ?)";
    my $backup_ins_sql = "REPLACE INTO `backup_tbl` (`page`, `source`, `lastmodified`) VALUES (?, ?, ?)";
    my $attr_ins_sql = "REPLACE INTO `attr_tbl` (`page`, `key`, `value`, `lastmodified`) VALUES (?, ?, ?, ?)";

    my $data_sth = $dbh->prepare($data_ins_sql);
    my $backup_sth = $dbh->prepare($backup_ins_sql);
    my $attr_sth = $dbh->prepare($attr_ins_sql);

    eval {
        foreach my $file (@files) {
            print "Processing file: $file\n"; # デバッグログ
            my $file_path = File::Spec->catfile($data_dir, $file);
            my $content;
            # エンコーディングを自動判別して読み込み
            open my $fh, '<:raw', $file_path or die "Can't open $file_path: $!";
            my $raw_content = do { local $/; <$fh> };
            close $fh;

            # UTF-8, Shift_JIS, EUC-JPの順にデコードを試みる
            if (eval { $content = decode('UTF-8', $raw_content, Encode::FB_CROAK); 1 }) {
                # UTF-8として成功
            } elsif (eval { $content = decode('Shift_JIS', $raw_content, Encode::FB_CROAK); 1 }) {
                # Shift_JISとして成功
            } elsif (eval { $content = decode('EUC-JP', $raw_content, Encode::FB_CROAK); 1 }) {
                # EUC-JPとして成功
            } else {
                # どれでもない場合はUTF-8で強制デコードし、不正な文字は置換
                $content = decode('UTF-8', $raw_content, 0x00000004); # Encode::FB_XMLCHAR
                warn "Warning: Could not decode $file_path with UTF-8, Shift_JIS, or EUC-JP. Forcing UTF-8 with character replacement.\n";
            }

            my $mtime = (stat($file_path))[9];

            if ($file =~ /\.wiki$/) {
                my $page_name = uri_unescape($file);
                $page_name =~ s/\.wiki$//;
                print "  Page name (wiki): $page_name\n"; # デバッグログ
                $data_sth->execute($page_name, $content, $mtime);
                print "  Imported wiki: $page_name\n";
            } elsif ($file =~ /\.bak$/) {
                my $page_name = uri_unescape($file);
                $page_name =~ s/\.bak$//;
                print "  Page name (backup): $page_name\n"; # デバッグログ
                $backup_sth->execute($page_name, $content, $mtime);
                print "  Imported backup: $page_name\n";
            }
            elsif ($file =~ /\.attr$/) {
                my $page_name = uri_unescape($file);
                $page_name =~ s/\.attr$//;
                print "  Page name (attr): $page_name\n"; # デバッグログ
                # .attrファイルは key=value 形式なのでパースが必要
                my @lines = split /\n/, $content;
                foreach my $line (@lines) {
                    next unless $line =~ /^([^=]+)=(.*)$/;
                    my ($key, $value) = ($1, $2);
                    $attr_sth->execute($page_name, $key, $value, $mtime);
                    print "  Imported attr: $page_name ($key)\n";
                }
            }
        }
        $dbh->commit();
    };
    if ($@) {
        warn "Data import failed: $@";
        $dbh->rollback();
        die;
    }
}