############################################################
#
# MathJaxを使い数式イメージを挿入するプラグイン
#
############################################################
package plugin::mathjax::Install;

sub install {
	my $wiki = shift;
	$wiki->add_inline_plugin("mathjax","plugin::mathjax::MathJax", "HTML");

	my $head_info = <<"END_OF_HEAD";
<script src="https://polyfill.io/v3/polyfill.min.js?features=es6"></script>
<script id="MathJax-script" async
  src="https://cdn.jsdelivr.net/npm/mathjax\@3/es5/tex-mml-chtml.js">
</script>
END_OF_HEAD

	$wiki->add_head_info($head_info);
}

1;
