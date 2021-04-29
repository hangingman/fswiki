###############################################################################
# 
# ページを表示するプラグイン
# 
###############################################################################
package plugin::core::ShowPage;
use strict;
use warnings;
#==============================================================================
# コンストラクタ
#==============================================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#==============================================================================
# アクションの実行
#==============================================================================
sub do_action {
	my $self = shift;
	my $wiki = shift;
	my $cgi  = $wiki->get_CGI;
	
	my $pagename = $cgi->param("page");
	if(!defined($pagename) || $pagename eq ""){
		$pagename = $wiki->config("frontpage");
		$cgi->param("page",$pagename);
	}
	
	if($wiki->page_exists($pagename)){
		# アクセスログの記録
		if($wiki->config('log_dir') ne "" && $wiki->config('access_log_file') ne ""){
			&write_log($wiki,$pagename);
		}
		
		# 参照権限のチェック
		if(!$wiki->can_show($pagename)){
			$wiki->set_title("参照権限がありません");
			return $wiki->error("参照権限がありません。");
		}
		
		$wiki->set_title($pagename);
		$wiki->do_hook("show"); # 本当はWiki.pmの中から呼びたい...
		
		return $wiki->process_wiki($wiki->get_page($pagename),1,1);
		
	} else {
		return $wiki->call_handler("EDIT",$cgi);
	}
}

#==============================================================================
# アクセスログの記録
#==============================================================================
sub write_log {
	my $wiki = shift;
	my $page = shift;
	
	my $ip  = $ENV{"REMOTE_ADDR"};
	my $ref = $ENV{"HTTP_REFERER"};
	my $ua  = $ENV{"HTTP_USER_AGENT"};
	if(!defined($ip)  || $ip  eq ""){ $ip  = "-"; }
	if(!defined($ref) || $ref eq ""){ $ref = "-"; }
	if(!defined($ua)  || $ua  eq ""){ $ua  = "-"; }
	
	my $tmp = time.".".$$;	# 現在時刻＆プロセス番号
	my $logname = $wiki->config('log_dir')."/".$wiki->config('access_log_file');
	my $readtmpname = $wiki->config('log_dir')."/".$tmp.".0.tmp";	# テンポラリ名は重複しない一意の名前に
	my $writetmpname = $wiki->config('log_dir')."/".$tmp.".1.tmp";	# 上に同じ

	my $write_record = Util::url_encode($page)." ".&log_date()." $ip $ref $ua\n";
	my $logsize = (stat($logname))[7];
	my $limit_size = $wiki->config('access_log_limit_kbyte') * 1024;
	my $seek = $limit_size - length($write_record);
	my $tmp = 1;
	until (rename $logname,$readtmpname) {				# 排他制御
		die $! if (++$tmp > 6);
		sleep ($tmp / 2);					# 混雑時は待ち時間を長くする
	}
#	rename $logname, $readtmpname;					# for DEBUG
	if ($limit_size && $logsize > $seek) {				# (現在ログサイズ+追記量 > 限度サイズ)か判定
		open(READTMP,"<".$readtmpname) or die $!;
		seek(READTMP,- $seek,2);				# サイズ合わせのため(限度サイズ-追記量)だけシーク
		open(WRITETMP,">".$writetmpname) or die $!;
		my $readlinedata = <READTMP> ;				# 行の途中かも知れないので最初の一行は破棄
		while ($readlinedata = <READTMP>){			# 旧ファイルから新ファイルにせっせとピーコ
			print WRITETMP $readlinedata;
		}
		close(READTMP);
		print WRITETMP $write_record;				# 最後に新しい行を追加
		close(WRITETMP);
		rename $writetmpname, $logname;				# 新ファイルをログファイルに改名
		unlink $readtmpname;					# 旧ファイルは捨てます
	} else {
		open(LOG,">>".$readtmpname) or die $!;
		print LOG $write_record;
		close(LOG);
		rename $readtmpname, $logname;
	}
}

#===============================================================================
# 日付をフォーマット（アクセスログ用）
#===============================================================================
sub log_date {
	my ($sec, $min, $hour, $mday, $mon, $year) = localtime(time());
	return sprintf("%04d/%02d/%02d %02d:%02d:%02d",
	               $year+1900,$mon+1,$mday,$hour,$min,$sec);
}

1;
