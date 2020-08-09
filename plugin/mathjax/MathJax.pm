###############################################################################
#
# <p>MathJaxを使い数式イメージを挿入するプラグイン</p>
#
# <pre>
#   {{mathjax parameter}}
# </pre>
# <p>
#
# <pre>
# Example
# {{mathjax \exp(x)=1+x+\frac{1}{2!}x^2+\frac{1}{3!}x^3+... ,. }}
#
# {{mathjax \LARGE \exp(x)=1+x+\frac{1}{2!}x^2+\frac{1}{3!}x^3+... ,. }}
#
# {{mathjax \LARGE \exp(x)=1+x+\frac{1}{2!}x^2+\frac{1}{3!}x^3+... ,. }}
#
# </pre>
# </p>
#
###############################################################################
package plugin::mathjax::MathJax;

#==============================================================================
# Constructor
#==============================================================================
sub new {
  my $class = shift;
  my $self = {};
  return bless $self,$class;
}
#========================================================================
# inline
#========================================================================
sub inline {
  my $self = shift;
  my $wiki = shift;
  my $param = shift;

  #-------------------------------------------------------
  # In order to use comma but not use quote " " in
  #
  # {{mathjax \LARGE f(x,y,z) = x + y + z }}
  #
  # the following while loop is used to parse the formula
  # correctly.
  #-------------------------------------------------------

  my @parameters = @_;
  for my $par (@parameters) {
    $param .= "\,".$par;
  }

  my $mathjax=$wiki->config('mathjax');
  #return &Util::escapeHTML($param);
  return $param;
}

1;
