###############################################################################
# 
# <p>アクセスログをAjaxで検索して表示します。</p>
# 
###############################################################################
package plugin::accesslog::AccessLogSearch;
use strict;
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
	my $print  = "";
	my $log_path = $wiki->config('log_dir')."/".$wiki->config('access_log_file');
	my $ajax_path = $wiki->config('log_dir')."/ajax_access.log";
	
	use Jcode;
	unlink($ajax_path);
	open(LH ,"<$log_path");
	open(FH ,">$ajax_path");
	foreach(<LH>){
		print FH &Jcode::convert(Util::url_decode($_),"utf8");
	}
	close(FH);
	close(LH);
	
	$wiki->set_title("アクセスログ検索");
	
	$print =<<"EOD";
<meta http-equiv="Content-Script-Type" content="text/javascript" />
<script src="LogSearch.js" type="text/javascript"></script>
<script>
var inputId  = 'search';
var targetId = 'result';

var LS = new LogSearch({
        'logFile':\'$ajax_path\'
});

function search(str) {
        var lists = '';
        var result = LS.search(str);

        for (var i = 0; i < result.length; i++) {
            lists += '<li>'+result[i]+'</li>\\n';
        }

        var targetNode = document.getElementById(targetId);
        targetNode.innerHTML = lists;
}
</script>
<h2>アクセスログ検索</h2>
<p><input id="search" type="text" size="80" value="" onkeyup="search(this.value)" /></p>
<ul id="result"></ul>
EOD
	
	return $print;
}

1;
