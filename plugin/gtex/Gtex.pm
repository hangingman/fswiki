###############################################################################
#
# <p>Google Chart APIを使い数式イメージを挿入するプラグイン</p>
#
# <pre>
#   {{gtex parameter}}
# </pre>
# <p>
# 
# <pre>
# Example
# {{gtex \exp(x)=1+x+\frac{1}{2!}x^2+\frac{1}{3!}x^3+... ,. }}
#
# {{gtex \LARGE \exp(x)=1+x+\frac{1}{2!}x^2+\frac{1}{3!}x^3+... ,. }}
#
# {{gtex \LARGE \exp(x)=1+x+\frac{1}{2!}x^2+\frac{1}{3!}x^3+... ,. }}
#
# </pre>
# </p>
#
###############################################################################
package plugin::gtex::Gtex;

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
  # {{gtex \LARGE f(x,y,z) = x + y + z }}
  #
  # the following while loop is used to parse the formula
  # correctly.
  #-------------------------------------------------------

  my @parameters = @_;
  for my $par (@parameters) {
    $param .= "\,".$par;
  }

  #my $param2 = shift;
  #while ($param2) {
  #  $param .= "\,".$param2;
  #  $param2 = shift;
  #}
  #-------------------------------------------------------end
  
  # Change as you wish.
  my $style = qq(align="absmiddle");
  
  my $gtex=$wiki->config('gtex');
  $gtex="https://chart.googleapis.com/chart?cht=tx&chl=" if !$gtex;
  $param =~ s/([^ 0-9a-zA-Z])/"%".uc(unpack("H2",$1))/eg;
  $param =~ s/ /+/g;
  my $url = $gtex.$param; 
  
  return "<img $style src=\"$url\" alt=\"$param\" />";
}

1;
