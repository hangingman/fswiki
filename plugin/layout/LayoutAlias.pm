############################################################
# 
# <p>エイリアス名から実際のプラグインを呼び出します。</p>
# 
# <p>これは、プラグインのエイリアスです</p>
# 
############################################################
package plugin::layout::LayoutAlias;
use Util;
use strict;

#===========================================================
# コンストラクタ
#===========================================================
sub new {
	my $class = shift;
	my $self = {};
	
	# エイリアス名が入ります
	$self->{command} = undef;
	# エイリアス設定ファイル
	$self->{layoutalias} = 'layoutalias.dat';
	# エイリアス情報
	$self->{alias} = {};
	
	return bless $self,$class;
}

#==============================================================================
# インライン関数
#==============================================================================
sub inline {
	my $self = shift;
	my $wiki = shift;
	my @args = @_;
	
	my $a_info = $self->{alias}->{$self->{command}};
	if ( !defined($a_info) ) {
		return $self->error($wiki,$self->{command}."エイリアスは存在しません。");
	}
	my $p_info = $wiki->get_plugin_info($a_info->{COMMAND});
	my $obj = $wiki->get_plugin_instance($p_info->{CLASS});
	
	if ( !defined($obj) ) {
		return $self->error($wiki,$a_info->{COMMAND}."プラグインは存在しません。");
	}
	
	my $result = undef;
	$obj->{command} = $a_info->{COMMAND};
	# パラメータの追加
	my @o_args = ();
	push(@o_args, @{$a_info->{ARGS}});
	push(@o_args, @args);
	# プラグイン呼出
	return $obj->inline($wiki, @o_args);
}

#==============================================================================
# パラグラフ関数
#==============================================================================
sub paragraph {
	my $self = shift;
	my $wiki = shift;
	my @args = @_;
	
	my $a_info = $self->{alias}->{$self->{command}};
	if ( !defined($a_info) ) {
		return $self->error($wiki,$self->{command}."エイリアスは存在しません。");
	}
	my $p_info = $wiki->get_plugin_info($a_info->{COMMAND});
	my $obj = $wiki->get_plugin_instance($p_info->{CLASS});
	
	if ( !defined($obj) ) {
		return $self->error($wiki,$a_info->{COMMAND}."プラグインは存在しません。");
	}
	
	my $result = undef;
	$obj->{command} = $a_info->{COMMAND};
	# パラメータの追加
	my @o_args = ();
	push(@o_args, @{$a_info->{ARGS}});
	push(@o_args, @args);
	# プラグイン呼出
	return $obj->paragraph($wiki,@o_args);
}

#===========================================================
# ブロック関数
#===========================================================
sub block {
	my $self   = shift;
	my $wiki   = shift;
	my $source = shift;
	my @args   = @_;
	
	my $a_info = $self->{alias}->{$self->{command}};
	if ( !defined($a_info) ) {
		return $self->error($wiki,$self->{command}."エイリアスは存在しません。");
	}
	my $p_info = $wiki->get_plugin_info($a_info->{COMMAND});
	my $obj = $wiki->get_plugin_instance($p_info->{CLASS});
	
	if ( !defined($obj) ) {
		return $self->error($wiki,$a_info->{COMMAND}."プラグインは存在しません。");
	}
	
	my $result = undef;
	$obj->{command} = $a_info->{COMMAND};
	# パラメータの追加
	my @o_args = ();
	push(@o_args, @{$a_info->{ARGS}});
	push(@o_args, @args);
	# プラグイン呼出
	return $obj->block($wiki,$source,@o_args);
}

#===========================================================
# エラー用
#===========================================================
sub error {
	my $self = shift;
	my $wiki = shift;
	my $message = shift;
	return "<font class=\"error\">".$message."</font>";
}

#===========================================================
# エイリアス情報の読込フック
#===========================================================
sub hook {
	my $self = shift;
	my $wiki = shift;
	my $name = shift;
	
	if ( $name eq 'initialize' ) {
		$self->initialize($wiki);
	}
	return undef;
}

sub initialize {
	my $self = shift;
	my $wiki = shift;
	
	if ( ! -e $wiki->config('config_dir').'/'.$self->{layoutalias} ) {
		return undef;
	}
	my $info = &Util::load_config_hash($wiki,$self->{layoutalias});
	
	# エイリアス登録
	foreach my $alias (keys(%$info)) {
		my ($command, $parameter) = split(/\t/,$info->{$alias});
		my $plugin = $wiki->get_plugin_info($command);
		my @args = map {/^"(.*)"$/ ? scalar($_ = $1, s/\"\"/\"/g, $_) : $_}
		              ($parameter =~ /,?\s*(\"[^\"]*(?:\"\"[^\"]*)*\"|[^,]+)/g);
		
		my $info = {COMMAND=>$command, CLASS=>$plugin->{CLASS}, TYPE=>$plugin->{TYPE}, FORMAT=>$plugin->{FORMAT}, ARGS=>\@args};
		$self->{alias}->{$alias} = $info;
		
		if ( $plugin->{TYPE} eq 'inline' ) {
			# インライン・プラグイン
			$wiki->add_inline_plugin($alias, __PACKAGE__, $plugin->{FORMAT});
		} elsif ( $info->{$alias}->{TYPE} eq 'paragraph' ) {
			# パラグラフ・プラグイン
			$wiki->add_paragraph_plugin($alias, __PACKAGE__, $plugin->{FORMAT});
		} else {
			# ブロック・プラグイン
			$wiki->add_block_plugin($alias, __PACKAGE__, $plugin->{FORMAT});
		}
	}
	return undef;
}

1;
