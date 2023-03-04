package plugin::amazon::Amazon;
use strict;
use warnings;
###############################################################################
#
# <p>指定した書籍の書影をgoogle bookから取得して表示し、amazonの書評ページへリンクをはります。</p>
# <pre>
#   {{amazon asin[,comment]}}
# </pre>
# <p>
#   setup.dat に amazon_aid という定数を設定すると amazon のアソシエトID つきでリンクがはられます。
# </p>
# <p>
#   イメージが存在しないかどうか確認するためにamazonのサーバに接続しているので、
#   プロキシ経由で外に出る必要がある場合は、プロキシの設定情報をsetup.datに設定しておく必要があります。
# </p>
# <p>
#   comment 引数があたえられると、書影画像のかわりにその文字列からリンクをはります。
# </p>
#
###############################################################################
use LWP::UserAgent;
use JSON;
use MIME::Base64;

#use HTTP::Response;
#use HTTP::Request;

#==============================================================================
# コンストラクタ
#==============================================================================
sub new {
	my $class = shift;
	my $self = {};
	return bless $self,$class;
}
#==============================================================================
# インラインメソッド
#==============================================================================
sub inline {
	my $self    = shift;
	my $wiki    = shift;
	my $asin    = shift;
	my $comment = shift;

	$asin = Util::escapeHTML($asin);
	my $buf;
	my $aid = $wiki->config('amazon_aid');
	my $link = 'http://www.amazon.co.jp/exec/obidos/ASIN/' .  $asin;
	$link .= '/' . $aid . '/ref=nosim' if $aid;

	if($comment eq ""){
		my $image_url = get_image_url($wiki, $asin);
		my $image = get_image_as_base64($wiki, $image_url);
		$buf = qq(<img src="data:image/jpeg;base64,$image">);
	} else{
		$buf = Util::escapeHTML($comment);
	}
	return '<span class="amazonb"><a href="'.$link.'">'.$buf.'</a></span>';
}

sub get_image_as_base64 {
	my $wiki = shift;
	my $image_url = shift;

	my $noimg = 'http://images-jp.amazon.com/images/G/09/icons/books/comingsoon_books.gif';

	my $image = &Util::get_response($wiki, $image_url);
	$image = $noimg if (length($image) < 1024);

	return encode_base64($image);
}

sub get_image_url {
	my $wiki = shift;
	my $asin = shift;

	# Google Books APIのエンドポイントURL
	my $url = qq(https://www.googleapis.com/books/v1/volumes?q=isbn:$asin);
	my $json = &Util::get_response($wiki, $url);

	# レスポンスのJSONデータをパースする
	my $data = decode_json($json);

	# 画像のURLを取得する
	my $image_url = $data->{items}[0]{volumeInfo}{imageLinks}{thumbnail};
	return $image_url;
}

1;
