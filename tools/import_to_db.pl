#!/usr/bin/perl
use strict;
use warnings;
use Cwd;

use DBI;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use File::Spec;
use File::Path qw(make_path remove_tree);

# --- 設定 ---
my $zip_file = shift @ARGV; # 第1引数でzipファイルへのパスを受け取る
die "Usage: $0 <path_to_export.zip>" unless $zip_file;

my $tmp_dir = File::Spec->catdir(Cwd::cwd(), 'tmp_import');

# --- DB接続情報 (環境変数から取得) ---
my $db_driver = $ENV{'DB_DRIVER'} || 'mysql';
my $db_name   = $ENV{'DB_NAME'}   || die "DB_NAME not set";
my $db_host   = $ENV{'DB_HOST'}   || die "DB_HOST not set";
my $db_user   = $ENV{'DB_USER'}   || die "DB_USER not set";
my $db_pass   = $ENV{'DB_PASS'}   || '';

# --- メイン処理 ---

# 1. zipファイルを解凍
print "1. Unzipping $zip_file to $tmp_dir...\n";
remove_tree($tmp_dir) if -d $tmp_dir;
make_path($tmp_dir);

my $zip = Archive::Zip->new();
die 'Error reading zip file' unless $zip->read($zip_file) == AZ_OK;
$zip->extractTree('', "$tmp_dir/");
print "Unzip completed.\n";

# 2. DB接続
print "2. Connecting to database...\n";
my $dsn = "dbi:$db_driver:database=$db_name;host=$db_host";
my $dbh = DBI->connect($dsn, $db_user, $db_pass, { PrintError => 1, RaiseError => 1, AutoCommit => 0 });
die "DBI connect failed: $DBI::errstr" unless $dbh;
$dbh->do('SET NAMES utf8mb4');
print "Database connected.\n";

# 3. テーブル作成
print "3. Creating tables...\n";
create_tables($dbh);
print "Tables created.\n";

# 4. データインポート
print "4. Importing data...\n";
my $data_dir = File::Spec->catdir($tmp_dir, 'data');
import_data($dbh, $data_dir);
print "Data import completed.\n";

# 5. クリーンアップ
print "5. Cleaning up temporary files...\n";
remove_tree($tmp_dir);
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

    my $data_ins_sql = "INSERT INTO `data_tbl` (`page`, `source`, `lastmodified`) VALUES (?, ?, ?)";
    my $backup_ins_sql = "INSERT INTO `backup_tbl` (`page`, `source`, `lastmodified`) VALUES (?, ?, ?)";
    my $attr_ins_sql = "INSERT INTO `attr_tbl` (`page`, `key`, `value`, `lastmodified`) VALUES (?, ?, ?, ?)";

    my $data_sth = $dbh->prepare($data_ins_sql);
    my $backup_sth = $dbh->prepare($backup_ins_sql);
    my $attr_sth = $dbh->prepare($attr_ins_sql);

    eval {
        foreach my $file (@files) {
            my $file_path = File::Spec->catfile($data_dir, $file);
            my $content = do { local $/; open my $fh, '<:utf8', $file_path or die "Can't open $file_path: $!"; <$fh> };
            my $mtime = (stat($file_path))[9];

            if ($file =~ /\.wiki$/) {
                my $page_name = $file;
                $page_name =~ s/\.wiki$//;
                $data_sth->execute($page_name, $content, $mtime);
                print "  Imported wiki: $page_name\n";
            } elsif ($file =~ /\.bak$/) {
                my $page_name = $file;
                $page_name =~ s/\.bak$//;
                $backup_sth->execute($page_name, $content, $mtime);
                print "  Imported backup: $page_name\n";
            } elsif ($file =~ /\.attr$/) {
                my $page_name = $file;
                $page_name =~ s/\.attr$//;
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
