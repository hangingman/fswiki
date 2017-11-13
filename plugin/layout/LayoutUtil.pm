############################################################
# 
# <p>Layoutプラグインのテンプレートからテンプレート情報を取得します。</p>
# 
############################################################
package plugin::layout::LayoutUtil;
use Util;
use strict;

#===========================================================
# テンプレート一覧を取得する関数
#===========================================================
sub get_tmpl_list {
	my $wiki = shift;
	
	my @list;
	opendir(DIR,$wiki->config('tmpl_dir')."/layout") or die $!;
	while(my $entry = readdir(DIR)){
		my $path = $wiki->config('tmpl_dir')."/layout/$entry";
		if(-f $path && $entry =~ /^(.*)\.tmpl$/ ){
			push(@list,$1);
		}
	}
	closedir(DIR);
	
	@list = sort(@list);
	return @list;
}

#===========================================================
# テンプレート・ファイルの解析
# テンプレートに規定のフォーマットで記述された情報を読み込みます
#===========================================================
sub get_tmpl_info {
	my $wiki = shift;
	my $tmpl = shift;
	
	my $tmplinfo = undef;
	my $tmplsrc  = undef;
	
	# テンプレート名チェック
	return undef if ($tmpl =~ /\.\./);
	# テンプレート存在チェック
	$tmplinfo->{TEMPLATE} = $wiki->config('tmpl_dir')."/layout/".$tmpl.".tmpl";
	return undef if ( ! -f $tmplinfo->{TEMPLATE} );
	
	open(TEMPLATE, $tmplinfo->{TEMPLATE});
	while (read(TEMPLATE, $tmplsrc, 10240, length($tmplsrc))) {};
	close(TEMPLATE);
	
	my ($layout,$help) = 0;
	foreach (split("\n",$tmplsrc)) {
		if ( /^-- LAYOUTINFO_START/ ) {
			$layout = 1;
		} elsif ( /^-- LAYOUTINFO_END/ ) {
			last;
		} else {
			next if (! $layout);
			if ( /^-- \b(TITLE)\b[\s\t]*:[\s\t]*(.+)/ ) {
				## STRING: タイトル
				$tmplinfo->{$1} = $2;
			} elsif ( /^-- \b(PARAMETER)\b[\s\t]*:[\s\t]*([\$]?\w+)[\s\t]*,[\s\t]*(WIKI|\/(.*)\/)/ ) {
				## HASH  : 利用可能なパラメータ＆入力規則
				$tmplinfo->{$1}->{$2}->{type} = 'TEXT';
				$tmplinfo->{$1}->{$2}->{type} = $3 if (defined($3));
				$tmplinfo->{$1}->{$2}->{validation} = $4;
				push(@{$tmplinfo->{PARAMETERLIST}}, $2);
			} elsif ( /^-- \b(SOURCE)\b[\s\t]*:[\s\t]*(WIKI|TEXT)[\s\t]*/ ) {
				$tmplinfo->{$1} = $2 || 'WIKI';
			} elsif ( /^-- HELP_START(:(WIKI|HTML))?/ ) {
				$help = 1;
				if ( defined($2) ) {
					$tmplinfo->{HELP_STYLE} = $2;
				} else {
					$tmplinfo->{HELP_STYLE} = "WIKI";
				}
			} elsif ( /^-- HELP_END/ ) {
				$help = 0;
				next;
			} else {
				if ( $help ) {
					## STRING: 利用方法
					$tmplinfo->{HELP} .= $_."\n";
				}
			}
		}
	}
	
	return $tmplinfo;
}

#==============================================================================
# <p>
# パラメータで渡された テンプレート・ソース 内のWikiキーワードを処理します。
# </p>
# パラメータ内の以下の記述部のWikiソースを変換して挿入します。
# <pre>
#   <!--FSWIKI_SOURCE-->Wikiソース<!--/FSWIKI_SOURCE-->
# </pre>
# パラメータ内の以下の記述部のWikiページを変換して挿入します。
# <pre>
#   <!--FSWIKI_INCLUDE PAGE='<Wikiページ>'-->
# </pre>
#==============================================================================
sub process_template {
	my $wiki = shift;
	my $source = shift;
	
	my @lines = split(/\n/,$source);
	my $html = "";
	
	while ($source =~ /<!--\s*(FSWIKI_SOURCE|FSWIKI_INCLUDE|FSWIKI_HEAD_INFO)(\s+(PAGE=)?["']([\w\-\.]*)['"])?\s*-->/i) {
		$html .= $`;
		my $a = $';
		if (uc($1) eq 'FSWIKI_SOURCE') {
			if ( $a =~ /<!--\s*\/FSWIKI_SOURCE\s*-->/i ) {
				$html .= $wiki->process_wiki($`);
				$a = $';
			}
		} elsif (uc($1) eq 'FSWIKI_INCLUDE') {
			if ($wiki->page_exists($4) && $wiki->can_show($4)) {
#				$html .= $wiki->process_wiki("{{include $4}}");
				$html .= $wiki->process_wiki($wiki->get_page($4));
			}
		} elsif (uc($1) eq 'FSWIKI_HEAD_INFO') {
			if ( $a =~ /<!--\s*\/FSWIKI_HEAD_INFO\s*-->/i ) {
				$wiki->add_head_info($`);
				$a = $';
			}
		}
		$source = $a;
	}
	$html .= $source;
	return $html;
}

#==============================================================================
# <p>
# パラメータで渡された テンプレート・ソース 内のページ存在チェック部を処理します。
# </p>
# ページ存在チェックに利用する以下の 'EXIST_PAGE_<ページ名>' に該当するページ存在チェック値を取得します。
# <pre>
#   <!--TMPL_IF NAME='EXIST_PAGE_<ページ名>'-->
# </pre>
#==============================================================================
sub set_template_exist_page {
	my $wiki = shift;
	my $tmpl = shift;
	
	my $tmplpath = $tmpl->{options}->{filepath};
	my $tmplsrc = $tmpl->{template};
	
	open(TEMPLATE, $tmplpath);
	while (read(TEMPLATE, $tmplsrc, 10240, length($tmplsrc))) {}
	close(TEMPLATE);
	
	while ( $tmplsrc =~ /<!--\s*[Tt][Mm][Pp][Ll]_[Ii][Ff]\s+(NAME=)?["']?EXIST_PAGE_([\w\/\-\.]+)['"]?\s*-->/ ) {
		if(index($2,"/")==-1 && $wiki->can_show($2)){
			$tmpl->param("EXIST_PAGE_".$2=>1);
		}
		$tmplsrc = $';
	}
}

1;
