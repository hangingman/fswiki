function LogSearch (arg) {

	// private fields
	var log_file = arg['logFile'];
	var list      = false;
	var cache     = new Array(); // strings already searched

	// public method
	this.search = search;

	_initialize();

	function search(str) {
		if (str == '')  return '';
		if (cache[str]) return cache[str];

		var result = new Array();
		var regexp = new RegExp(_quoteMetaChar(str), 'i');

		for (var i = 0; i < list.length; i++) {
			var cols = list[i].split('\s');

			if (regexp.exec(cols[0])) {
				result.push(list[i]);
			}
		}

		cache[str] = result;
		return result;
	}

	function _quoteMetaChar(str) {
		return str.replace(/(\W)/, '\\$1');
	}

	function _initialize() {
		var xmlHttpRequest = _createXmlHttpObject();

		xmlHttpRequest.open('GET', log_file, true);
		xmlHttpRequest.onreadystatechange = function() {
			if (xmlHttpRequest.readyState == 4) {
				var text = xmlHttpRequest.responseText;
				list = text.split("\n");
			}
		}

		xmlHttpRequest.send(null);
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
}
