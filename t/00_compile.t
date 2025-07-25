use strict;
use warnings;
use Test::More;

# テスト実行時にlibとpluginディレクトリを検索パスに追加
use lib 'lib';
use lib 'plugin';

# メインのアプリケーションモジュールが読み込めるかテスト
use_ok('WikiApplication');

done_testing();