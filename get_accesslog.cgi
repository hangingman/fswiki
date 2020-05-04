#!/usr/local/bin/perl
# get_accesslog.cgi
BEGIN {
    push(@INC,'.');
    push(@INC,'./lib');
}
use strict;
use warnings;
use CGI::Carp qw(fatalsToBrowser);
use CGI;
use Jcode;
use Util;

my $cgi = CGI->new();

my $num = $cgi->param("num");
my $disp  = $cgi->param("disp");
my $font  = $cgi->param("font");
my $file  = $cgi->param("file");
my $i = 0;
my $k = 0;
my $output = "";
my @lines = ();
my $end = ($num * $disp) - 1;
my $start = ($end - $disp) + 1;
if($start <= 0){
    $start = 0;
}

open(FH ,"<$file");
while(<FH>){
    if($i >= $start && $i <= $end){
        chomp;
        @lines = split(/\s/);
        $output .= "<tr><td>".Util::url_decode($lines[0])."</td>";
        $output .= "<td>$lines[1] $lines[2]</td>";
        $output .= "<td>$lines[3]</td>";
        $output .= "<td>".Util::url_decode($lines[4])."</td>";
        $output .= "<td>\n";
        for($k=5;$k<=$#lines;$k++){
            $output .= $lines[$k]." ";
        }
    }
    $i++;
}
close(FH);

my $data =<<"__HTML__";
<div id="result">
<table width="100%" style="font-size: $font;">
<tr><td>Page</td><td>Time</td><td>IP</td><td>Referrer</td><td>Agent</td></tr>
$output
</table></div>
__HTML__

print $cgi->header(-type=>'text/html',-charset=>'UTF-8',);
print $data;

exit;
