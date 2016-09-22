#!/usr/bin/perl

require "libfile.pl";
require "$ENV{MYPERLDIR}/lib/libstats.pl";
require "$ENV{MYPERLDIR}/lib/libstring.pl";
require "$ENV{MYPERLDIR}/lib/libsystem.pl";

#use List::Util 'shuffle';
#@shuffled = shuffle(@list);
# Check out: perldoc -q array

use POSIX      qw(ceil floor);
use List::Util qw(max min);
use Term::ANSIColor;
use File::Basename;
use Getopt::Long;

use strict;
use warnings;
use diagnostics;

sub main();

print colorString("blue");
print "Arr";
colorResetString();

sub printUsage() {
    print STDOUT <DATA>;
    exit(0);
}

# ==1==
sub main() { # Main program
    my ($delim) = "\t";
    my ($decimalPlaces) = 4; # How many decimal places to print, by default

	$Getopt::Long::passthrough = 1; # ignore arguments we don't recognize in GetOptions, and put them in @ARGV

    GetOptions("help|?|man" => sub { printUsageAndQuit(); }
	       , "delim|d=s" => \$delim
		   , "dp=i" => \$decimalPlaces
	       ) or printUsageAndQuit();

	if (1 == 0) {
	  quitWithUsageError("1 == 0? Something is wrong!");
	}

	my $numUnprocessedArgs = scalar(@ARGV);
	if ($numUnprocessedArgs != 2) {
	  quitWithUsageError("Error in arguments! You must send TWO filenames to this program.\n");
	}


	my $filename1 = undef;
	my $filename2 = undef;

	foreach (@ARGV) { # these were arguments that were not understood by GetOptions
	  if (!defined($filename1)) { $filename1 = $_; }
	  else if (!defined($filename2)) { $filename2 = $_; }
	  else {
		print STDERR "Unprocessed argument: $_\n";
	  }
	}


	#print "\t" . sprintf("%.${numDecimalPointsToPrint}f", $levFraction);
	#my @col1 = @{readFileColumn($filename1, 0, $delim)};

	print STDERR colorString("green");
	print STDERR "===============================\n";
	print STDERR "Done!\n";
	print STDERR colorResetString();
} # end main()


main();


END {
  # Runs after everything else.
  # Makes sure that the terminal text is back to its normal color.
  resetColor();
}

exit(0);
# ====

__DATA__

MYPROGRAM.pl  [OPTIONS]

by YOUR NAME, THE_YEAR

THIS PROGRAM DOES SOMETHING. YOU GIVE IT ONE THING AND THIS OTHER THING,
AND THE OUTPUT IS THIS FINAL THING.

See the examples below for more information.

CAVEATS:

MAYBE EXPECTS A HEADER LINE BY DEFAULT.

MAYBE IT BREAKS IF THE INPUT IS TOO LONG.

MAYBE IT TAKES 30 MINUTES TO RUN.

OPTIONS:

  --delim = DELIMITER   (Default: tab)
     Sets the input delimiter to DELIMITER.

EXAMPLES:

MYPROGRAM.pl --help
  Displays this help

MYPROGRAM.pl  --works=yes --bugs=4  -q
  Does nothing. -q indicates "quiet" operation.


KNOWN BUGS:

  None known.

TO DO:

  Add ???.

--------------
