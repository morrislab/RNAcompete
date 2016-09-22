use strict;
use warnings;

use Term::ANSIColor;

# A function named "replicate" used to be defined here. it was also defined in
# libfile.pl (or was it libstats.pl) Replicate is just a redefinition of Perl's
# "x" operator. "x" is actually "multiply this string by this number of times.
# For example: print "ROBOT--" x 2; will print ROBOT--ROBOT-- Therefore, the
# "replicate" function is not necessary. Also, it is overloaded in another
# library, so we should not have two functions in the same namespace with the
# same name anyway. sub replicate
# # ($str, $num) { my ($str, $num) = @_; my $replicates = ''; for(my $i = 0; $i
# < $num; $i++) { $replicates .= $str; } return $replicates; }

# Takes a string as input, and returns it with multi-spaces collapsed down to
# singles, and no trailing or leading whitespace.
sub remExtraSpaces($) {
  my $string = shift;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  $string =~ s/(\s)\s+//g;
  return $string;
}


sub setOutputColor($) {
  return(colorString($_[0]));
}

sub colorString($) {
  # Requires: use Term::AnsiColor at the top of your file. Note: you have to
  # PRINT the result of this function! Only sets the output color if the output
  # is a TERMINAL. If the output is NOT a terminal, then colorizing output
  # results in lots of garbage characters (the color control characters)
  # written to the screen.
  my ($theColor) = @_;
  if (-t STDOUT) { # <-- checks to see if STDOUT goes directly to the terminal (instead of, say, outputting to a file with a redirect)
	return color($theColor);
  }
}

sub colorResetString() {
  # Note: you have to PRINT the result of this function! # Usage: "print
  # resetColor()"
  return colorString("reset");	# sets the font color back to the normal one
}

sub resetColor() {
  return colorResetString();
}



sub roundFloat($$) {
  # Rounds a number to $numPlaces decimal places. Returns it as a string.
  my ($theNumber, $numPlaces) = @_;
  return sprintf(("%." . $numPlaces . "f"),   $theNumber);
}




sub percentileToColor($;$$) {
  # Takes a "low" color -- (blue "000099" is a good example),
  # a high color (red -- "FF0000" is a good example), and a percentile from 0 to 100 inclusive,
  # and prints out the color that is a linear interpolation between the defined high and
  # low colors.
  my ($percentile, $lowColor, $hiColor) = @_;

  if (!defined($lowColor)) {
	$lowColor = '000066';
  }
  if (!defined($hiColor )) {
	$hiColor = 'FF6633';
  }
  my @lowDecArr = (hex(substr($lowColor,0,2)), hex(substr($lowColor,2,2)), hex(substr($lowColor,4,2)));
  my @hiDecArr = (hex(substr($hiColor,0,2)), hex(substr($hiColor,2,2)), hex(substr($hiColor,4,2)));
  my @resultDecArr = ();
  for (my $i = 0; $i < scalar(@lowDecArr) && $i < scalar(@hiDecArr); $i++) {
	$resultDecArr[$i] = ($lowDecArr[$i] * (100 - $percentile)/100)  +  ($hiDecArr[$i] * ($percentile/100));
  }
  return (sprintf("%X%X%X", $resultDecArr[0],$resultDecArr[1],$resultDecArr[2]));
}












1
