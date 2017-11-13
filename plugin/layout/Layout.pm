############################################################
# 
# <p>任意のテンプレートを利用しWikiソースのパース結果を適用するプラグインを提供します。</p>
# 
# <h3>利用方法</h3>
# <pre>
# {{layout テンプレート名[,変数:値,...]
# 〜Wiki書式のソース〜
# }}
# </pre>
# 
# <h3>パラメータで利用可能な変数</h3>
# <p>
# パラメータで利用する変数の定義はテンプレート内に規定のフォーマットで記述します。
# 詳しくは SAMPLE.tmpl を参照してください。
# </p>
# <p>
# パラメータ名で <b>outline</b> という名称は予約されています。
# <b>outline</b> を指定すると process_outline を使用して Wikiソースを変換します。
# この場合、outline プラグインへ見出しが反映されるようになりますが、パート編集の位置がずれることがあります。
# </p>
# <p>
# この outline パラメータは <u>setup.dat</u> もしくは <u>config/config.dat</u> ファイル内で、以下の設定を行うことで既定の動作となります。
#= <pre>layout_process_outline=1</pre>
# <p>
# 
# <h3>テンプレートで利用可能な内部変数一覧</h3>
# <pre>
# SOURCE            : Wikiソース変換結果（HTMLソース）
# LOGIN             : ログイン済みの場合は 1
# LOGIN_ID          : ログイン・ユーザーID
# LOGIN_TYPE        : ログイン種別（0:管理者, 1:一般）
# IS_HANDYPHONE     : 携帯アクセスの場合は 1
# IS_FIRST_TMPL     : 同一テンプレート利用で１回目の呼び出し時に 1
# IS_FIRST_LAYOUT   : Layoutプラグインの１回目の呼び出し時に 1
# COUNT_TMPL        : 同一テンプレートの呼び出し回数（ID属性のカウンターなどに利用）
# COUNT_LAYOUT      : Layoutプラグインの呼び出し回数（ID属性のカウンターなどに利用）
# CURRENT_TIMESTAMP : 現在時刻（Util::format_date()形式）
# SCRIPT_NAME       : スクリプト・パス
# CURRENT_PAGE      : 表示中のページ名
# CURRENT_PAGE#url  : 表示中のページ名をURLエンコードした文字列(2013/03/07機能追加)
# FSWIKI_HOME       : FSWIKI ホームのURI
# FSWIKI_HOME_DIR   : FSWIKI ホームディレクトリへのパス（例：ルートWikiの場合は'.'、子Wikiの場合は './..' となる）
# SITE_THEME_URI    : テーマディレクトリへのURI
# SITE_THEME_NAME   : テーマ名
# SITE_TMPL_NAME    : テンプレート名
# PATH_INFO         : CGIの PATH_INFO 環境変数値
# WIKI_ACTION       : CGIパラメータのactionで指定された名称（アクションなしの場合はブランク）
# WIKI_ACTION_...   : ...で指定したアクションがCGIパラメータで指定されているかどうか（1:パラメータあり）
# EXIST_PAGE_...    : ...で指定した / を含まないページ名が存在するかどうか（1:存在する）
# CGI_PARAM_...     : ...で指定したCGIパラメータの設定値（無ければFALSEになる）?page=xxxx の場合は CGI_PARAM_page に xxx が設定される
# CGI_PARAMS_...    : ...で指定した配列要素のCGIパラメータの設定値 ?abc=xxx&abc=yyy の場合は CGI_PARAMS_abc に CGI_PARAM_abc として各値が設定される
# </pre>
# 
# <p>
# 上記の他、テンプレートファイルに指定した PARAMETER で定義された変数が使用できます。
# また、PARAMETER で定義された変数の「変数名+'#url'」 でURLエンコードされた値を取得できます。
# </p>
# 
# <h3>任意のテンプレートの内容をそのまま出力するには・・・</h3>
# <p><small>このプラグイン利用時は Wiki ソースの指定はできません。テンプレートで利用可能な内部変数は利用できます。</small></p>
# <pre>
# // インライン版
# {{ilayout テンプレート名[,変数:値,...]}}
# </pre>
# 
# <h3>FSWIKI用の追加テンプレート記述</h3>
# <dl>
# <dt>FSWIKI_SOURCE 〜 /FSWIKI_SOURCE</dt>
# <dd>テンプレート内に指定したWiki書式を変換する</dd>
# </dl>
# <pre>
# // 記述例
# &lt;!--FSWIKI_SOURCE--&gt;
# !!!見出し
# [[Menu]]
# &lt;!--/FSWIKI_SOURCE--&gt;
# </pre>
# 
# <dl>
# <dt>FSWIKI_INCLUDE</dt>
# <dd>テンプレート内に指定したWikiページを挿入する</dd>
# </dl>
# <pre>
# // 記述例
# &lt;!--FSWIKI_INCLUDE PAGE=Menu--&gt;
# </pre>
# 
# <dl>
# <dt>FSWIKI_HEAD_INFO</dt>
# <dd>テンプレート内の指定した範囲を&lt;HEAD&gt;タグ内に挿入する</dd>
# </dl>
# <pre>
# // 記述例
# // ※ IS_FIRST_TMPL との併用で初回のみ HEAD 内に追加することが出来ます。
# &lt;!--TMPL_IF "IS_FIRST_TMPL"--&gt;
# &lt;!--FSWIKI_HEAD_INFO--&gt;
# &lt;script type="text/javascript"&gt;
# function sample_script() {
#   alert('sample!');
# }
# &lt;/script&gt;
# &lt;!--/FSWIKI_HEAD_INFO--&gt;
# &lt;!--/TMPL_IF--&gt;
# </pre>
# 
############################################################
package plugin::layout::Layout;
use plugin::layout::LayoutUtil;
use Util;
use strict;
#===========================================================
# コンストラクタ
#===========================================================
sub new {
	my $class = shift;
	my $self = {};
	
	$self->{'exist_page'} = undef;
	
	# 設定ファイル
	$self->{config_file} = 'layoutkey.dat';
	
	return bless $self,$class;
}

#==============================================================================
# インライン関数
#==============================================================================
sub inline {
	my $self   = shift;
	my $wiki   = shift;
	my $tmpl   = shift;
	my @attr   = @_;
	
	return $self->block($wiki,undef,$tmpl,@attr);
}

#===========================================================
# ブロックプラグイン
#===========================================================
sub block {
	my $self   = shift;
	my $wiki   = shift;
	my $source = shift;
	my $tmpl   = shift;
	my @attr   = @_;
	my $cgi    = $wiki->get_CGI();
	my $outline = 0;
	
	# Wikiソース変換のデフォルト設定値の取得
	if ( defined($wiki->config('layout_process_outline')) ) {
		$outline = $wiki->config('layout_process_outline');
	}
	
	# テンプレート・パラメータ用
	my %param = {};
	
	# テンプレート名のチェック
	if ( $tmpl =~ /[\/\\]?\.\.[\/\\]/ ) {
		return $wiki->error("テンプレート名が正しくありません。");
	}
	
	# テンプレート情報の取得
	my $tmplinfo = &plugin::layout::LayoutUtil::get_tmpl_info($wiki, $tmpl);
	if ( !defined($tmplinfo) ) {
		return $wiki->error("テンプレート(".$tmpl.")が見つかりません。");
	}
	
	# 規定のパラメータの取り出し
	my $num = 0;
	foreach (@attr) {
		$num++;
		my ($a, $b) = undef;
		if ( defined($tmplinfo->{PARAMETER}->{'$'.$num}->{validation}) ) {
			$a = '$'.$num;
			$b = $_;
		} else {
			if ( /^([^:]+)(\:(.*))?/ ) {
				$a = $1; $b = $3;
			}
		}
		if ( $a eq "outline" ) {
			$outline = 1;
		} elsif ( $tmplinfo->{PARAMETER}->{$a}->{type} eq 'WIKI' ) {
			$param{$a} = $wiki->process_wiki($b);
			$param{$a} =~ s/^<p>(.*)<\/p>$/$1/;
		} elsif ( !defined($tmplinfo->{PARAMETER}->{$a}->{validation}) ) {
			return $wiki->error("(".$a.")不明なキー設定です。");
		} elsif ( !defined($b) ) {
			if ( $tmplinfo->{PARAMETER}->{$a}->{validation} eq "" ) {
				$param{$a} = 1;
			} else {
				return $wiki->error("(".$a.")キーの値が正しくありません。");
			}
		} elsif ( $b =~ /$tmplinfo->{PARAMETER}->{$a}->{validation}/ ) {
			$param{$a} = $b;
			$param{$a.'#url'} = &Util::url_encode($b);	#エンコード値
		} else {
			return $wiki->error("(".$a.")キーの値が正しくありません。");
		}
	}
	
	my $buf = "";
	my $html = "";
	
	# SOURCE 種別
	if (!$tmplinfo->{SOURCE} || $tmplinfo->{SOURCE} eq "WIKI") {
		# Wikiソース変換
		if (defined($source)) {	# ilayout からの呼出では $source が入ってこないので処理しない
			if ( $outline == 0 ) {
				$html = $wiki->process_wiki($source);
			} else {
				$html = $wiki->process_outline($source);	# アウトライン反映
			}
		}
	} else {
		# 変換なし（注意：テンプレートで必ず <!--TMPL_VAR 'xxxx' ESCAPE=HTML--> というようにESCAPE属性を付けること）
		$html = $source;
	}
	my $login_info = $wiki->get_login_info();	# ログイン情報
	my $is_handyphone = &Util::handyphone();	# 携帯チェック
	
	my $fswiki_home = $cgi->script_name();
	$fswiki_home =~ s/\/[^\/]+$//;
	my $fswiki_home_dir = $cgi->path_info();
	$fswiki_home_dir =~ s/[^\/]+/\.\./g;
	$fswiki_home_dir = ".".$fswiki_home_dir;
	
	# テンプレートを使用してフォーマット取得
	my $layouttmpl = HTML::Template->new(
	                    filename=>$tmplinfo->{TEMPLATE},
	                    die_on_bad_params => 0,
	                    loop_context_vars => 1,
	                    global_vars => 1);
	
	$self->{tmpl}->{$tmpl} = 0 if (!defined($self->{tmpl}->{$tmpl}));
	$self->{layout} = 0 if (!defined($self->{layout}));
	
	%param = (%param
	         ,SOURCE            => $html
	         ,LOGIN             => (defined($login_info))?1:0
	         ,LOGIN_ID          => (defined($login_info))?$login_info->{id}:0
	         ,LOGIN_TYPE        => (defined($login_info))?$login_info->{type}:0
	         ,IS_HANDYPHONE     => $is_handyphone
	         ,IS_FIRST_TMPL     => ($self->{tmpl}->{$tmpl})?0:1
	         ,IS_FIRST_LAYOUT   => ($self->{layout})?0:1
	         ,COUNT_TMPL        => ($self->{tmpl}->{$tmpl}+1)
	         ,COUNT_LAYOUT      => ($self->{layout}+1)
	         ,CURRENT_TIMESTAMP => &Util::format_date(time())
	         ,SCRIPT_NAME       => $wiki->config('script_name')
	         ,CURRENT_PAGE      => (defined($cgi->param('page')))?$cgi->param('page'):''
	         ,'CURRENT_PAGE#url' => &Util::url_encode((defined($cgi->param('page')))?$cgi->param('page'):'')
	         ,FSWIKI_HOME       => $fswiki_home
	         ,FSWIKI_HOME_DIR   => $fswiki_home_dir
	         ,SITE_THEME_URI    => $wiki->config('theme_uri')
	         ,SITE_THEME_NAME   => $wiki->config('theme')
	         ,SITE_TMPL_NAME    => $wiki->config('site_tmpl_theme')
	         ,PATH_INFO         => $cgi->path_info()
	         );
	
	$layouttmpl->param(%param);
	
	# 設定キー情報
	my $layoutkey = &Util::load_config_hash($wiki,$self->{config_file});
	foreach my $key (sort(keys(%$layoutkey))) {
		$layouttmpl->param($key => $layoutkey->{$key});
	}
	
	# CGI->param の設定値
	foreach my $key ($cgi->all_parameters()) {
#		$layouttmpl->param('CGI_PARAM_'.$key => $cgi->param($key));
		my @values = $cgi->param($key);
		if ($#values > 0) {
			@values = map { {'CGI_PARAM_'.$key => $_} } @values;
			$layouttmpl->param('CGI_PARAMS_'.$key => \@values);
		} else {
			$layouttmpl->param('CGI_PARAM_'.$key => $values[0]);
		}
	}
	
	# アクション
	$layouttmpl->param('WIKI_ACTION' => $cgi->param('action'));
	if (defined($cgi->param('action'))) {
		$layouttmpl->param('WIKI_ACTION_'.$cgi->param('action') => 1);
	}
	
	# ページ名をEXIST_PAGE_ページ名というパラメータにセット
	# ただし、スラッシュを含むページ名はセットしない
	if ( !defined($self->{'exist_page'}) ) {
		my @pagelist = $wiki->get_page_list();
		# 検索結果をキャッシュする
		foreach my $page (@pagelist){
			push(@{$self->{'exist_page'}}, $page);
		}
	}
	
	# EXIST_PAGE_xxxx の設定
	&plugin::layout::LayoutUtil::set_template_exist_page($wiki, $layouttmpl);
=pod
	foreach my $page (@{$self->{'exist_page'}}){
		if(index($page,"/")==-1 && $wiki->can_show($page)){
			$layouttmpl->param("EXIST_PAGE_".$page=>1);
		}
	}
=cut
	
	$buf = $layouttmpl->output();
	
	# FSWIKI テンプレート書式の処理
	$buf = &plugin::layout::LayoutUtil::process_template($wiki, $buf);
=pod
	# インクルード命令
	# <!--FSWIKI_INCLUDE PAGE="ページ名"-->
	# ページ名でWikiNameを指定する。
	my $fswiki_include_tag = '<!--\s*FSWIKI_INCLUDE\s+PAGE\s*=\s*"([^"]*)"\s*-->';
	while($buf =~ /$fswiki_include_tag/o){
		if($wiki->page_exists($1) && $wiki->can_show($1)){
			# キャッシュモードONの場合
			if($wiki->use_cache($1)){
				my $cache = $wiki->get_page_cache($1,0);
				if($cache ne ""){
					$buf =~ s/$fswiki_include_tag/$cache/oe;
				} else {
					$wiki->update_page_cache($1);
					$cache = $wiki->get_page_cache($1,0);
					$buf =~ s/$fswiki_include_tag/$cache/oe;
				}
			# キャッシュモードOFFの場合
			} else {
				$buf =~ s/$fswiki_include_tag/$wiki->process_wiki($wiki->get_page($1))/oe;
			}
		} else {
			$buf =~ s/$fswiki_include_tag//o;
		}
	}
=cut
	
	$self->{tmpl}->{$tmpl} += 1;
	$self->{layout} += 1;
	
	return $buf;
}

1;
