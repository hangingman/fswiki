############################################################
#
# 書籍執筆用のプラグインを提供します。
#
############################################################
package plugin::book::Install;
use strict;
use plugin::book::TocParser;

sub install {
	my $wiki  = shift;
	$wiki->add_paragraph_plugin("chapter", "plugin::book::Chapter", "HTML");
	$wiki->add_paragraph_plugin("section", "plugin::book::Section", "HTML");
	$wiki->add_inline_plugin("title1", "plugin::book::Title1", "HTML");
	$wiki->add_inline_plugin("title2", "plugin::book::Title2", "HTML");
	$wiki->add_inline_plugin("title3", "plugin::book::Title3", "HTML");
	$wiki->add_paragraph_plugin("caption" ,"plugin::book::Caption" ,"HTML");
	$wiki->add_paragraph_plugin("toc" ,"plugin::book::Toc" ,"HTML");
	$wiki->add_inline_plugin("link" ,"plugin::book::Link" ,"HTML");
	
	$wiki->add_block_plugin("list" ,"plugin::book::List" ,"HTML");
	$wiki->add_inline_plugin("code" ,"plugin::book::Code" ,"HTML");
	
	$wiki->add_block_plugin("column" ,"plugin::book::Column" ,"HTML");
	$wiki->add_paragraph_plugin("columnlist", "plugin::book::ColumnList", "HTML");
	$wiki->add_block_plugin("note" ,"plugin::book::Note" ,"HTML");
	$wiki->add_block_plugin("box" ,"plugin::book::Box" ,"HTML");
	
	$wiki->add_inline_plugin("memo", "plugin::book::Memo", "HTML");
	$wiki->add_inline_plugin("add", "plugin::book::Add", "HTML");
	$wiki->add_inline_plugin("del", "plugin::book::Del", "HTML");
	$wiki->add_paragraph_plugin("memolist", "plugin::book::Memolist", "HTML");
	
	$wiki->add_inline_plugin("wordcount", "plugin::book::Wordcount", "HTML");
	$wiki->add_inline_plugin("pagecount", "plugin::book::Pagecount", "HTML");
	
	$wiki->add_hook("chapter", "plugin::book::Title1");
	$wiki->add_hook("chapter", "plugin::book::Title2");
	$wiki->add_hook("chapter", "plugin::book::Title3");
	$wiki->add_hook("chapter", "plugin::book::Caption");
	
	$wiki->add_hook("title1", "plugin::book::Title2");
	$wiki->add_hook("title1", "plugin::book::Title3");
	$wiki->add_hook("title3", "plugin::book::Title3");
	
	$wiki->add_inline_plugin("br", "plugin::book::Br");
	$wiki->add_paragraph_plugin("keyword" ,"plugin::book::Keyword" ,"HTML");
	
	my @paths = split(/\//, $wiki->get_CGI()->path_info());
	my $path_prefix = '';
	for(my $i = 0; $i < $#paths; $i++){
		$path_prefix .= '../';
	}
	$wiki->{book_plugin_path_prefix} = $path_prefix;
	
	my $head_info = <<"END_OF_HEAD";
<link href="${path_prefix}plugin/book/google-code-prettify/sunburst.css" type="text/css" rel="stylesheet" />
<script type="text/javascript" src="${path_prefix}plugin/book/google-code-prettify/prettify.js"></script>
<script type="text/javascript">window.onload = function(){ prettyPrint(); }</script>
<style type="text/css">
div.chapter {
  text-align: right;
  padding: 20px;
  font-size: 200%;
  font-style: italic;
}

a.xref {
  background-color: silver;
  border: 1px solid gray;
}

a.xref:link {
  color: black;
}

a.xref:hover {
  color: black;
}

a.xref:visited {
  color: black;
}

span.xref-error {
  background-color: silver;
  font-weight: bold;
}

span.memo {
  background-color: yellow;
  border: 1px solid #888800;
  margin-left: 2px;
  margin-right: 2x;
}

span.delete {
  color: blue;
  text-decoration: line-through;
}

span.add {
  color: red;
  text-decoration: underline;
}

div.caption {
  font-size: 80%;
  font-weight: bold;
}

code {
 font-weight: bold;
/* font-style: italic; */
 font-family: monospace;
}

img {
  border: 1px solid silver;
}

div.column {
  border: 1px solid gray;
  margin-left: 20px;
  margin-right: 20px;
  margin-top: 10px;
  margin-bottom: 20px;
}

div.column-title {
  background-color: silver;
  font-weight: bold;
  padding: 4px;
}

div.column-body {
  padding: 4px;
}

div.note {
  border: 2px dotted #FF8888;
  background-color: #FFEEEE;
  margin-bottom: 20px;
  margin-left: 20px;
  margin-top: 10px;
  margin-right: 20px;
}

div.note-title {
  font-weight: bold;
  padding: 4px;
}

div.note-body {
  padding: 4px;
}

span.keyword {
  background-color: #666688;
  color: white;
  padding: 4px;
}

span.keyword a {
  color: white;
}

div.keyword {
  padding-top: 4px;
  padding-left: 4px;
  padding-right: 4px;
  padding-bottom: 8px;
}

table.box {
  width: 100%;
  border-top: none;
  border-left: none;
  border-right: none;
  border-bottom: none;
  border-collapse:collapse;
  border-spacing:0;
  empty-cells:show;
  margin: 2px;
}

table.box th {
  width: 100px;
  border-top: 1px solid #88AAFF;
  border-left: 1px solid #88AAFF;
  border-right:1px solid #88AAFF;
  border-bottom:1px solid #88AAFF;
  background-position:left top;
  padding:0.3em 1em;
  text-align:center;
}

table.box td {
  border-top: 1px solid #88AAFF;
  border-left: none;
  border-right:1px solid #88AAFF;
  border-bottom:1px solid #88AAFF;
  padding:0.3em 1em;
}

table.box ul {
  margin-bottom: 0px;
  margin-left: 0px;
  padding-left: 10px;
}

table.box p {
  margin-bottom: 0px;
  margin-left: 0px;
  padding-left: 0px;
}

pre.prettyprint strong {
  background-color: #444444;
  text-decoration: underline;
#  border: 1px solid gray;
  font-weight: normal;
}
</style>
END_OF_HEAD
	
	$wiki->add_head_info($head_info);
}

1;
