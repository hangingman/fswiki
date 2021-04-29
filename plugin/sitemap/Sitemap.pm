############################################################
#
# ページ保存時or削除時に記録を行うフックプラグイン
#
############################################################
package plugin::sitemap::Sitemap;
use strict;
use warnings;
use Encode;
#===========================================================
# コンストラクタ
#===========================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}

#===========================================================
# ページ保存後or削除後のフックメソッド
#===========================================================
sub hook {
	my $self = shift;
	my $wiki = shift;

	#ページの重要度
	my $priority ="0.5";
	#ページの更新頻度
	#"always"（常時）"hourly"（毎時）"daily"（毎日）"weekly"（毎週）"monthly"（毎月）"yearly"（毎年）"never"（不変）
	my $changefreq ="weekly";
	#サイトマップ格納ディレクトリ…はトップディレクトリ
	my $file = $wiki->config('sitemap_path');
	my $wiki_host = $wiki->config('server_host') . $wiki->config('wiki_dir') . "/";

	#モジュール用変数
	my $sitemapheader = <<END_OF_DATA;
<?xml version="1.0" encoding="UTF-8"?>
<urlset
	xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9
	http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd">
END_OF_DATA
	my $sitemapfooter = "</urlset>\n";
	my $sitemapattr = "";
	my @list = $wiki->get_page_list({-permit=>'show'});
	my @sitemap;

	push (@sitemap, $sitemapheader);

	#ページリストから一覧を取得し、サイトマップ配列に保管
	foreach (@list){
		#もう少しスマートなやり方がきっとあるはず…
		$sitemapattr = "<url>\n";
		if ($_ eq $wiki->config("frontpage")) { #トップページは色々変えます
			$sitemapattr .= "<loc>" . $wiki->config('server_host'). "/</loc>\n";
			$sitemapattr .= "<lastmod>" . format_date($wiki->get_last_modified2($_)) . "</lastmod>\n";
			$sitemapattr .= "<priority>" . "1.0" . "</priority>\n";
			$sitemapattr .= "<changefreq>" . $changefreq . "</changefreq>\n";
		} else {
			$sitemapattr .= "<loc>" . $wiki_host . $wiki->create_page_url($_) . "</loc>\n";
			$sitemapattr .= "<lastmod>" . format_date($wiki->get_last_modified2($_)) . "</lastmod>\n";
			$sitemapattr .= "<priority>" . $priority . "</priority>\n";
			$sitemapattr .= "<changefreq>" . $changefreq . "</changefreq>\n";
		}
		$sitemapattr .= "</url>\n\n";
		push (@sitemap, $sitemapattr);

	}

	push (@sitemap, $sitemapfooter);

	#ファイルは上書き
	open (DATA, ">$file") or die $!;
	print DATA @sitemap;
	close(DATA);
}

#==============================================================================
# 日付をフォーマット（wikiの関数は使わない）
#==============================================================================
sub format_date {
	my $time = shift;
	my (undef, undef, undef, $mday, $mon, $year, undef) = localtime($time);
	return sprintf("%04d-%02d-%02d",
	               $year+1900,$mon+1,$mday);
}

1;
