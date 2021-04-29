############################################################
#
# SearchHandler Extension
#
############################################################
package plugin::search::SearchHandler;
use strict;
use warnings;
use plugin::search::SearchHandler;

#===========================================================
# アクションの実行
#===========================================================
sub do_action {
	my $self = shift;
	my $wiki = shift;
	my $cgi = $wiki->get_CGI;
	my $word = Util::trim($cgi->param("word"));

	my $buf = "";

	$wiki->set_title("検索");
	$buf .= "<form method=\"GET\" action=\"".$wiki->config('script_name')."\">\n".
	        "キーワード <input type=\"text\" name=\"word\" size=\"20\" value=\"".$cgi->escapeHTML($word)."\"> ";

	$buf .= "<input type=\"radio\" name=\"t\" id=\"and\" value=\"and\"";
	$buf .= " checked" if($cgi->param("t") ne "or");
	$buf .= "><label for=\"and\">AND</label>\n";
	$buf .= "<input type=\"radio\" name=\"t\" id=\"or\" value=\"or\"";
	$buf .= " checked" if($cgi->param("t") eq "or");
	$buf .= "><label for=\"or\">OR</label>\n";
	$buf .= "<input type=\"checkbox\" id=\"contents\" name=\"c\" value=\"true\"";
	$buf .= " checked" if($cgi->param("c") eq "true");
	$buf .= "><label for=\"contents\">ページ内容も含める</label>\n";

	# 検索速度が速くなったから、並べ替え機能もつけてみる
	$buf .= "<select name=\"sort\">";
	$buf .= "<option value=\"page\"".(($cgi->param('sort') eq 'page')?' selected':'').">名前順</option>";
	$buf .= "<option value=\"lastmodified\"".(($cgi->param('sort') eq 'lastmodified')?' selected':'').">更新日順</option>";
	$buf .= "<option value=\"lastmodified DESC\"".(($cgi->param('sort') eq 'lastmodified DESC')?' selected':'').">更新日順（新着順）</option>";
	$buf .= "</select>";

	$buf .=  "<input type=\"submit\" value=\" 検 索 \">".
	         "<input type=\"hidden\" name=\"action\" value=\"SEARCH\">".
	         "</form>\n";

	#---------------------------------------------------------------------------
	# 検索実行
	if($word ne ""){
		my ($sql, $hst, $hDB) = undef;
		my @row = undef;
		my @words = split(/ +|　+/,$word);
		my $t = "";
		$sql = 'SELECT * FROM `data_tbl` WHERE';
		foreach $word (@words){
			$sql .= $t." (page LIKE '%".$word."%'";
			# ページ名も検索対象にする？
			if($cgi->param("c") eq "true"){
				$sql .= " OR source LIKE '%".$word."%'";
			}
			$sql .= ")";
			if($cgi->param("t") eq "or"){
				$t = " OR";
			} else {
				$t = " AND";
			}
		}
		$sql .= " ORDER BY ".$cgi->param('sort');
		$hDB = $wiki->{storage}->get_connection();
		$hst = $hDB->prepare($sql);
		$hst->execute();
		my $name;
		$buf = $buf."<ul>\n";
		while (@row = $hst->fetchrow_array()){
			$name = @row[0];
			# 参照権限チェック
			next if(!$wiki->can_show($name));
			# ページ名も検索対象にする
			my $page  = $name;
			if($cgi->param("c") eq "true"){
				$page .= "\n".$row[1];
			}
			my $page2 = ($word =~ /[A-Za-z]/) ? Jcode->new($page)->tr('a-z','A-Z') : undef;

			if($cgi->param("t") eq "or"){
				# OR検索 -------------------------------------------------------
				foreach(@words){
					if($_ eq ""){ next; }
					my $index = (defined($page2)) ? index($page2, Jcode->new($_)->tr('a-z','A-Z')) : index($page,$_);
					if($index!=-1){
						$buf .= "<li><a href=\"".$wiki->config('script_name').
						        "?page=".Util::url_encode($name)."\">".
						        $cgi->escapeHTML($name)."</a> - ".
						        Util::escapeHTML(&get_match_content($wiki,$name,$page,$index))."</li>\n";
						last;
					}
				}
			} else {
				# AND検索 ------------------------------------------------------
				my $flag = 1;
				my $index;
				foreach(@words){
					if($_ eq ""){ next; }
					$index = (defined($page2)) ? index($page2, Jcode->new($_)->tr('a-z','A-Z')) : index($page,$_);
					if($index==-1){
						$flag = 0;
						last;
					}
				}
				if($flag == 1){
					$buf .= "<li><a href=\"".$wiki->config('script_name').
					        "?page=".Util::url_encode($name)."\">".
					        $cgi->escapeHTML($name)."</a> - ".
					        Util::escapeHTML(&get_match_content($wiki,$name,$page,$index))."</li>\n";
				}
			}
		}
		$hst->finish();
		$buf = $buf."</ul>\n";
	}
	return $buf;
}

1;
