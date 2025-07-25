#!/usr/bin/perl

use strict;
use warnings;
use DBI;
use URI::Escape;

my $db_driver = $ENV{DB_DRIVER} || 'mysql';
my $db_host = $ENV{DB_HOST} || 'localhost';
my $db_name = $ENV{DB_NAME} || 'fswiki';
my $db_user = $ENV{DB_USER} || 'root';
my $db_pass = $ENV{DB_PASS} || 'password';

my $dsn = "DBI:$db_driver:database=$db_name;host=$db_host";
my $dbh = DBI->connect($dsn, $db_user, $db_pass, { RaiseError => 1, AutoCommit => 1 });

my $config_file = '/app/tmp_import/config/config.dat.txt';

open(my $fh, '<', $config_file) or die "Cannot open $config_file: $!";

while (my $line = <$fh>) {
    chomp $line;
    next if $line =~ /^\s*$/; # Skip empty lines

    if ($line =~ /^"([^"]+)"="(.*)"$/) {
        my $key = $1;
        my $value = $2;

        # Decode URL-encoded characters in key and value if necessary
        $key = uri_unescape($key);
        $value = uri_unescape($value);

        my $sth = $dbh->prepare("REPLACE INTO config (key_name, value) VALUES (?, ?)");
        $sth->execute($key, $value);
    }
}

close($fh);
$dbh->disconnect();

print "Config data imported successfully.\n";
