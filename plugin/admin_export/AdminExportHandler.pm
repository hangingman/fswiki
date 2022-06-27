###############################################################################
#
# FSWikiのデータをエクスポートするアクションハンドラ
#
###############################################################################
package plugin::admin_export::AdminExportHandler;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
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
# アクションハンドラメソッド
#==============================================================================
sub do_action {
	my $self  = shift;
	my $wiki  = shift;
	my $cgi = $wiki->get_CGI;

	$wiki->set_title("データのエクスポート");

	if($cgi->param("download") ne ""){
		return $self->download_dump($wiki);
	}
	if(!defined($wiki->get_login_info)) {
		return $wiki->error("ログインしていません。");
	}
	my $id = $wiki->get_login_info()->{id};

	return $self->export_form($wiki,$id);
}

#==============================================================================
# FSWikiのダンプのDLフォーム
#==============================================================================
sub export_form {
	my $self = shift;
	my $wiki = shift;

	my $buf = "<h2>データのエクスポート</h2>";
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
	my $yyyymmdd = sprintf("%04d%02d%02d", $year + 1900, $mon + 1, $mday);
	my $file = "fswiki-dump-".$yyyymmdd.".zip";
	$buf .= "<p>".&Util::escapeHTML($file)."</p>\n".
			"<form action=\"".$wiki->create_url()."\" method=\"POST\">\n".
			"  <input type=\"submit\" name=\"download\" value=\"ダウンロード\">\n".
			"  <input type=\"hidden\" name=\"target\" value=\"download\">\n".
			"  <input type=\"hidden\" name=\"action\" value=\"ADMINEXPORT\">\n".
			"</form>\n";

	return $buf;
}

#==============================================================================
# FSWikiのダンプファイルをダウンロード
#==============================================================================
sub download_dump {
	my $self = shift;
	my Wiki $wiki = shift;

	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
	my $yyyymmdd = sprintf("%04d%02d%02d", $year + 1900, $mon + 1, $mday);
	my $download_file = "fswiki-dump-".$yyyymmdd.".zip";

	my Plack::Response $res = Plack::Response->new(200);
	$res->content_type('application/zip');

	my Archive::Zip::Archive $zip = Archive::Zip->new();

	my @export_dirs = ("data_dir", "config_dir", "backup_dir", "log_dir", "attach_dir");
	foreach my $dir (@export_dirs) {
		my $real_dir = $wiki->config($dir);
		my @files = glob "$real_dir/*";
		foreach my $file (@files) {
			next if -d $file;  # ディレクトリのみの場合はzipに含めない
			$zip->addFile($file);
		}
	}

	my ($fh, $filename) = Archive::Zip::tempFile( $wiki->config("log_dir") );
	if ( $zip->writeToFileHandle( $fh ) != AZ_OK) {
		return $wiki->error("ZIPファイル作成に失敗。");
	}
	close $fh;
	open my $zip_fh, '<', $filename or return $wiki->error("ZIPファイル作成に失敗。");

	$res->header('Content-Disposition' => 'inline; filename="' . $download_file . '"');
	$res->body($zip_fh);
	return $res;
}

1;
