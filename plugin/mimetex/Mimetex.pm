###############################################################################
#
# <p>mimetex.cgiを使い数式イメージを挿入するプラグイン</p>
# <p> A plugin to show the image of math formular with mimetex.cgi</p>
#
# <pre>
#   {{mimetex parameter}}
# or
#   {{tex parameter}}
# or
#   {{math parameter}}
# </pre>
# <p>
# 
# <pre>
# Example
# {{tex \exp(x)=1+x+\frac{1}{2!}x^2+\frac{1}{3!}x^3+... ,. }}
# {{math \exp(x)=1+x+\frac{1}{2!}x^2+\frac{1}{3!}x^3+... ,. }}
#
# {{mimetex \exp(x)=1+x+\frac{1}{2!}x^2+\frac{1}{3!}x^3+... ,. }}
#
# {{mimetex \LARGE \exp(x)=1+x+\frac{1}{2!}x^2+\frac{1}{3!}x^3+... ,. }}
#
# {{mimetex \LARGE \exp(x)=1+x+\frac{1}{2!}x^2+\frac{1}{3!}x^3+... ,. }}
#
# </pre>
# </p>
# <p>
#
# config/plugin.datにmimetexを追加すれば
# 任意の場所でmimetex.cgiを利用できます。
#
# Check plugin for mimetex after you login.
#
# Modified by Mo Y.
# </p>
#
###############################################################################
package plugin::mimetex::Mimetex;

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
  # {{mimetex \LARGE f(x,y,z) = x + y + z }}
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
  
  my $mimetex=$wiki->config('mimetex');
  $mimetex="../mimetex.cgi" if !$mimetex;
  my $url = $mimetex."?".$param; 
  
  return "<img $style class=\"mimetex\" src=\"$url\" alt=\"$param\" />";
}

1;
