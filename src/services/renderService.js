"use strict";
// src/services/renderService.ts
Object.defineProperty(exports, "__esModule", { value: true });
exports.parseWikiText = parseWikiText;
/**
 * Wiki記法テキストを解析し、構造化された中間表現またはイベントストリームを生成するサービス。
 * Wiki::Parser.pmのロジックをTypeScriptで再現する。
 */
/**
 * Wiki記法テキストをパースする。
 * @param source - パース対象のWiki記法テキスト
 */
function parseWikiText(source) {
    console.log("Parsing wiki text...");
    // TODO: Wiki::Parser.pmのparseメソッドのロジックをここに実装
    // 行ごとに処理し、ブロック要素やインライン要素を識別する
    var lines = source.replace(/\r/g, "").split("\n");
    startParse(); // パース開始フック
    var block = null; // ブロックプラグインの状態管理
    for (var _i = 0, lines_1 = lines; _i < lines_1.length; _i++) {
        var line = lines_1[_i];
        // 複数行の説明処理 (各行の先頭でチェック)
        multiExplanation(line);
        var word1 = line.substring(0, 1);
        var word2 = line.substring(0, 2);
        var word3 = line.substring(0, 3);
        // 空行
        if (line === "" && !block) {
            lParagraph();
            continue;
        }
        // ブロック書式のエスケープ
        if (word2 === "\\\\" || word1 === "\\") {
            var obj = parseLine(line.substring(1));
            lText(obj);
            continue;
        }
        // プラグイン
        var paragraphPluginMatch = line.match(/^\{\{(.+\}\})$/);
        var blockPluginStartMatch = line.match(/^\{\{(.+)$/);
        if (paragraphPluginMatch) {
            if (!block) {
                // TODO: parse_inline_pluginの実装が必要
                // const plugin = wiki.parse_inline_plugin(paragraphPluginMatch[1]);
                // const info = wiki.get_plugin_info(plugin.command);
                // if (info.TYPE === "paragraph") {
                //     lPlugin(plugin);
                // } else {
                //     const obj = parseLine(line);
                //     lText(obj);
                // }
                console.warn("TODO: Paragraph plugin parsing not implemented.");
                var obj = parseLine(line);
                lText(obj);
                continue;
            }
        }
        else if (blockPluginStartMatch) {
            if (block) {
                // TODO: parse_inline_pluginの実装が必要
                // const plugin = wiki.parse_inline_plugin(blockPluginStartMatch[1]);
                // const info = wiki.get_plugin_info(plugin.command);
                // block.level++ if (info.TYPE !== "inline");
                // block.args[0] += line + "\n";
                console.warn("TODO: Block plugin continuation parsing not implemented.");
                block.args[0] += line + "\n";
                continue;
            }
            // TODO: parse_inline_pluginの実装が必要
            // const plugin = wiki.parse_inline_plugin(blockPluginStartMatch[1]);
            // const info = wiki.get_plugin_info(plugin.command);
            // if (info.TYPE === "block") {
            //     plugin.args.unshift("");
            //     block = plugin;
            //     block.level = 0;
            // } else {
            //     const obj = parseLine(line);
            //     lText(obj);
            // }
            console.warn("TODO: Block plugin start parsing not implemented.");
            // 仮のブロックプラグインとして扱う
            block = { command: "TODO_PLUGIN", args: [line + "\n"], level: 0 };
            continue;
        }
        if (block) {
            if (line === "}}") {
                // TODO: block.levelの考慮が必要
                // if (block.level > 0) {
                //     block.level--;
                //     block.args[0] += line + "\n";
                //     continue;
                // }
                var plugin_1 = block;
                block = null;
                lPlugin(plugin_1);
            }
            else {
                block.args[0] += line + "\n";
            }
            continue;
        }
        // PRE
        if (word1 === " " || word1 === "\t") {
            lVerbatim(line);
            continue;
        }
        // 見出し
        if (word3 === "!!!") {
            var obj = parseLine(line.substring(3));
            lHeadline(1, obj);
            continue;
        }
        else if (word2 === "!!") {
            var obj = parseLine(line.substring(2));
            lHeadline(2, obj);
            continue;
        }
        else if (word1 === "!") {
            var obj = parseLine(line.substring(1));
            lHeadline(3, obj);
            continue;
        }
        // 項目
        if (word3 === "***") {
            var obj = parseLine(line.substring(3));
            lList(3, obj);
            continue;
        }
        else if (word2 === "**") {
            var obj = parseLine(line.substring(2));
            lList(2, obj);
            continue;
        }
        else if (word1 === "*") {
            var obj = parseLine(line.substring(1));
            lList(1, obj);
            continue;
        }
        // 番号付き項目
        if (word3 === "+++") {
            var obj = parseLine(line.substring(3));
            lNumlist(3, obj);
            continue;
        }
        else if (word2 === "++") {
            var obj = parseLine(line.substring(2));
            lNumlist(2, obj);
            continue;
        }
        else if (word1 === "+") {
            var obj = parseLine(line.substring(1));
            lNumlist(1, obj);
            continue;
        }
        // 水平線
        if (line === "----") {
            lLine();
            continue;
        }
        // 引用
        if (word2 === '""') {
            var obj = parseLine(line.substring(2));
            lQuotation(obj);
            continue;
        }
        // 説明
        if (line.indexOf(":") === 0 && line.indexOf(":", 1) !== -1) {
            if (line.indexOf(":::") === 0) {
                multiExplanation(line); // 複数行説明の続き
                continue;
            }
            if (dtBuffer !== "" || ddBuffer !== "") {
                multiExplanation(); // 複数行説明の終了
            }
            if (line.indexOf("::") === 0) {
                dtBuffer = line.substring(2);
                dlFlag = 1;
                continue;
            }
            var dt = line.substring(1, line.indexOf(":", 1));
            var dd = line.substring(line.indexOf(":", 1) + 1);
            var obj1 = parseLine(dt);
            var obj2 = parseLine(dd);
            lExplanation(obj1, obj2);
            continue;
        }
        // テーブル
        if (word1 === ",") {
            var tableLine = line;
            if (tableLine.endsWith(",")) {
                tableLine += " ";
            }
            // 正規表現でセルに分割
            var cellMatches = tableLine.match(/,\s*(\"[^\"]*(?:\"\"[^\"]*)*\"|[^,]*)/g);
            var row = [];
            if (cellMatches) {
                for (var _a = 0, cellMatches_1 = cellMatches; _a < cellMatches_1.length; _a++) {
                    var cellMatch = cellMatches_1[_a];
                    // 先頭の "," とそれに続く空白を削除
                    var cellContent = cellMatch.replace(/^,\s*/, "");
                    // 引用符で囲まれている場合は引用符を外し、""を"に変換
                    var processedCellContent = cellContent.match(/^"(.*)"$/)
                        ? cellContent.substring(1, cellContent.length - 1).replace(/\"\"/g, "\"")
                        : cellContent;
                    var cell = parseLine(processedCellContent);
                    row.push(cell);
                }
            }
            lTable(row);
            continue;
        }
        // コメント
        if (word2 === "//") {
            // コメント行は無視
            continue;
        }
        // 何もない行 (上記のどのパターンにもマッチしない場合)
        var parsedLine = parseLine(line);
        lText(parsedLine);
    }
    // 複数行の説明処理 (パース終了時のチェック)
    multiExplanation();
    // パース中のブロックプラグインがあった場合、とりあえず評価しておく？
    if (block) {
        // TODO: 残ったブロックプラグインの処理
        console.warn("TODO: Remaining block plugin processing not implemented.");
        lPlugin(block);
        block = null;
    }
    endParse(); // パース終了フック
    console.log("Finished parsing.");
    // TODO: パース結果を返す (中間表現など)
    return {}; // 仮の戻り値
}
/**
 * _parse_line_keyword に相当する関数。
 * キーワードやWikiNameをパースする。
 * @param source - パース対象の文字列
 * @returns パースされた要素の配列
 */
var parseLineKeyword = function (source, hooks) {
    if (source === undefined) {
        return [];
    }
    var keywordElements = [];
    var keywordRemainingSource = source;
    // Wiki::Parser.pmの_parse_line_keywordロジックを再現
    while (keywordRemainingSource !== '') {
        var matched = false;
        // TODO: Wiki::KeywordとWiki::InterWikiの実装が必要
        // 現時点ではキーワードとInterWikiNameの識別は簡易的に行うかスキップし、WikiNameを優先して処理する
        // Wiki::Parser.pmの_parse_line_keywordではキーワード、WikiNameの順にチェックしているが、
        // exists_keywordの実装が複雑なため、ここではWikiNameを先にチェックする簡易的な実装とする。
        // 正確な移植にはWiki::KeywordとWiki::InterWikiの移植が必要。
        // WikiName
        var wikiNameMatch = keywordRemainingSource.match(/^([A-Z]+?[a-z]+?(?:[A-Z]+?[a-zA-Z]+)+)/);
        if (wikiNameMatch) {
            var pre = keywordRemainingSource.substring(0, wikiNameMatch.index); // indexは常に0
            var page = wikiNameMatch[0];
            keywordRemainingSource = keywordRemainingSource.substring(wikiNameMatch[0].length);
            if (pre !== '') {
                // ここには来ないはずだが念のため
                keywordElements.push.apply(keywordElements, parseLineKeyword(pre, hooks)); // 再帰呼び出し
            }
            // TODO: wiki.config('wikiname') === 1 のチェックが必要
            keywordElements.push(hooks.wikiAnchor(page));
            matched = true;
        }
        // TODO: キーワードとInterWikiNameのパースロジックをここに追加
        // else if (/* キーワードにマッチ */) {
        //    ...
        // } else if (/* InterWikiNameにマッチ */) {
        //    ...
        // }
        // キーワードも WikiName も見つからなかったとき
        if (!matched) {
            // 1文字進めるか、残りをテキストとして扱う
            var singleCharMatch = keywordRemainingSource.match(/^(.)/);
            if (singleCharMatch) {
                keywordElements.push(hooks.text(singleCharMatch[0]));
                keywordRemainingSource = keywordRemainingSource.substring(singleCharMatch[0].length);
            }
            else {
                // 残り全てをテキストとして扱う（通常はここに到達しないはず）
                keywordElements.push(hooks.text(keywordRemainingSource));
                keywordRemainingSource = ''; // 処理終了
            }
        }
    }
    return keywordElements;
};
/**
 * 1行内のインライン要素をパースする。
 * Wiki::Parser.pmのparse_lineメソッドのロジックをTypeScriptで再現する。
 * @param source - パース対象の文字列
 * @returns パースされた要素の配列
 */
function parseLine(source) {
    if (source === undefined) {
        return [];
    }
    console.log("Parsing inline: \"".concat(source, "\""));
    var elements = [];
    var remainingSource = source;
    var pre = ""; // マッチしなかった先頭部分
    // $source が空になるまで繰り返す。
    SOURCE_LOOP: while (remainingSource !== "") {
        var parsed = [];
        // どのインライン Wiki 書式の先頭にも match しない場合
        var match = remainingSource.match(/^(.*?)((?:\{\{|\[\[?|https?:|mailto:|f(?:tp:|file:)|'''?|==|__|<<).*)$/);
        if (!match) {
            // キーワード検索・置換処理のみ実施して終了する
            var hooks = { text: text, urlAnchor: urlAnchor, wikiAnchor: wikiAnchor };
            elements.push.apply(elements, parseLineKeyword(pre + remainingSource, hooks));
            return elements;
        }
        pre += match[1]; // match しなかった先頭部分は溜めておく
        remainingSource = match[2]; // match 部分は後続処理にて詳細チェックを行う
        parsed = [];
        // プラグイン
        if (remainingSource.startsWith("{{")) {
            // TODO: parse_inline_pluginの実装が必要
            console.warn("TODO: Inline plugin parsing not implemented.");
            remainingSource = remainingSource.substring(2); // 仮にスキップ
            parsed.push(text("{{")); // 仮にテキストとして扱う
            // const plugin = wiki.parse_inline_plugin(remainingSource);
            // if (!plugin) {
            //     parsed.push(text('{{'));
            //     parsed.push(...parseLine(remainingSource));
            // } else {
            //     const info = wiki.get_plugin_info(plugin.command);
            //     if (info.TYPE === "inline") {
            //         parsed.push(plugin(plugin)); // pluginフックを呼び出し
            //     } else {
            //         parsed.push(...parseLine(`<<${plugin.command}プラグインは存在しません。>>`));
            //     }
            //     remainingSource = plugin.post;
            // }
        }
        // InterWikiName
        // TODO: exists_interwikiの実装が必要
        // else if (wiki.interwiki.exists_interwiki(remainingSource)) {
        //     const label = wiki.interwiki.g_label;
        //     const url = wiki.interwiki.g_url;
        //     remainingSource = wiki.interwiki.g_post;
        //     parsed.push(urlAnchor(url, label));
        // }
        // ページ別名リンク [[label|page]]
        else if (remainingSource.match(/^\[\[([^\[]+?)\|([^\|\[]+?)\]\]/)) {
            var linkMatch = remainingSource.match(/^\[\[([^\[]+?)\|([^\|\[]+?)\]\]/);
            var label = linkMatch[1];
            var page = linkMatch[2];
            remainingSource = remainingSource.substring(linkMatch[0].length);
            parsed.push(wikiAnchor(page, label));
        }
        // URL別名リンク [label|url]
        else if (remainingSource.match(/^\[([^\[]+?)\|((?:http|https|ftp|mailto):[a-zA-Z0-9\.,%~^_+\-%\/\?\(\)!&=:;\*#\@'\$]*)\]/) ||
            remainingSource.match(/^\[([^\[]+?)\|(file:[^\[\]]*)\]/) ||
            remainingSource.match(/^\[([^\[]+?)\|((?:\/|\.\/|\.\.\/)+[a-zA-Z0-9\.,%~^_+\-%\/\?\(\)!&=:;\*#\@'\$]*)\]/)) {
            var linkMatch = remainingSource.match(/^\[([^\[]+?)\|((?:http|https|ftp|mailto):[a-zA-Z0-9\.,%~^_+\-%\/\?\(\)!&=:;\*#\@'\$]*)\]/) ||
                remainingSource.match(/^\[([^\[]+?)\|(file:[^\[\]]*)\]/) ||
                remainingSource.match(/^\[([^\[]+?)\|((?:\/|\.\/|\.\.\/)+[a-zA-Z0-9\.,%~^_+\-%\/\?\(\)!&=:;\*#\@'\$]*)\]/);
            var label = linkMatch[1];
            var url = linkMatch[2];
            remainingSource = remainingSource.substring(linkMatch[0].length);
            if (url.indexOf('"') >= 0 ||
                url.indexOf("><") >= 0 ||
                url.indexOf("javascript:") >= 0) {
                parsed.push(error("<<不正なリンクです。>>"));
            }
            else {
                // TODO: wiki.config('server_host') や wiki.get_CGI() の実装が必要
                // 現時点ではURLをそのまま使用
                parsed.push(urlAnchor(url, label));
            }
        }
        // URLリンク (http:, https:, ftp:, mailto:, file:)
        else if (remainingSource.match(/^(?:https?|ftp|mailto):[a-zA-Z0-9\.,%~^_+\-%\/\?\(\)!&=:;\*#\@'\$]*/) ||
            remainingSource.match(/^file:[^\[\]]*/)) {
            var urlMatch = remainingSource.match(/^(?:https?|ftp|mailto):[a-zA-Z0-9\.,%~^_+\-%\/\?\(\)!&=:;\*#\@'\$]*/) || remainingSource.match(/^file:[^\[\]]*/);
            var url = urlMatch[0];
            remainingSource = remainingSource.substring(urlMatch[0].length);
            if (url.indexOf('"') >= 0 ||
                url.indexOf("><") >= 0 ||
                url.indexOf("javascript:") >= 0) {
                parsed.push(error("<<不正なリンクです。>>"));
            }
            else {
                parsed.push(urlAnchor(url));
            }
        }
        // ページリンク [[page]]
        else if (remainingSource.match(/^\[\[([^\|]+?)\]\]/)) {
            var linkMatch = remainingSource.match(/^\[\[([^\|]+?)\]\]/);
            var page = linkMatch[1];
            remainingSource = remainingSource.substring(linkMatch[0].length);
            parsed.push(wikiAnchor(page));
        }
        // 任意のURLリンク [label|.+?] (上記のURL別名リンクに含まれないもの)
        // Wiki::Parser.pmではこのパターンはURL別名リンクの後にチェックされているが、正規表現が異なる
        // ここでは簡易的に、[label|...] の形式で、かつ上記のURL別名リンクのパターンにマッチしなかったものを扱う
        // TODO: Wiki::Parser.pmの正規表現を正確に移植する必要がある
        else if (remainingSource.match(/^\[([^\[]+?)\|(.+?)\]/)) {
            var linkMatch = remainingSource.match(/^\[([^\[]+?)\|(.+?)\]/);
            var label = linkMatch[1];
            var url = linkMatch[2];
            remainingSource = remainingSource.substring(linkMatch[0].length);
            if (url.indexOf('"') >= 0 ||
                url.indexOf("><") >= 0 ||
                url.indexOf("javascript:") >= 0) {
                parsed.push(error("<<不正なリンクです。>>"));
            }
            else {
                // TODO: Wiki::Parser.pmのURL生成ロジックを正確に移植する必要がある
                // 現時点ではURLをそのまま使用
                parsed.push(urlAnchor(url, label));
            }
        }
        // ボールド、イタリック、取り消し線、下線
        else if (remainingSource.match(/^('''?|==|__)(.+?)\1/)) {
            var formatMatch = remainingSource.match(/^('''?|==|__)(.+?)\1/);
            var type = formatMatch[1];
            var label = formatMatch[2];
            remainingSource = remainingSource.substring(formatMatch[0].length);
            if (type === "'''") {
                // 三連クォートは文字列リテラルとして修正
                parsed.push(bold(label));
            }
            else if (type === "__") {
                parsed.push(underline(label));
            }
            else if (type === "''") {
                parsed.push(italic(label));
            }
            else {
                // type === '=='
                parsed.push(denialline(label));
            }
        }
        // エラーメッセージ <<...>>
        else if (remainingSource.match(/^<<(.+?)>>/)) {
            var errorMatch = remainingSource.match(/^<<(.+?)>>/);
            var label = errorMatch[1];
            remainingSource = remainingSource.substring(errorMatch[0].length);
            parsed.push(error(label));
        }
        // インライン Wiki 書式全体には macth しなかったとき
        else {
            // 1 文字進む。
            var charMatch = remainingSource.match(/^(.)/);
            if (charMatch) {
                pre += charMatch[1];
                remainingSource = remainingSource.substring(charMatch[0].length);
            }
            // parse 結果を @array に保存する処理を飛ばして繰り返し。
            continue SOURCE_LOOP;
        }
        // インライン Wiki 書式全体に macth した後の
        // parse 結果を @array に保存する処理。
        // もし $pre が溜まっているなら、キーワードの処理を実施。
        if (pre !== "") {
            var hooks = { text: text, urlAnchor: urlAnchor, wikiAnchor: wikiAnchor };
            elements.push.apply(elements, parseLineKeyword(pre, hooks));
            pre = "";
        }
        elements.push.apply(elements, parsed);
    }
    // もし $pre が溜まっているなら、キーワードの処理を実施。
    if (pre !== "") {
        var hooks = { text: text, urlAnchor: urlAnchor, wikiAnchor: wikiAnchor };
        elements.push.apply(elements, parseLineKeyword(pre, hooks));
    }
    console.log("Finished parsing inline.");
    return elements; // パースされた要素の配列を返す
}
// --- フックメソッドのスタブ ---
// これらのメソッドは、Wiki::HTMLParser.pmに相当するクラスでオーバーライド
function startParse() {
    console.log("Hook: startParse");
    // パース開始時の処理 (サブクラスでオーバーライド)
}
function endParse() {
    console.log("Hook: endParse");
    // パース終了時の処理 (サブクラスでオーバーライド)
}
function urlAnchor(url, label) {
    console.log("Hook: urlAnchor - URL: ".concat(url, ", Label: ").concat(label));
    // URLアンカにマッチした場合の処理 (サブクラスで実装)
    return { type: "url_anchor", url: url, label: label };
}
function wikiAnchor(page, label) {
    console.log("Hook: wikiAnchor - Page: ".concat(page, ", Label: ").concat(label));
    // ページ名アンカにマッチした場合の処理 (サブクラスで実装)
    return { type: "wiki_anchor", page: page, label: label };
}
function italic(content) {
    console.log("Hook: italic - Content: ".concat(content));
    // イタリックにマッチした場合の処理 (サブクラスで実装)
    return { type: "italic", content: content };
}
function bold(content) {
    console.log("Hook: bold - Content: ".concat(content));
    // ボールドにマッチした場合の処理 (サブクラスで実装)
    return { type: "bold", content: content };
}
function underline(content) {
    console.log("Hook: underline - Content: ".concat(content));
    // 下線にマッチした場合の処理 (サブクラスで実装)
    return { type: "underline", content: content };
}
function denialline(content) {
    console.log("Hook: denialline - Content: ".concat(content));
    // 打ち消し線にマッチした場合の処理 (サブクラスで実装)
    return { type: "denialline", content: content };
}
function plugin(pluginInfo) {
    console.log("Hook: plugin - Info: ".concat(JSON.stringify(pluginInfo)));
    // プラグインにマッチした場合の処理 (サブクラスで実装)
    return { type: "plugin", pluginInfo: pluginInfo };
}
function text(content) {
    console.log("Hook: text - Content: \"".concat(content, "\""));
    // テキストにマッチした場合の処理 (サブクラスで実装)
    return { type: "text", content: content };
}
function lList(level, content) {
    console.log("Hook: lList - Level: ".concat(level, ", Content: ").concat(JSON.stringify(content)));
    // 項目にマッチした場合の処理 (サブクラスで実装)
    return { type: "list_item", level: level, content: content };
}
function lNumlist(level, content) {
    console.log("Hook: lNumlist - Level: ".concat(level, ", Content: ").concat(JSON.stringify(content)));
    // 番号付き項目にマッチした場合の処理 (サブクラスで実装)
    return { type: "numlist_item", level: level, content: content };
}
function lHeadline(level, content) {
    console.log("Hook: lHeadline - Level: ".concat(level, ", Content: ").concat(JSON.stringify(content)));
    // 見出しにマッチした場合の処理 (サブクラスで実装)
    return { type: "headline", level: level, content: content };
}
function lVerbatim(content) {
    console.log("Hook: lVerbatim - Content: \"".concat(content, "\""));
    // PREタグにマッチした場合の処理 (サブクラスで実装)
    return { type: "verbatim", content: content };
}
function lLine() {
    console.log("Hook: lLine");
    // 水平線にマッチした場合の処理 (サブクラスで実装)
    return { type: "horizontal_rule" };
}
function lText(content) {
    console.log("Hook: lText - Content: ".concat(JSON.stringify(content)));
    // 特になにもない行にマッチした場合の処理 (サブクラスで実装)
    return { type: "paragraph", content: content };
}
function lExplanation(dt, dd) {
    console.log("Hook: lExplanation - DT: ".concat(JSON.stringify(dt), ", DD: ").concat(JSON.stringify(dd)));
    // 説明にマッチした場合の処理 (サブクラスで実装)
    return { type: "explanation", dt: dt, dd: dd };
}
function lQuotation(content) {
    console.log("Hook: lQuotation - Content: ".concat(JSON.stringify(content)));
    // 引用にマッチした場合の処理 (サブクラスで実装)
    return { type: "quotation", content: content };
}
function lParagraph() {
    console.log("Hook: lParagraph");
    // パラグラフの区切りにマッチした場合の処理 (サブクラスで実装)
    return { type: "paragraph_break" };
}
function lTable(row) {
    console.log("Hook: lTable - Row: ".concat(JSON.stringify(row)));
    // テーブル行にマッチした場合の処理 (サブクラスで実装)
    // Wiki::Parser.pmのl_tableは行の配列を受け取るが、ここでは1行ずつ処理するため行を渡す
    return { type: "table_row", row: row };
}
function lPlugin(pluginInfo) {
    console.log("Hook: lPlugin - Info: ".concat(JSON.stringify(pluginInfo)));
    // パラグラフプラグインにマッチした場合の処理 (サブクラスで実装)
    return { type: "block_plugin", pluginInfo: pluginInfo };
}
function lImage(url, alt) {
    console.log("Hook: lImage - URL: ".concat(url, ", Alt: ").concat(alt));
    // 画像にマッチした場合の処理 (サブクラスで実装)
    return { type: "image", url: url, alt: alt };
}
function error(message) {
    console.log("Hook: error - Message: \"".concat(message, "\""));
    // エラーメッセージにマッチした場合の処理 (サブクラスで実装)
    return { type: "error", message: message };
}
// 複数行の説明処理 (Wiki::Parser.pmのmulti_explanationに相当)
var dlFlag = 0;
var dtBuffer = "";
var ddBuffer = "";
function multiExplanation(line) {
    // この関数はparseWikiText内で各行処理後に呼ばれるか、パース終了時に引数なしで呼ばれる
    // Wiki::Parser.pmのmulti_explanationロジックを再現
    if (dlFlag === 1 && (line === undefined || !line.startsWith(":"))) {
        var parsedDt = parseLine(dtBuffer);
        var parsedDd = parseLine(ddBuffer);
        lExplanation(parsedDt, parsedDd);
        dlFlag = 0;
        dtBuffer = "";
        ddBuffer = "";
    }
    if (line !== undefined && line.startsWith(":::") && dlFlag === 1) {
        ddBuffer += line.substring(3);
    }
}
