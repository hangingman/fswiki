###############################################################################
# <p>
# DBI対応の標準データベース・ストレージ
# </p>
###############################################################################
package plugin::dbi::StandardDatabaseStorage;
use strict;
use warnings;
use Wiki::DefaultStorage;
use DBI;
our @ISA;

# バージョン情報
our $VERSION;
$VERSION = '0.0.3 - 2006/05/08';

@ISA = qw(Wiki::DefaultStorage);
#==============================================================================
# <p>
# コンストラクタ
# </p>
#==============================================================================
sub new {
	my $class  = shift;
	my $wiki   = shift;

	my $self = Wiki::DefaultStorage->new($wiki);

	# ＤＢ設定
	$self->{db_driver} = $wiki->{'config'}->{'db_driver'};
	$self->{db_host}   = $wiki->{'config'}->{'db_host'};
	$self->{db_name}   = $wiki->{'config'}->{'db_name'};
	$self->{db_user}   = $wiki->{'config'}->{'db_user'};
	$self->{db_pass}   = $wiki->{'config'}->{'db_pass'};
	$self->{db_port}   = $wiki->{'config'}->{'db_port'};

	# Farmでのパスの置換え
	my $cgi = $wiki->{CGI};

	# 拡張機能の呼び出し
	&_load_extension();

	return bless $self,$class;
}

#------------------------------------------------------------------------------
# <p>
# ＤＢ利用時の拡張機能の読み込み
# </p>
#------------------------------------------------------------------------------
sub _load_extension {
	# 拡張モジュールディレクトリの取得
	my $pkg = __PACKAGE__;
	$pkg =~ s/::/\//g;
	$pkg = $INC{$pkg.'.pm'};
	$pkg =~ s/\/[^\/]+$//;
	my $extpath = $pkg.'/extension';
	# モジュールファイル検索
	opendir(DIR,$extpath);
	my ($entry,@list);
	while($entry = readdir(DIR)){
		my $type = substr($entry,rindex($entry,"."));
		if ($type eq '.pm') {
			push(@list, $extpath.'/'.$entry);
		}
	}
	closedir(DIR);
	foreach my $module (@list) {
		eval {
			require $module;
		};
	}
}

#------------------------------------------------------------------------------
# <p>
# ＤＢ接続
# </p>
#------------------------------------------------------------------------------
sub get_connection {
	my $self = shift;
	my $farm = shift;

	$farm =~ s/^\///;
	if ( defined($farm) && $farm ne '' ) {
		$farm = '/'.$farm;
	}
	$farm = '' if ( !defined($farm) );
	my $hDB = $self->{db}->{$farm}->{handle};

	if ( !defined($self->{db}->{$farm}->{handle}) ) {
		my $dbdriver = $ENV{'DB_DRIVER'} || $self->{db_driver};
		my $dbname = $ENV{'DB_NAME'} || $self->{db_name};
		my $dbhost = $ENV{'DB_HOST'} || $self->{db_host};
		my $dbport = $ENV{'DB_PORT'} || $self->{db_port};
		my $user = $ENV{'DB_USER'} || $self->{db_user};
		my $pass = $ENV{'DB_PASS'} || $self->{db_pass};

		my $dsn;
		if ($dbdriver eq 'mysql' || $dbdriver eq 'MariaDB') {
		    $dsn = "dbi:$dbdriver:database=$dbname;host=$dbhost;port=$dbport";
		    $dsn .= ";mysql_ssl=1" if $dbdriver eq 'mysql';
		} else { # SQLite by default
		    $dsn = "dbi:$dbdriver:database=$dbname";
		}

		$hDB = DBI->connect($dsn, $user, $pass, {PrintError=>0});
		die "$DBI::errstr " if (!$hDB);
		# キャッシュ
		$self->{db}->{$farm}->{handle} = $hDB;
	}
	return $hDB;
}

#==============================================================================
# <p>
# ステートメント・ハンドルの取得
# </p>
#==============================================================================
sub prepare {
	my $self = shift;
	my $sql  = shift;
	my $farm = shift;

	my $hDB;
	$hDB = $self->get_connection($farm);
	return undef if (!defined($hDB));
	return $hDB->prepare($sql);
}

#==============================================================================
# <p>
# ページを取得
# </p>
#==============================================================================
sub get_page {
	my $self = shift;
	my $page = shift;
	my $path = shift;

#	return $self->SUPER::get_page($page, $path);

	if (!defined($self->{"$path:source"}->{$page})) {
		my ($sql, $hst, $rslt) = undef;
		my @row = undef;

		$sql = "SELECT `source` FROM `data_tbl` WHERE `page` = ?";
		$hst = $self->prepare($sql,$path); die "$DBI::errstr " if (!$hst);
		$rslt = $hst->execute($page); die "$DBI::errstr " if (!$rslt);
		@row = $hst->fetchrow_array();
		$hst->finish();

		# キャッシュ
		$self->{"$path:source"}->{$page} = $row[0];
	}
	return $self->{"$path:source"}->{$page};
}

#==============================================================================
# <p>
# ページを保存
# </p>
#==============================================================================
sub save_page {
	my $self    = shift;
	my $page    = shift;
	my $content = shift;
	my $sage    = shift;
	my $wiki    = $self->{wiki};

	$self->SUPER::save_page($page, $content, $sage);

	$content = '' if($content =~ /^[\r\n]+$/s); # added for opera

	# ページ名とページ内容の補正
	$page = Util::trim($page);
	$content =~ s/\r\n/\n/g;
	$content =~ s/\r/\n/g;

	# バックアップ
	if ( !defined($self->backup($page)) ) {
		# backupがない場合は、page_levelをデフォルト値に設定する。
		my $login = $wiki->get_login_info();
		my $level = 0;
		if (defined($login)) {
			if ($login->{type} == 1) {
				$level = 1;
			} elsif ($login->{type} == 0) {
				$level = 2;
			}
		}
		if ($level > $wiki->config('refer_level')) {
			$level = $wiki->config('refer_level');
		}
		$wiki->set_page_level($page, $level);
	} else {
		$self->_dbs_rename_old_history($page);
	}

	# 書き込む
	my ($sql, $hst, $rslt) = undef;
	my @row = undef;

	if($content eq ""){
		# 削除処理
		$sql = "DELETE FROM `data_tbl` WHERE `page` = ?";
		$hst = $self->prepare($sql); die "$DBI::errstr " if (!$hst);
		$rslt = $hst->execute($page);die "$DBI::errstr " if (!$rslt);
		$hst->finish();
		$wiki->set_page_level($page);
		# キャッシュの更新
		$self->{':source'}->{$page} = undef;
	} else {
		# 更新処理
		$sql = "SELECT COUNT(*) FROM `data_tbl` WHERE `page` = ?";
		$hst = $self->prepare($sql); die "$DBI::errstr " if (!$hst);
		$rslt = $hst->execute($page); die "$DBI::errstr " if (!$rslt);
		@row = $hst->fetchrow_array();
		$hst->finish();
		if ($row[0] gt 0) {
			$sql = "UPDATE `data_tbl` SET `source` = ?, `lastmodified` = ? WHERE `page` = ?";
			$hst = $self->prepare($sql); die "$DBI::errstr " if (!$hst);
			$rslt = $hst->execute($content, time(), $page); die "$DBI::errstr " if (!$rslt);
			$hst->finish();
		} else {
			$sql = "INSERT INTO `data_tbl` VALUES(?, ?, ?)";
			$hst = $self->prepare($sql); die "$DBI::errstr " if (!$hst);
			$rslt = $hst->execute($page, $content, time());die "$DBI::errstr " if (!$rslt);
			$hst->finish();
		}
		# キャッシュの更新
		$self->{':source'}->{$page} = $content;
	}
}

#==============================================================================
# <p>
# バックアップの作成
# </p>
#==============================================================================
sub backup {
	my $self    = shift;
	my $page    = shift;

	my $wiki = $self->{wiki};
	my ($sql, $hst, $rslt) = undef;
	my @row = undef;

	# 更新前ソースの取得
	$sql = "SELECT `source` FROM `data_tbl` WHERE `page` = ?";
	$hst = $self->prepare($sql); die "$DBI::errstr " if (!$hst);
	$rslt = $hst->execute($page); die "$DBI::errstr " if (!$rslt);
	@row = $hst->fetchrow_array();
	$hst->finish();
	if ( $#row >= 0 ) {
		my $contents = $row[0];
		my @row = undef;
		$sql = "INSERT INTO `backup_tbl` VALUES(?, ?, ?)";
		$hst = $self->prepare($sql); die "$DBI::errstr " if (!$hst);
		$rslt = $hst->execute($page, $contents, time()); die "$DBI::errstr " if (!$rslt);
		$hst->finish();
		return $contents;
	}
	return undef;
}

#------------------------------------------------------------------------------
# <p>
# 保存世代数を超えた分を削除するプライベートメソッド
# </p>
#------------------------------------------------------------------------------
sub _dbs_rename_old_history {
	my $self  = shift;
	my $page  = shift;
	my $wiki  = $self->{wiki};

	# 無制限の場合は何もしない
	if($self->{backup}==0){
		return;
	}

	my ($sql, $hst, $rslt) = undef;
	my @row = undef;
	$sql = "SELECT `lastmodified` FROM `backup_tbl` WHERE `page` = ? ORDER BY `lastmodified` DESC";
	$hst = $self->prepare($sql); die "$DBI::errstr " if (!$hst);
	$rslt = $hst->execute($page); die "$DBI::errstr " if (!$rslt);
	my $count = 0;
	my $lastmodified = 0;
	while (@row = $hst->fetchrow_array()) {
		$count++;
		$lastmodified = $row[0];
		last if ($count > $self->{backup});
	}
	$hst->finish();
	# バックアップ数以上のバックアップデータを削除
	if ($count > $self->{backup}) {
		$sql = "DELETE FROM `backup_tbl` WHERE `page` = ? AND `lastmodified` <= ?";
		$hst = $self->prepare($sql); die "$DBI::errstr " if (!$hst);
		$rslt = $hst->execute($page,$lastmodified); die "$DBI::errstr " if (!$rslt);
		$hst->finish();
	}
}

#==============================================================================
# <p>
# ページの一覧を取得。
# </p>
#==============================================================================
sub get_page_list {
	my $self   = shift;
	my $args   = shift;
	my $wiki   = $self->{wiki};
	my $sort   = "name";
	my $permit = "all";
	my $max    = 0;

#	return $self->SUPER::get_page_list($args);

	my ($sql, $hst, $rslt) = undef;

	# 引数を解釈
	if(defined($args)){
		if(defined($args->{-sort})){
			$sort = $args->{-sort};
		}
		if(defined($args->{-permit})){
			$permit = $args->{-permit};
		}
		if(defined($args->{-max})){
			$max = $args->{-max};
		}
	}
	# ページの一覧を取得
	$sql = "SELECT `page` FROM `data_tbl`";
	$hst = $self->prepare($sql); die "$DBI::errstr " if (!$hst);
	$rslt = $hst->execute(); die "$DBI::errstr " if (!$rslt);
	my ($name, @list, @row) = undef;
	while (@row = $hst->fetchrow_array()) {
		$name = $row[0];
		my $flag = 0;
		# 参照権のあるページのみ
		if($permit eq "show"){
			if($wiki->can_show($name)){
				$flag = 1;
			}

		} elsif($permit eq "modify"){
			if($wiki->can_modify_page($name)){
				$flag = 1;
			}

		# 全てのページ
		} elsif($permit eq "all"){
			$flag = 1;

		# それ以外の場合はエラー
		} else {
			die "permitオプションの指定が不正です。";
		}
		if($flag == 1){
			push(@list, $name);
		}
	}
	$hst->finish();

	# 名前でソート
	if($sort eq "name"){
		@list = sort { $a cmp $b } @list;

	# 更新日時（新着順）にソート
	} elsif($sort eq "last_modified"){
		@list =  map  { $_->[0] }
		         sort { $b->[1] <=> $a->[1] }
		         map  { [$_, $wiki->get_last_modified2($_)] } @list;

	# それ以外の場合はエラー
	} else {
		die "sortオプションの指定が不正です。";
	}

	return $max == 0 ? @list : splice(@list, 0, $max);
}

#==============================================================================
# <p>
# ページの最終更新時刻を取得（物理的）
# </p>
#==============================================================================
sub get_last_modified {
	my $self   = shift;
	my $page   = shift;
	my $modtime = $self->{modtime_cache};

#	return $self->SUPER::get_last_modified($page);

	if(defined($modtime->{$page})){
		return $modtime->{$page};
	}

	my ($sql, $hst, $rslt) = undef;
	my @row = undef;

	$sql = "SELECT `lastmodified` FROM `data_tbl` WHERE `page` = ?";
	$hst = $self->prepare($sql); die "$DBI::errstr " if (!$hst);
	$rslt = $hst->execute($page); die "$DBI::errstr " if (!$rslt);
	@row = $hst->fetchrow_array();
	$hst->finish();

	# キャッシュ
	$self->{modtime_cache}->{$page} = $row[0];

	return $row[0];
}

#==============================================================================
# <p>
# ページの最終更新時刻を取得（論理的）
# </p>
#==============================================================================
sub get_last_modified2 {
	my $self   = shift;
	my $page   = shift;

#	return $self->SUPER::get_last_modified2($page);

	return $self->get_last_modified($page);
}

#===============================================================================
# <p>
# ページが存在するかどうか調べる
# </p>
#===============================================================================
sub page_exists {
	my $self = shift;
	my $page = shift;
	my $path = shift;

#	return $self->SUPER::page_exists($page, $path);

	if($self->{exists_cache} and defined($self->{exists_cache}->{"$path:$page"})){
		return $self->{exists_cache}->{"$path:$page"};
	}

	my ($sql, $hst, $rslt) = undef;
	my @row = undef;

	$sql = "SELECT COUNT(*) FROM `data_tbl` WHERE `page` = ?";
	$hst = $self->prepare($sql,$path); die "$DBI::errstr " if (!$hst);
	$rslt = $hst->execute($page); die "$DBI::errstr " if (!$rslt);
	@row = $hst->fetchrow_array();
	$hst->finish();

	my $exists = ($row[0] gt 0)?1:undef;
	$self->{exists_cache}->{"$path:$page"} = $exists;

	return $exists;
}

#==============================================================================
# <p>
# バックアップタイプを取得(single|all)。
# setup.datの設定内容によって、１世代のみの場合はsingle、
# 世代バックアップを行っている場合はallを返却します。
# </p>
#==============================================================================
sub backup_type {
	my $self = shift;

	return $self->SUPER::backup_type();
}

#==============================================================================
# <p>
# 世代バックアップを行っている場合にバックアップ時刻の一覧を取得します。
# １世代のみバックアップの設定で動作している場合はundefを返します。
# </p>
#==============================================================================
sub get_backup_list {
	my $self = shift;
	my $page = shift;

#	return $self->SUPER::get_backup_list($page);

	if($self->{backup}==1){
		return undef;
	} else {
		my ($sql, $hst, $rslt) = undef;
		my @row = undef;

		$sql = "SELECT `lastmodified` FROM `backup_tbl` WHERE `page` = ? ORDER BY `lastmodified` DESC";
		$hst = $self->prepare($sql); die "$DBI::errstr " if (!$hst);
		$rslt = $hst->execute($page); die "$DBI::errstr " if (!$rslt);
		my @datelist;
		my $count = 0;
		while (@row = $hst->fetchrow_array()) {
			push(@datelist, Util::format_date($row[0]));
			$count++;
			if ( $self->{backup} > 0 ) {
				last if ($count >= $self->{backup});
			}
		}
		$hst->finish();
		return @datelist;
	}
}

#==============================================================================
# <p>
# バックアップを取得します。
# backup_type=allの場合は第二引数で世代(0～)を指定します。
# </p>
#==============================================================================
sub get_backup {
	my $self     = shift;
	my $page     = shift;
	my $gen      = shift;
	my $content  = "";
	my $filename = "";

#	return $self->SUPER::get_backup($page, $gen);

	my ($sql, $hst, $rslt) = undef;
	my @row = undef;

	# 件数の取得
	$sql = "SELECT COUNT(*) FROM `backup_tbl` WHERE `page` = ?";
	$hst = $self->prepare($sql); die "$DBI::errstr " if (!$hst);
	$rslt = $hst->execute($page); die "$DBI::errstr " if (!$rslt);
	@row = $hst->fetchrow_array();
	$hst->finish();
	my $max = $row[0];

	# 指定されたバックアップデータの取得
	$sql = "SELECT `source`, `lastmodified` FROM `backup_tbl` WHERE `page` = ? ORDER BY `lastmodified` DESC";
	$hst = $self->prepare($sql); die "$DBI::errstr " if (!$hst);
	$rslt = $hst->execute($page); die "$DBI::errstr " if (!$rslt);
	my $count = ($max < $self->{backup})?$max:$self->{backup};
	while (@row = $hst->fetchrow_array()) {
		if ( !defined($gen) || $gen == 0 || $gen < 0 || $self->{backup} == 1) {
			$content = $row[0];
			last;
		}
		if ( $count <= $gen ) {
			$content = $row[0];
			last;
		}
		$count--;
	}
	$hst->finish();
	return $content;
}

#==============================================================================
# <p>
# ページを凍結します
# </p>
#==============================================================================
sub freeze_page {
	my $self = shift;
	my $page = shift;

	$self->SUPER::freeze_page($page);

	if(!$self->is_freeze($page)){
		my ($sql, $hst, $rslt) = undef;
		my @row = undef;

		$sql = "SELECT COUNT(*) FROM `attr_tbl` WHERE `page` = ? AND `key` = ?";
		$hst = $self->prepare($sql); die "$DBI::errstr " if (!$hst);
		$rslt = $hst->execute($page, 'freeze'); die "$DBI::errstr " if (!$rslt);
		@row = $hst->fetchrow_array();
		$hst->finish();
		if ( $row[0] > 0 ) {
			# UPDATE
			$sql = "UPDATE `attr_tbl` SET `value` = ?, `lastmodified` = ? WHERE `page` = ? AND `key` = ?";
			$hst = $self->prepare($sql); die "$DBI::errstr " if (!$hst);
			$rslt = $hst->execute('1',time(),$page,'freeze'); die "$DBI::errstr " if (!$rslt);
			$hst->finish();
		} else {
			# INSERT
			$sql = "INSERT INTO `attr_tbl` VALUES(?, ?, ?, ?)";
			$hst = $self->prepare($sql); die "$DBI::errstr " if (!$hst);
			$rslt = $hst->execute($page,'freeze','1',time()); die "$DBI::errstr " if (!$rslt);
			$hst->finish();
		}
		# リダイレクトすれば不要だけど…
		push(@{$self->{':freeze_list'}},$page);
	}
}

#==============================================================================
# <p>
# ページの凍結を解除します
# </p>
#==============================================================================
sub un_freeze_page {
	my $self = shift;
	my $page = shift;

	$self->SUPER::un_freeze_page($page);

	if($self->is_freeze($page)){
		my ($sql, $hst, $rslt) = undef;
		my @row = undef;

		$sql = "SELECT COUNT(*) FROM `attr_tbl` WHERE `page` = ? AND `key` = ?";
		$hst = $self->prepare($sql); die "$DBI::errstr " if (!$hst);
		$rslt = $hst->execute($page, 'freeze'); die "$DBI::errstr " if (!$rslt);
		@row = $hst->fetchrow_array();
		$hst->finish();
		if ( $row[0] > 0 ) {
			# DELETE
			$sql = "DELETE FROM `attr_tbl` WHERE `page` = ? AND `key` = ?";
			$hst = $self->prepare($sql); die "$DBI::errstr " if (!$hst);
			$rslt = $hst->execute($page,'freeze'); die "$DBI::errstr " if (!$rslt);
			$hst->finish();
		}
		# リダイレクトすれば不要だけど…
		@{$self->{':freeze_list'}} = grep(!/^\Q$page\E$/,@{$self->{':freeze_list'}});
	}
}

#==============================================================================
# <p>
# 凍結リストを取得
# </p>
#==============================================================================
sub get_freeze_list {
	my $self = shift;
	my $path = shift;

#	return $self->SUPER::get_freeze_list($path);

	if(!defined($path)){
		$path = "";
	}

	if(defined($self->{"$path:freeze_list"})){
		return @{$self->{"$path:freeze_list"}};
	}

	my ($sql, $hst, $rslt) = undef;
	my @row = undef;
	my @list;

	$sql = "SELECT `page` FROM `attr_tbl` WHERE `key` = ?";
	$hst = $self->prepare($sql,$path); die "$DBI::errstr " if (!$hst);
	$rslt = $hst->execute('freeze'); die "$DBI::errstr " if (!$rslt);
	while ( @row = $hst->fetchrow_array() ) {
		push @list,$row[0];
	}
	$hst->finish();

	$self->{"$path:freeze_list"} = \@list;
	return @list;
}

#==============================================================================
# <p>
# 引数で渡したページが凍結中かどうかしらべます
# </p>
#==============================================================================
sub is_freeze {
	my $self = shift;
	my $page = shift;
	my $path = shift;

#	return $self->SUPER::is_freeze($page,$path);
	foreach my $freeze_page ($self->get_freeze_list($path)){
		if($freeze_page eq $page){
			return 1;
		}
	}

	return 0;
}

#==============================================================================
# <p>
# ページの参照レベルを設定します。
# </p>
#==============================================================================
sub set_page_level {
	my $self  = shift;
	my $page  = shift;
	my $level = shift;

	$self->SUPER::set_page_level($page,$level);

	my ($sql, $hst, $rslt) = undef;
	my @row = undef;

	$sql = "SELECT COUNT(*) FROM `attr_tbl` WHERE `page` = ? AND `key` = ?";
	$hst = $self->prepare($sql); die "$DBI::errstr " if (!$hst);
	$rslt = $hst->execute($page, 'page_level'); die "$DBI::errstr " if (!$rslt);
	@row = $hst->fetchrow_array();
	$hst->finish();
	if ( $row[0] > 0 ) {
		# UPDATE
		$sql = "UPDATE `attr_tbl` SET `value` = ?, `lastmodified` = ? WHERE `page` = ? AND `key` = ?";
		$hst = $self->prepare($sql); die "$DBI::errstr " if (!$hst);
		$rslt = $hst->execute($level,time(),$page,'page_level'); die "$DBI::errstr " if (!$rslt);
		$hst->finish();
	} else {
		# INSERT
		$sql = "INSERT INTO `attr_tbl` VALUES(?, ?, ?, ?)";
		$hst = $self->prepare($sql); die "$DBI::errstr " if (!$hst);
		$rslt = $hst->execute($page,'page_level',$level,time()); die "$DBI::errstr " if (!$rslt);
		$hst->finish();
	}
	# キャッシュ
	if (defined($self->{':show_level'})) {
		$self->{':show_level'}->{$page} = $level;
	}
}

#==============================================================================
# <p>
# ページの参照レベルを取得します。
# </p>
#==============================================================================
sub get_page_level {
	my $self = shift;
	my $page = shift;
	my $path = shift;

#	return $self->SUPER::get_page_level($page,$path);

	if(!defined($path)){
		$path = "";
	}

	unless(defined($self->{"$path:show_level"})){
		my ($sql, $hst, $rslt) = undef;
		my @row = undef;

		$sql = "SELECT `page`, `value` FROM `attr_tbl` WHERE `key` = ?";
		$hst = $self->prepare($sql,$path); die "$DBI::errstr " if (!$hst);
		$rslt = $hst->execute('page_level'); die "$DBI::errstr " if (!$rslt);
		while (@row = $hst->fetchrow_array()) {
			$self->{"$path:show_level"}->{$row[0]} = $row[1];
		}
		$hst->finish();
	}

	if(defined($page)){
		if(defined($self->{"$path:show_level"}->{$page})){
			return $self->{"$path:show_level"}->{$page};
		} else {
			#return $self->{wiki}->config('refer_level');
			return 0;
		}
	} else {
		return $self->{"$path:show_level"};
	}
}

#==============================================================================
# <p>
# 終了時に呼び出されます。データベースへの接続を切断します。
# </p>
#==============================================================================
sub finalize {
	my $self = shift;

	# DB接続の終了
	foreach my $farm ( keys(%{$self->{db}}) ) {
		if ( defined($self->{db}->{$farm}->{handle}) ) {
			$self->{db}->{$farm}->{handle}->disconnect();
			$self->{db}->{$farm}->{handle} = undef;
		}
	}
	undef($self->{wiki});
}

1;
