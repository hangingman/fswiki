###############################################################################
#
# パラメータを常にUTF-8変換するCGIクラス
#
###############################################################################
package CGI2;
use CGI::PSGI;
use Plack::Session;
our @ISA;
use strict;
@ISA = qw(CGI::PSGI);

#==============================================================================
# コンストラクタ
#==============================================================================
sub new {
	my $self = shift;
	my $env  = shift;
	$env->{PATH_INFO} =~ s/^$env->{SCRIPT_NAME}//;
	return bless CGI::PSGI->new($env);
}

#==============================================================================
# スクリプトからの追加パス情報を返します
#==============================================================================
sub path_info {
	my $self = shift;
	return $self->env->{PATH_INFO};
}

#==============================================================================
# タイムアウトしているセッションを破棄します
#==============================================================================
sub remove_session {
	my $self = shift;
	my Wiki $wiki = shift;

	my $dir   = $wiki->config('session_dir');
	my $limit = $wiki->config('session_limit');

	opendir(SESSION_DIR,$dir) or die "$!: $dir";
	my $timeout = time() - (60 * $limit);
	while(my $entry = readdir(SESSION_DIR)){
		if($entry =~ /^cgisess_/){
			my @status = stat("$dir/$entry");
			if($status[9] < $timeout){
				unlink("$dir/$entry");
			}
		}
	}
	closedir(SESSION_DIR);
}

#==============================================================================
# CGI::Sessionオブジェクトを取得
#==============================================================================
sub get_session {
	my $self  = shift;
	my $wiki  = shift;
	my $start = shift;

	# セッション開始フラグが立っておらず、CookieにセッションIDが
	# 存在しない場合はセッションを生成しない
	if(!defined($self->{session_cache})){
		if((not defined $start or $start!=1) && $self->cookie(-name=>'CGISESSID') eq ""){
			return undef;
		}
		# session管理はPlack::Middleware::Sessionにまかせるため、app.psgiに移動しました
		my $session = Plack::Session->new($self->env);
		$self->{session_cache} = $session;
		return $session;
	} else {
		return $self->{session_cache};
	}
}

#==============================================================================
# パラメータを取得または設定
#==============================================================================
sub param {
	my $self  = shift;
	my $name  = shift;
	my $value = shift;

	# 必ずUTF-8への変換を行う
	if(Util::handyphone()){
		if(defined($name)) {
			my @values = $self->CGI::param($name,$value);
			my @array = ();
			foreach my $value (@values){
				&Jcode::convert(\$value,"utf8");
				push(@array,$value);
			}
			if($#array==0){
				return $array[0];
			} elsif($#array!=-1){
				return @array;
			} else {
				return undef;
			}
		} else {
			return map { &Jcode::convert(\$_, "utf8") } $self->CGI::param();
		}
	} else {
		if(defined($name)) {
			return scalar $self->CGI::param($name, $value);
		} else {
			return $self->CGI::param();
		}
	}
}

#==============================================================================
# 現在のページに遷移するためのURLを取得します。
#==============================================================================
sub get_url {
	my $self  = shift;
	my $url   = $self->url();
	my $query = "";
	foreach my $param ($self->param()){
		if($query eq ""){
			$query = "?";
		} else {
			$query .= "&";
		}
		$query .= &Util::url_encode($param);
		$query .= "=";
		$query .= &Util::url_encode($self->param($param));
	}
	return $url.$query;
}

#==============================================================================
# 終了時に呼び出されます。
#==============================================================================
sub finalize {
	my $self = shift;
	undef($self->{session_cache}->{_SESSION_OBJ});
	undef($self->{session_cache});
}

1;
