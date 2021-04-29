###############################################################################
#
#
###############################################################################
package plugin::bookmarks::Bookmarks;
use strict;
use warnings;
use Jcode;

#==============================================================================
# コンストラクタ
#==============================================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}
#==============================================================================
# パラグラフメソッド
#==============================================================================
sub paragraph {
	my $self = shift;
	my $wiki = shift;
	my $page = shift;
	my $cgi = $wiki->get_CGI();
	my $thispageTITLE = "";

	#my $thispageURL = $wiki->config("server_host").$wiki->create_page_url(&Util::escapeHTML($wiki->get_title()));
	my $thispageURL = $cgi->url;
	# トップページかどうかを判定
	# トップページならサイト名を、それ以外であれば ページ名 - サイト名 形式で出力。
	if($cgi->param("page") eq $wiki->config("frontpage")){
		$thispageTITLE = $wiki->config('site_title');
	} else {
		$thispageTITLE = $wiki->get_title() . " - " .$wiki->config('site_title');
	}
	$thispageTITLE = &Util::escapeHTML($thispageTITLE);

	#UTF8
	my $thispageTITLEu = &Util::url_encode(Jcode->new($thispageTITLE,"euc")->h2z->utf8);
	my $buf = "<div id=\"bookmarks\"><ul>\n";

	#はてなブックマーク
	#http://b.hatena.ne.jp/help/button
	$buf .= "<li><a href=\"http://b.hatena.ne.jp/entry/" .$thispageURL. "\"><img src=\"./img/bookmarks/hatena.gif\" width=\"16\" height=\"12\" alt=\"Hatenaブックマークに追加\"></a></li>\n";

	#livedoorクリップ
	#http://clip.livedoor.com/guide/blog.html
	$buf .= "<li><a href=\"http://clip.livedoor.com/redirect?link=".Util::url_encode($thispageURL)."&amp;title=".$thispageTITLE."&ie=euc\"><img src=\"./img/bookmarks/livedoor.gif\" width=\"16\" height=\"16\" alt=\"livedoorクリップに追加\"></a></li>\n";

	#del.icio.us
	#http://del.icio.us/help/savebuttons
	$buf .= "<li><a href=\"http://del.icio.us/post?url=".Util::url_encode($thispageURL)."&amp;title=".$thispageTITLEu."\" charset=\"utf-8\"><img src=\"./img/bookmarks/delicious.gif\" width=\"16\" height=\"16\" alt=\"del.icio.usに追加\"></a></li>\n";

	#FC2
	#http://bookmark.fc2.com/faq
	$buf .= "<li><a href=\"http://bookmark.fc2.com/user/post?url=".Util::url_encode($thispageURL)."&amp;title=". $thispageTITLEu."\"><img src=\"./img/bookmarks/fc2.gif\" width=\"16\" height=\"16\" alt=\"FC2ブックマークに追加\"></a></li>\n";

	#google
	$buf .= "<li><a href=\"javascript:(function(){var a=window,b=document,c=encodeURIComponent,d=a.open('http://www.google.com/bookmarks/mark?op=edit&amp;output=popup&amp;bkmk='+c(b.location)+'&amp;title='+c(b.title),'bkmk_popup','left='+((a.screenX||a.screenLeft)+10)+',top='+((a.screenY||a.screenTop)+10)+',height=420px,width=550px,resizable=1,alwaysRaised=1');a.setTimeout(function(){d.focus()},300)})();\" title=\"Add Google bookmark\"><img src=\"./img/bookmarks/googlebookmark.gif\" width=\"16\" height=\"16\"></a></li>";

	$buf .= "</ul></div>\n";
	return $buf;
}

1;
