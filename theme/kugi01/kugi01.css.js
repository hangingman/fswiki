/**
 * kugi01 - FreeStyleWiki Theme
 * @version 1.0.0 - 2018/07/20
 * @copyright (c) 2018 KG
 * @license GNU General Public License - https://www.gnu.org/licenses/gpl-1.0.txt
 */
var theme_name;
var theme_config_uri;
var ie_ver = 0;
var isIOS = /iP(hone|(o|a)d)/.test(navigator.userAgent);
(function(){
	//IEVer
	if (window.navigator.userAgent.toLowerCase().match(/msie [0-9\.]+;/)) {
		ie_ver = parseInt(window.navigator.userAgent.toLowerCase().replace(/^.+msie ([0-9]+)\.[0-9];.+/, "$1"), 10);
	}
	//iOS
	
	theme_config_uri = (function() {
		if (document.currentScript) {
			return document.currentScript.src;
		} else {
			var scripts = document.getElementsByTagName('script'),
			script = scripts[scripts.length-1];
			if (script.src) {
				return script.src;
			}
		}
	})();
	theme_name = theme_config_uri.replace(/.*\/([^\.]+)\.css\.js.*/,'$1');
	theme_config_uri = theme_config_uri.replace(/[^\/\\]+$/, "");
	//--------------------------------------------------
	//スクリプト読み込み(IE-legacy)
	//--------------------------------------------------
	if (ie_ver && ie_ver < 9) {
		document.write('<script type="text/javascript" src="http://html5shiv.googlecode.com/svn/trunk/html5.js"></script>');
		document.write('<script type="text/javascript" src="http://css3-mediaqueries-js.googlecode.com/svn/trunk/css3-mediaqueries.js"></script>');
	}
	//--------------------------------------------------
	//スタイル読み込み
	//--------------------------------------------------
	document.write('<link rel="stylesheet" type="text/css" href="' + theme_config_uri + theme_name + '.css">');
	//IE9未満対応
	if (ie_ver && ie_ver < 9) {
		document.write('<link rel="stylesheet" type="text/css" href="' + theme_config_uri + 'ie-legacy.css">');
		document.write(
			  '<style>'
			+ '#header-container { behavior: url(./theme/resources/legacy/PIE.htc); }'
			+ '#header-container div.dropdown-menu > a:after { behavior: url(./theme/resources/legacy/PIE.htc); }'
			+ '.main > .header > .outline {'
				+ '-ms-transform-origin: 120px 18px; -ms-transform: rotate(-90deg); -ms-opacity: 0.7;'
				+ 'right: -100px; filter: progid:DXImageTransform.Microsoft.BasicImage(rotation=3); '
				+ 'behavior: url(./theme/resources/legacy/PIE.htc);'
			+ '}'
			+ '.main > .header > .outline:hover, .main > .header > .outline:focus {'
				+ '-ms-transform: rotate(0deg); -ms-opacity: 0.9; -ms-box-shadow: 0 0 10px rgba(0,0,0,0.2);'
				+ 'right: 0px; filter: none;'
				+ 'behavior: url(./theme/resources/legacy/PIE.htc);'
			+ '}'
			+ '</style>'
		);
	}
	//--------------------------------------------------
	//スクリプト読み込み
	//--------------------------------------------------
	document.write('<script type="text/javascript" src="' + theme_config_uri + 'jquery-1.12.4.min.js"></script>');
	//--------------------------------------------------
	//その他
	//--------------------------------------------------
	document.write('<script type="text/javascript">$(window).ready(onready);</script>');
})();

//--------------------------------------------------
//初期処理
//--------------------------------------------------
function onready(){
	//--------------------------------------------------
	//iPhone: hover対応
	//--------------------------------------------------
	$(window).on('touchstart', function(){});
	//--------------------------------------------------
	//Resize時のメニュー縦サイズ再設定
	//--------------------------------------------------
	$('.sidebar').height(document.documentElement.clientHeight - $('#header-container').height());
	$(window).on('resize', function(){
		$('.sidebar').css('left', '');
		$('.sidebar').height((isIOS ? window.innerHeight : document.documentElement.clientHeight) - $('#header-container').height());
		$('.sidebar-icon').removeClass('hover').trigger('blur');
	});
	//--------------------------------------------------
	//文字拡大縮小設定(cookie)の読込と適用
	//--------------------------------------------------
	var cookies = document.cookie.split('; ');
	for (var i=0; i<cookies.length; i++) {
		var kv = cookies[i].split('=');
		var key = kv.shift(), val = kv.join('=');
		if (key === 'fswiki_zoom') {
			setZoom(val);
			break;
		}
	}
	//--------------------------------------------------
	//{{outline}}: トップメニュー化
	//--------------------------------------------------
	var $outline = $('.main .header .outline');
	if ($outline.length > 0) {
		$('.dropdown-menu-outline').show();
		var $area = $('.dropdown-menu-outline > .dropdown-menu-area');
		$area.append($outline[0]);
		$area.css({'display':'block', 'position':'absolute', 'left':'0', 'width':window.innerWidth+'px'});
		var w = $outline.css('display', 'inline-block').width();
		$area.css({'display':'', 'position':'', 'left':'', 'width':''});
		$outline.width(w);
	}
	//--------------------------------------------------
	//ドロップダウンメニュー表示位置調整
	//--------------------------------------------------
	$('.dropdown-menu').on('mouseover touchstart', function(){
		var $ddmenu = $(this);
		var $ddarea = $(this).find('.dropdown-menu-area');
		if ($ddarea.length > 0) {
			var hdrW = $('#header-container').width(),
				ddmL = $ddmenu.offset().left,
				ddaW = $ddarea.outerWidth(),
				scrX = window.scrollX ? window.scrollX : window.pageXOffset;
			//dropdown-menu内容が画面を超える場合の位置調整
			if (ddmL + ddaW - scrX > hdrW) {
				$ddarea.css({'left': '', 'right': '0px'});//(scrX + hdrW) - (ddmL - ddaW)) + 'px');
			} else {
				$ddarea.css({'left': ''});
			}
		}
	});
	//--------------------------------------------------
	//サイドバー: 表示非表示
	//--------------------------------------------------
	var $sidebar = $('.sidebar');
	$('.sidebar-icon').on('click', function(){
		if ($sidebar.position().left < 0) {
			$sidebar.animate({'left':'0px'}, 100);
			$(this).addClass('hover');
			$sidebar.focus();
		} else {
			$sidebar.animate({'left':-($sidebar.width()+10)+'px'}, 100);
			$(this).removeClass('hover');
			$(window).focus();
		}
	});
	//--------------------------------------------------
	//{{bugtrack}}: テーブルnowrap設定
	//--------------------------------------------------
	if ($('form > table > tbody > tr > th').text() == '投稿者サマリカテゴリ優先度状態内容') {
		$('form > table > tbody > tr > th').css('white-space','nowrap');
	}
	//--------------------------------------------------
	//{{bugtrack-list}}: テーブルnowrap設定, BugTrack文字削除
	//--------------------------------------------------
	$(':not(form) > table > tbody > tr:first').each(function(){
		if(this.innerText=="\nカテゴリ\t優先度\t状態\t投稿者\tサマリ"){
			$(this).parent().find('tr').each(function(){
				var $td = $(this).find('td:first,th:first');
				$td.children().text($td.children().text().replace(/BugTrack\-/,''));
				$td.css('white-space','nowrap');		//ID
			});
		};
	});
	//--------------------------------------------------
	//アイコン設定
	//--------------------------------------------------
	$('img.theme_ic').each(function(){
		var icon = this.getAttribute('data-value');
		this.setAttribute('src', theme_config_uri + icon);
	});
};

//--------------------------------------------------
//フォントサイズ変更処理
//--------------------------------------------------
function setZoom(val) {
	if (val < 0 || val > 1) {
		return;
	}
	document.body.style.fontSize= val + 'em';
	$('.sidebar').width(300*val < 150 ? 150 : 300*val < 250 ? 300*val : 250);
	$(window).trigger('resize');
	// 1weeks expires
	document.cookie = [
		'fswiki_zoom=' + val,
		'path=' + '/',
		'domain=' + location.host,
		'expires=' + new Date(new Date().getTime()+7*24*60*60*1000).toUTCString()
	].join('; ');
}
