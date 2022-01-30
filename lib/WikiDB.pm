package WikiDB;
use strict;
use warnings FATAL => 'all';

###############################################################################
#
# ::FreeStyleWiki
#
# Wiki::DatabaseStorage 移行スクリプト
#
###############################################################################



sub new {
	my $class = shift;
	my $self  = {};
	return bless $self,$class;
};

sub run_psgi {
	# 外部からのリクエスト
	my ($self, $env) = @_;
	#==============================================================================
	# CGIとWikiのインスタンス化
	#==============================================================================
	my $wiki = Wiki->new('setup.dat', $env);
	my $cgi = $wiki->get_CGI($env);
	# ストレージをデフォルトに変更する
	$wiki->{"storage"}->finalize();
	$wiki->{"storage"} = Wiki::DefaultStorage->new($wiki);
	# スクリプト名の上書き
	$wiki->config("script_name", "wikidb.cgi");
	# データベース作成用のインスタンス生成
	my $wikidb = Wiki::DB->new();
	# Session用ディレクトリはFarmでも共通に使用する
	$wiki->config('session_dir',$wiki->config('log_dir'));

	#==============================================================================
	# Farmとして動作する場合
	#==============================================================================
	my $path_info  = $cgi->path_info();
	my $path_count = 0;
	if(length($path_info) > 0){
		# PATH_INFOの最後が/だったら/なしのURLに転送する
		if($path_info =~ m|/$|) {
			$path_info =~ s|/$||;
			$wiki->redirectURL($cgi->url().$path_info);
		}
		$path_info =~ m</([^/]+)$>;
		$wiki->config('script_name', $1);
		$wiki->config('data_dir'   , $wiki->config('data_dir'  ).$path_info);
		$wiki->config('config_dir' , $wiki->config('config_dir').$path_info);
		$wiki->config('backup_dir' , $wiki->config('backup_dir').$path_info);
		$wiki->config('log_dir'    , $wiki->config('log_dir'   ).$path_info);
	}

	#==============================================================================
	# 設定を反映（もうちょっとスマートにやりたいね）
	#==============================================================================
	my $config = &Util::load_config_hash($wiki,$wiki->config('config_file'));
	foreach my $key (keys(%$config)){
		$wiki->config($key,$config->{$key});
	}

	# キャッシュの設定を反映
	my $cache_config = &Util::load_config_hash($wiki,'cache.dat');
	$wiki->config('use_cache'   ,$cache_config->{use_cache});
	$wiki->config('no_cache'    ,$cache_config->{no_cache});
	$wiki->config('remove_cache',$cache_config->{remove_cache});

	#==============================================================================
	# タイムアウトしているセッションを破棄
	#==============================================================================
	$cgi->remove_session($wiki);

	#==============================================================================
	# ユーザ情報の読み込み
	#==============================================================================
	my $users = &Util::load_config_hash($wiki,$wiki->config('userdat_file'));
	foreach my $id (keys(%$users)){
		my ($pass,$type) = split(/\t/,$users->{$id});
		$wiki->add_user($id,$pass,$type);
	}

	#==============================================================================
	# プラグインのインストールと初期化
	#==============================================================================
	# 最低限のプラグインのみインストールする
	my @plugins = split(/,/,"admin,core,info");
	my $plugin_error = '';
	foreach(sort(@plugins)){
		$plugin_error .= $wiki->install_plugin($_);
	}
	# プラグインごとの初期化処理を起動
	$wiki->do_hook("initialize");

	#==============================================================================
	# アクションハンドラの呼び出し
	#==============================================================================
	my ($action, $content);
	$action = $cgi->param("action");
	$action = (!defined($action))?"LOGIN":$action;

	my $login = $wiki->get_login_info();

	# 未ログインの場合はログイン処理を行う。
	if ( !defined($login) ) {
		$action = "LOGIN";
		$content = $wiki->call_handler($action);
	}
	# ログアウト時はログイン画面に戻す
	elsif( $action eq "LOGIN" && defined($cgi->param('logout')) ) {
		$content = $wiki->call_handler($action);
		$wiki->redirectURL($wiki->config('script_name')."?action=LOGIN");
	}
	# 管理者でない場合はログアウト処理を行う。
	elsif( $login->{type} != 0 ) {
		$action = "LOGIN";
		$cgi->param('logout','1');
		$wiki->call_handler($action);
		$cgi->param('logout',"");
		$wiki->{'login_info'} = undef;
		$content = "<div style='color:#ff0000;'>管理者でログインしてください。</div>";
		$content .= $wiki->call_handler($action);
	}
	# 管理者ログイン時は移行画面を表示する
	else {
		if ( $action eq "MAKEDB" ){
			$content .= $wikidb->make_db($wiki);
		}
		else {
			$content .= "<div align='right'>".$wikidb->get_logout_form($wiki)."\n</div>\n";
			$content .= $wikidb->get_db_config_form($wiki)."\n";
			$content .= $wikidb->get_db_cmd_form($wiki);
		}
	}

	# プラグインのインストールに失敗した場合
	$content .= $plugin_error . $content if $plugin_error ne '';

	#==============================================================================
	# レスポンス
	#==============================================================================
	# ページのタイトルを決定
	my $title = "Wiki Database Storage 作成ツール";
	my $output = "";
	my $tmpl = $wikidb->get_template($wiki);
	my $template = HTML::Template->new(
			scalarref => \$tmpl,
			die_on_bad_params => 0,
			loop_context_vars => 1,
			case_sensitive => 1,
			global_vars => 1,
			utf8 => 1);

	$template->param(TITLE => $title, CONTENTS => $content);
	$output = $template->output;

	#------------------------------------------------------------------------------
	# 出力処理
	#------------------------------------------------------------------------------
	my $res = Plack::Response->new(200);
	$res->headers(HTTP::Headers->new(
			Pragma        => 'no-cache',
			Cache_Control => 'no-cache',
			Content_Type  => 'text/html'
	));
	$res->content_encoding('UTF-8');
	$res->body($output);
	return $res->finalize;
};

1;

package Wiki::DB;
use File::Path;
use DBI;
use strict;

#==============================================================================
# コンストラクタ
#==============================================================================
sub new {
	my $class = shift;
	my $self = {};

	return bless $self,$class;
}

sub get_template {
	my $self = shift;
	my $wiki = shift;
	return <<__EOD__;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<meta http-equiv="Content-Style-Type" content="text/css">
<link rel="stylesheet" type="text/css" href="$wiki->{config}->{theme_uri}/default/default.css">
<title><!--TMPL_VAR 'TITLE'--></title>
</head>
<body>
<div style="">
<!--TMPL_VAR 'MESSAGE'-->
</div>
<!--TMPL_VAR 'CONTENTS'-->
</body>
</html>
__EOD__
}

sub get_logout_form {
	my $self = shift;
	my $wiki = shift;
	my $script = $wiki->config('script_name');
	return <<__EOD__;
<form method='POST' action="$script">
	<input type="hidden" name="action" value="LOGIN">
	<input type="submit" name="logout" value="ログアウト">
</form>
__EOD__
}

sub get_db_config_form {
	my $self = shift;
	my $wiki = shift;
	my $script = $wiki->config('script_name');
	my $driver = $wiki->{config}->{db_driver};
	my $drh = DBI->installed_versions($driver);
	return <<__EOD__;
<h2>データベースの操作</h2>
<p>
データベース接続への設定は以下のようになっています。
<table border="1">
<tr><th>設定項目</th><th width="250">設定値</th></tr>
<tr><td>DBI</td><td>$drh->{'DBI'}&nbsp;</td></tr>
<tr><td>DBドライバ</td><td>$wiki->{config}->{db_driver} - $drh->{'DBD::'.$driver}&nbsp;</td></tr>
<tr><td>DBホスト</td><td>$wiki->{config}->{db_host}&nbsp;</td></tr>
<tr><td>DB名</td><td>$wiki->{config}->{db_name}&nbsp;</td></tr>
<tr><td>DBユーザー</td><td>$wiki->{config}->{db_user}&nbsp;</td></tr>
<tr><td>DBパスワード</td><td>$wiki->{config}->{db_pass}&nbsp;</td></tr>
</table>
</p>
__EOD__
}

sub get_db_cmd_form {
	my $self = shift;
	my $wiki = shift;
	my $script = $wiki->config('script_name');
	return <<__EOD__;
<p>
<form method='POST' action="$script">
	DBを作成（再作成）する WikiFarm を指定し、「データベースの作成」ボタンをクリックしてください。<br>
	ルートWikiを指定する場合は "/" を指定してください。<br>
	また、Farm名は "/" で始まるフルパスで指定します。
	<br><br>
	WikiFarm: <input type="text" name="farm" value="/" size=50>
	<input type="hidden" name="action" value="MAKEDB">
	<input type="submit" value="データベースの作成">
</form>
</p>
__EOD__
}

sub make_db {
	Util::debug("exec make_db");
	my $self = shift;
	my $wiki = shift;
	my $html = "";
	eval {
		my $wikifarm = $self->get_wikifarm_instance($wiki, $wiki->get_CGI()->param('farm'));
		if (defined($wikifarm)){
			$html .= $self->db_transition($wikifarm);
		} else {
			return "Wikiインスタンスの作成に失敗しました。"
		}
		$wikifarm->_process_before_exit();
	};
	if($@){
		return $html."<br>$@";
	}
	return $html."<br>"."正常に終了しました。";
}

sub db_transition {
	Util::debug("exec db_transition");
	my $self = shift;
	my $wiki = shift;
	my $hDB  = shift;
	my ($sql,$hst,$hst1,$hst2) = undef;
	my $html = "";
	$html .= "<ul>\n";

	my $dbdriver = $wiki->config('db_driver');
	my $dbname = $wiki->config('db_name');
	my $dbhost = $wiki->config('db_host');
	my $user = $wiki->config('db_user');
	my $pass = $wiki->config('db_pass');

	my $dsn = "dbi:$dbdriver:database=$dbname;host=$dbhost";
	$html .= "<li>データベース接続[$dsn]";
	$hDB = DBI->connect($dsn, $user, $pass, {PrintError=>0});
	if (!$hDB) { $html .= "<br>NG - ".$DBI::errstr."</li>\n"; };  $html .= "<br>OK</li>\n";

	eval {
		$sql = {
				# Drop
				data_drp     => "DROP TABLE IF EXISTS `data_tbl`",
				backup_drp   => "DROP TABLE IF EXISTS `backup_tbl`",
				attr_drp     => "DROP TABLE IF EXISTS `attr_tbl`",
				access_drp   => "DROP TABLE IF EXISTS `access_tbl`",
				data_drp_idx_1   => "DROP INDEX `data_idx_1`",
				backup_drp_idx_1 => "DROP INDEX `backup_idx_1`",
				attr_drp_idx_1   => "DROP INDEX `attr_idx_1`",
				attr_drp_idx_2   => "DROP INDEX `attr_idx_2`",
				access_drp_idx_1 => "DROP INDEX `access_idx_1`",
				access_drp_idx_2 => "DROP INDEX `access_idx_2`",
				# Table
				data_tbl     => "CREATE TABLE `data_tbl` (`page` text, `source` text, `lastmodified` bigint)",
				backup_tbl   => "CREATE TABLE `backup_tbl` (`page` text, `source` text, `lastmodified` bigint)",
				attr_tbl     => "CREATE TABLE `attr_tbl` (`page` text, `key` text, `value` text, `lastmodified` bigint)",
				access_tbl   => "CREATE TABLE `access_tbl` (`page` text, `datetime` text, `remote_addr` text, `referer` text, `user_agent` text, `lastmodified` bigint)",
				# Index
				data_idx_1   => "CREATE UNIQUE INDEX `data_idx_1` ON `data_tbl` (`page`(255))",
				backup_idx_1 => "CREATE UNIQUE INDEX `backup_idx_1` ON `backup_tbl` (`page`(255), `lastmodified` DESC)",
				attr_idx_1   => "CREATE UNIQUE INDEX `attr_idx_1` ON `attr_tbl` (`page`(255), `key`(255))",
				attr_idx_2   => "CREATE UNIQUE INDEX `attr_idx_2` ON `attr_tbl` (`key`(255), `page`(255))",
				access_idx_1 => "CREATE INDEX `access_idx_1` ON `access_tbl` (`lastmodified` DESC)",
				access_idx_2 => "CREATE INDEX `access_idx_2` ON `access_tbl` (`page`(255), `datetime`(255) DESC)",
				# Insert
				data_ins     => "INSERT INTO `data_tbl` VALUES(?, ?, ?)",
				backup_ins   => "INSERT INTO `backup_tbl` VALUES(?, ?, ?)",
				attr_ins     => "INSERT INTO `attr_tbl` VALUES(?, ?, ?, ?)",
		};
		# インデックス／テーブルの削除
		$hst = $hDB->do($sql->{data_drp_idx1});
		$hst = $hDB->do($sql->{backup_drp_idx1});
		$hst = $hDB->do($sql->{attr_drp_idx1});
		$hst = $hDB->do($sql->{attr_drp_idx2});
		$hst = $hDB->do($sql->{access_drp_idx1});
		$hst = $hDB->do($sql->{access_drp_idx2});
		$hst = $hDB->do($sql->{data_drp});
		$hst = $hDB->do($sql->{backup_drp});
		$hst = $hDB->do($sql->{attr_drp});
		$hst = $hDB->do($sql->{access_drp});
		# ページ情報テーブル／インデックス
		$html .= "<li>".$sql->{data_tbl}; $hst = $hDB->do($sql->{data_tbl}); if (!$hst) { $html .= "<br>NG - ".$DBI::errstr."</li>\n"; die; };  $html .= "<br>OK</li>\n";
		$html .= "<li>".$sql->{data_idx_1}; $hst = $hDB->do($sql->{data_idx_1}); if (!$hst) { $html .= "<br>NG - ".$DBI::errstr."</li>\n"; die; }; $html .= "<br>OK</li>\n";
		# バックアップ用テーブル／インデックス
		$html .= "<li>".$sql->{backup_tbl}; $hst = $hDB->do($sql->{backup_tbl}); if (!$hst) { $html .= "<br>NG - ".$DBI::errstr."</li>\n"; die; };  $html .= "<br>OK</li>\n";
		$html .= "<li>".$sql->{backup_idx_1}; $hst = $hDB->do($sql->{backup_idx_1}); if (!$hst) { $html .= "<br>NG - ".$DBI::errstr."</li>\n"; die; }; $html .= "<br>OK</li>\n";
		# ページ属性テーブル／インデックス
		$html .= "<li>".$sql->{attr_tbl}; $hst = $hDB->do($sql->{attr_tbl}); if (!$hst) { $html .= "<br>NG - ".$DBI::errstr."</li>\n"; die; };  $html .= "<br>OK</li>\n";
		$html .= "<li>".$sql->{attr_idx_1}; $hst = $hDB->do($sql->{attr_idx_1}); if (!$hst) { $html .= "<br>NG - ".$DBI::errstr."</li>\n"; die; }; $html .= "<br>OK</li>\n";
		$html .= "<li>".$sql->{attr_idx_2}; $hst = $hDB->do($sql->{attr_idx_2}); if (!$hst) { $html .= "<br>NG - ".$DBI::errstr."</li>\n"; die; }; $html .= "<br>OK</li>\n";
		# アクセスログ・テーブル／インデックス
		$html .= "<li>".$sql->{access_tbl}; $hst = $hDB->do($sql->{access_tbl}); if (!$hst) { $html .= "<br>NG - ".$DBI::errstr."</li>\n"; die; };  $html .= "<br>OK</li>\n";
		$html .= "<li>".$sql->{access_idx_1}; $hst = $hDB->do($sql->{access_idx_1}); if (!$hst) { $html .= "<br>NG - ".$DBI::errstr."</li>\n"; die; }; $html .= "<br>OK</li>\n";
		$html .= "<li>".$sql->{access_idx_2}; $hst = $hDB->do($sql->{access_idx_2}); if (!$hst) { $html .= "<br>NG - ".$DBI::errstr."</li>\n"; die; }; $html .= "<br>OK</li>\n";

		my @list = $wiki->get_page_list({-sort => 'name'});
		$html .= "<li>ページ数：".$#list;

		$hst1 = $hDB->prepare($sql->{data_ins});
		die "$DBI::errstr " if (!$hst1);
		$hst2 = $hDB->prepare($sql->{attr_ins});
		die "$DBI::errstr " if (!$hst2);

		foreach my $page (@list) {
			# ページの登録
			$hst1->execute($page, $wiki->get_page($page), $wiki->get_last_modified2($page) );
			# ページ・レベルの登録
			my $level = $wiki->get_page_level($page);
			$hst2->execute($page, "page_level", $level, time() ) if ( $level > 0 );
			# 凍結情報の登録
			my $freeze = $wiki->is_freeze($page);
			$hst2->execute($page, "freeze", $freeze, time() ) if ( $freeze > 0 );
			#		# タイトル情報の登録
			#		my @title = grep(/^{{title .+}}$/, split(/\n/,$wiki->get_page($page)));
			#		if ( $#title >= 0 ) {
			#			$title[0] =~ s/{{title (.+)}}$/$1/;
			#			$hst2->execute($page, "title", $title[0], time());
			#		}
		}
		$html .= "<br>OK</li>";
	};	# eval
	if ($@) {
		$html .= "<br>エラーが発生しました。 - $@";
	}
	$hst1->finish() if ($hst1);
	$hst2->finish() if ($hst2);
	if ($hDB) {
		$hDB->disconnect();
	}
	$html .= "</ul>\n";
	return $html;
}

#===========================================================
# 指定された WikiFarm 環境のインスタンスを生成します。
# ここで指定する $farm は絶対パスである必要があります。
# この関数は farmlink から流用しています。
#===========================================================
sub get_wikifarm_instance {
	my $self = shift;
	my $rwiki = shift;
	my $farm  = shift;

	# WikiFarm キャッシュから取得する
	my $wiki = undef;

	# InterWikiとKeyword情報のバックアップ
	my $interwiki = $Wiki::Parser::interwiki;
	my $keyword   = $Wiki::Parser::keyword;

	#-----------------------------------------------------------
	# WikiFarm用のwikiインスタンス作成
	#-----------------------------------------------------------
	eval {
		my $wiki = Wiki->new('setup.dat');
		my $cgi = $wiki->get_CGI();

		# ルートWikiへの相対パスの取得
		my $relative_path = $cgi->path_info();
		$relative_path =~ s/[^\/]*//g;
		$relative_path =~ s/\//..\//g;

		# PATH_INFOの上書き
		$cgi->path_info($farm);

		# pageの上書き
		$cgi->param('page',"#farmlink");
		# ストレージをデフォルトに変更する
		$wiki->{"storage"}->finalize();
		$wiki->{"storage"} = Wiki::DefaultStorage->new($wiki);

		# 子Wiki呼出情報の引継ぎ
		$wiki->{farmlink} = $rwiki->{farmlink};

		# Session用ディレクトリはFarmでも共通に使用する
		$wiki->config('session_dir',$wiki->config('log_dir'));
		# Farmとして動作する設定
		my $path_count = 0;
		$wiki->config('script_name', $relative_path.$wiki->config('script_name').$farm);
		$wiki->config('data_dir'   , $wiki->config('data_dir'  ).$farm);
		$wiki->config('config_dir' , $wiki->config('config_dir').$farm);
		$wiki->config('backup_dir' , $wiki->config('backup_dir').$farm);
		$wiki->config('log_dir'    , $wiki->config('log_dir'   ).$farm);
		if(!($wiki->config('theme_uri') =~ /^(\/|http:|https:|ftp:)/)){
			my @paths = split(/\//,$farm);
			$path_count = $#paths;
			for(my $i=0;$i<$path_count;$i++){
				$wiki->config('theme_uri','../'.$wiki->config('theme_uri'));
			}
		}
		# 設定を反映
		my $config = &Util::load_config_hash($wiki,$wiki->config('config_file'));
		foreach my $key (keys(%$config)){
			$wiki->config($key,$config->{$key});
		}
		# 個別に設定が必要なものだけ上書き
		$wiki->config('css'                  ,$wiki->config('theme_uri')."/".$config->{theme}."/".$config->{theme}.".css");
		$wiki->config('site_tmpl'            ,$wiki->config('tmpl_dir')."/site/".$config->{site_tmpl_theme}."/".$config->{site_tmpl_theme}.".tmpl");
		$wiki->config('site_handyphone_tmpl' ,$wiki->config('tmpl_dir')."/site/".$config->{site_tmpl_theme}."/".$config->{site_tmpl_theme}."_handyphone.tmpl");
		# キャッシュの設定を反映
		my $cache_config = &Util::load_config_hash($wiki,'cache.dat');
		$wiki->config('use_cache'   ,$cache_config->{use_cache});
		$wiki->config('no_cache'    ,$cache_config->{no_cache});
		$wiki->config('remove_cache',$cache_config->{remove_cache});

		# InterWikiとKeyword情報の再作成
		$Wiki::Parser::interwiki = Wiki::InterWiki->new($wiki);
		$Wiki::Parser::keyword   = Wiki::Keyword->new($wiki,$Wiki::Parser::interwiki);

		# InterWikiとKeyword情報の保管
		$wiki->{interwiki} = $Wiki::Parser::interwiki;
		$wiki->{keyword}   = $Wiki::Parser::keyword;

		# プラグインのインストールと初期化
		###		my @plugins = split(/\n/,&Util::load_config_text($wiki,$wiki->config('plugin_file')));
		# 最低限のプラグインのみインストールする
		my @plugins = split(/,/,"admin,core,info");
		my $plugin_error = '';
		foreach(sort(@plugins)){
			$plugin_error .= $wiki->install_plugin($_);
		}
		# プラグインごとの初期化処理を起動
		$wiki->do_hook("initialize");
	};

	# InterWikiとKeyword情報のレストア
	$Wiki::Parser::interwiki = $interwiki;
	$Wiki::Parser::keyword   = $keyword;

	if ( defined($wiki) ) {
		# Wiki インスタンスのキャッシュ登録
		$rwiki->{wikifarm}->{$farm} = $wiki;

		# Wiki インスタンスのキャッシュ情報の引継ぎ
		$wiki->{wikifarm} = $rwiki->{wikifarm};
	}

	return $wiki;
}

1;
