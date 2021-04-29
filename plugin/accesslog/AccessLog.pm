###############################################################################
#
# <p>アクセスログを整形して一覧表示します。</p>
#
###############################################################################
package plugin::accesslog::AccessLog;
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
	my $self   = shift;
	my $wiki   = shift;
	my $log_path  = $wiki->config('log_dir')."/".$wiki->config('access_log_file');
	my $font      = $wiki->config('access_log_font');
	my $c_cnt = $wiki->config('access_log_cnt');
	my $disp_cnt  = 100;
	my $an_cnt    = 10;
	my @data   = ();
	my @lines  = ();
	my $output = "";
	my $i = 0;
	my $k = 0;

	if($c_cnt > $disp_cnt){
		$disp_cnt = $c_cnt;
	}

	$wiki->set_title("アクセスログ閲覧");

	open(LH ,"<$log_path");
	@data = <LH>;
	close(LH);

	my $page = int($#data / $disp_cnt);
	my $page_t = $#data % $disp_cnt;
	if($page_t > 0){
		$page++;
	}
	my $an = "";
	my $end_an   = $page;
	my $start_an = $end_an - $an_cnt;
	my $set_s_an = $start_an - 1;
	my $set_e_an = $end_an;
	my $pre_an = "<a href=\"#\" onClick=\"javascript:get_anc(0);\">&lt;&lt;</a>";
	for($k=1;$k<=$page;$k++){
		if($k > $start_an && $k <= $end_an){
			$an .= "<a href=\"#\" onClick=\"javascript:get_list($k);\">$k</a>|";
		}
	}
	my $next_an = "<a href=\"#\" onClick=\"javascript:get_anc(1);\">&gt;&gt;</a>";

	if($page <= $an_cnt){
		$pre_an  = "";
		$next_an = "";
	}

	my $end = $#data;
	my $start = ($end - $page_t);
	foreach(@data){
		if($i >= $start && $i <= $end){
			chomp;
			(@lines) = split(/\s/);
			$output .= "<tr><td>".Util::url_decode($lines[0])."</td>";
			$output .= "<td>$lines[1] $lines[2]</td>";
			$output .= "<td>$lines[3]</td>";
			$output .= "<td>".Util::url_decode($lines[4])."</td>";
			$output .= "<td>\n";
			for($k=5;$k<=$#lines;$k++){
				$output .= $lines[$k]." ";
			}
		}
		$i++;
	}

	my $data =<<"__HTML__";
<script>
var targetId = 'result';
var nextId = 'next';
var preId = 'pre';
var ancId = 'anc';
var text = '';
var pre_num = $set_s_an;
var next_num = $set_e_an;
var now_start = $set_s_an+1;
var now_end = $set_e_an;
var pre_a = '$pre_an';
var next_a = '$next_an';
var link_base_1 = '<a href=\\"#\\" onClick=\\"javascript:get_list(';
var link_base_2 = ');\\">';
var link_base_3 = '</a>|';
var next_f = 0;
var pre_f = 1;

function get_anc(flg){
  var link = '';
  if(flg == 0){
    if(now_start > 0){
      var number = now_start;
      for(var i = 0 ; i < $an_cnt ; i++){
        link += link_base_1+number+link_base_2+number+link_base_3;
        number++;
      }
      now_start--;
      now_end--;
      if(now_start <= 0 && pre_f == 1){
        pre_f = 0;
        var targetNode = document.getElementById(preId);
        targetNode.innerHTML = '';
      }
      if(now_end < $set_e_an && next_f == 0){
        next_f = 1;
        var targetNode = document.getElementById(nextId);
        targetNode.innerHTML = next_a;
      }
    }else{
      return false;
    }
  }else{
    if(now_end < $set_e_an){
      var number = now_start+2;
      for(var i = 0 ; i < $an_cnt ; i++){
        link += link_base_1+number+link_base_2+number+link_base_3;
        number++
      }
      now_start++;
      now_end++;
      if(now_end >= $set_e_an && next_f == 1){
        next_f = 0;
        var targetNode = document.getElementById(nextId);
        targetNode.innerHTML = '';
      }
      if(now_start >= 0 && pre_f == 0){
        pre_f = 1;
        var targetNode = document.getElementById(preId);
        targetNode.innerHTML = pre_a;
      }
    }else{
      return false;
    }
  }
  var targetNode = document.getElementById(ancId);
  targetNode.innerHTML = link;
}

function _initialize(file) {
	var xmlHttpRequest = _createXmlHttpObject();
	xmlHttpRequest.open('GET', file, false);
	xmlHttpRequest.send(null);
	text = xmlHttpRequest.responseText;
}

function _createXmlHttpObject() {
	var xmlHttpRequest = false;
	try {
		xmlHttpRequest = new ActiveXObject('Msxml2.XMLHTTP');
	} catch (e) {
		try {
			xmlHttpRequest = new ActiveXObject('Microsoft.XMLHTTP');
		} catch (E) {
			xmlHttpRequest = false;
		}
	}
	if (!xmlHttpRequest && typeof XMLHttpRequest != 'undefined') {
		xmlHttpRequest = new XMLHttpRequest();
	}
	return xmlHttpRequest;
}

function init_action(num){
    var path = './get_accesslog.cgi?file=$log_path&font=$font&disp=$disp_cnt&num='+num;
    _initialize(path);
}

function get_list(num) {
    init_action(num);

    var targetNode = document.getElementById(targetId);
    targetNode.innerHTML = text;
}

</script>
<div>
<div id="pre">$pre_an</div><div id="anc">$an</div><div id="next"> </div>
</div>
<div id="result">
<table width="10%">
</table>
<table width="100%" style="font-size: $font;">
<tr><td>Page</td><td>Time</td><td>IP</td><td>Referrer</td><td>Agent</td></tr>
$output
</table>
</div>
__HTML__

	return $data;
}

1;
