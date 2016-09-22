#!/usr/bin/perl

sub errorMessageHandler () {
  # Used to ignore imported module warnings.
  # Dangerous! But Text::Levenshtein has warning issues,
  # so this is used to ignore its warnings.
  return;
}

use String::Approx qw(adistr adist amatch); # <-- from CPAN
# Docs: http://search.cpan.org/~jhi/String-Approx-3.26/Approx.pm

{
  # Do not warn about Text::Levenshtein! (But we WILL warn about other things)
  no warnings;
  $SIG{'__WARN__'} = \&errorMessageHandler; # <-- Ignore warnings in Text::Levenshtein
  use Text::Levenshtein; # qw(distance fastdistance); # <-- from CPAN
# Docs: http://search.cpan.org/~jgoldberg/Text-Levenshtein-0.05/Levenshtein.pm
# "This module implements the Levenshtein edit distance. The Levenshtein edit distance is a measure of the degree of proximity between two strings. This distance is the number of substitutions, deletions or insertions ("edits") needed to transform one string into the other one (and vice versa). When two strings have distance 0, they are the same."
}

require "libfile.pl";
require "$ENV{MYPERLDIR}/lib/libstats.pl";
require "$ENV{MYPERLDIR}/lib/libstring.pl";
require "$ENV{MYPERLDIR}/lib/libsystem.pl";

use POSIX qw(ceil floor); # import the ceil(ing) and floor functions for handling fractions/integers
use List::Util qw(max min); # import the max and min functions
use Term::ANSIColor;

use strict;
use warnings;
use diagnostics;

use File::Basename;
use Getopt::Long;


sub main();


# ==1==
sub main() { # Main program
    my ($delim) = "\t";
	my ($colToReadInFile1) = 1; # Default: 1
	my ($colToReadInFile2) = 1; # Default: 1
    my ($decimalPlaces) = 4; # How many decimal places to print, by default

	my ($relativeCutoff) = 1.0; # 1 = Accept ANYthing. 0 = exact and proper-substring matches only. 0.1 = strict-ish matches. Etc. Based on the "LevFraction" variable.

	my $numDecimalPointsToPrint = 3;

	my $caseSensitive = 0; # Default: not case-sensitive

	my $onlyCalculateLev = 0; # Default: calculate several things

	$Getopt::Long::passthrough = 1; # ignore arguments we don't recognize in GetOptions, and put them in @ARGV

    GetOptions("help|?|man" => sub { printUsageAndQuit(); }
			   , "delim|d=s" => \$delim
			   , "fast|faster|levonly!" => \$onlyCalculateLev
			   , "dp=i" => \$decimalPlaces
			   , "1=i" => \$colToReadInFile1 # <-- Given as "1 == first column". 0 is not valid.
			   , "2=i" => \$colToReadInFile2 # <-- Given as "1 == first column". 0 is not valid.
			   , "s|casesens!" => \$caseSensitive
			   , "cutoff|c=f"  => \$relativeCutoff
			  ) or printUsageAndQuit();


	if ($relativeCutoff > 1 || $relativeCutoff < 0) {
	  quitWithUsageError("Error in arguments! You cannot set a cutoff (-r CUTOFF) to less than 0 or to greater than 1.\n-r 0 means \"only display exact matches.\" -r 1 means \"output every match,\" and is currently the default value.\n");
	}

	if ($colToReadInFile1 <= 0 || $colToReadInFile2 <= 0) {
	  quitWithUsageError("Error in arguments! The column indices (specified with -1 and -2) cannot be less than 1.");
	}

	my $numUnprocessedArgs = scalar(@ARGV);
	if ($numUnprocessedArgs != 2) {
	  quitWithUsageError("Error in arguments! You must send TWO filenames to this program.\n");
	}

	my $filename1 = $ARGV[0];
	my $filename2 = $ARGV[1];

	for (my $i = 2; $i < scalar(@ARGV); $i++) { # these were arguments that were not understood by GetOptions and were ALSO not filenames
		print STDERR "Unprocessed argument: $_\n";
	}

	my $col1Index = ($colToReadInFile1 - 1);
	my $col2Index = ($colToReadInFile2 - 1);

	# Note: readFileColumn requires a column INDEX, starting from ZERO.

	my @col1 = @{readFileColumn($filename1, $col1Index, $delim)};
	@col1 = grep{!/^\s*$/} @col1;  # Filter out strings that are all whitespace!
	my @lowercaseCol1 = ($caseSensitive) ? undef : map(lc, @col1);
	
	my @col2 = @{readFileColumn($filename2, $col2Index, $delim)};
	@col2 = grep{!/^\s*$/} @col2;  # Filter out strings that are all whitespace!
	my @lowercaseCol2 = ($caseSensitive) ? undef : map(lc, @col2);

	my $whichCol1Pointer = ($caseSensitive) ? \@col1 : \@lowercaseCol1;
	my $whichCol2Pointer = ($caseSensitive) ? \@col2 : \@lowercaseCol2;

	# Prints to the terminal.
	print STDERR colorString("green");
	print STDERR "From file <$filename1>, we read " . scalar(@col1) . " values.\n"; # . join(", ",@col1) . "\n";
	print STDERR "From file <$filename2>, we read " . scalar(@col2) . " values.\n"; # . join(", ",@col2) . "\n";
	print STDERR "===============================\n";
	print STDERR colorResetString();

	#my $input = "ARR";
	#my @inputs = ("Arr", "Barr", "Parent", "Zombie", "pattern", "patt", "tern", "aappattern", "ppatternnnnn", "appatternfsfs", "123132", "x");

	#my $dist = adistr("p", "patterns");
	#print $dist . "\n";

	# Header Line
	print "Str1\tStr2\tlen(Str1)\tlen(Str2)\tEditDist\tDist/maxlen(Str1,Str2)";
	if (!$onlyCalculateLev) {
	  # These columns only get calculated if you do the FULL calculation,
	  # not the "lev-only" calculation.
	  print "\tDirectedDist\tRelativeDirectedDist";
	}
	print "\n";


	for (my $i = 0; $i < scalar(@{$whichCol1Pointer}); $i++) {
	  my $str1 = ${$whichCol1Pointer}[$i];
	  my $str1Length = length($str1);

	  next if ($str1Length == 0);

	  # These edit distances from String::Approx ARE directional!
	  my @directionalEditDists     = ($onlyCalculateLev) ? undef : String::Approx::adist($str1, @{$whichCol2Pointer});
	  my @relativeDirectionalDists = ($onlyCalculateLev) ? undef : String::Approx::adistr($str1, @{$whichCol2Pointer});
	  
	  my @levDists = Text::Levenshtein::distance($str1, @{$whichCol2Pointer}); # <-- this edit distance is non-directional!

	  for (my $j = 0; $j < scalar(@{$whichCol2Pointer}); $j++) {
		my $str2 = ${$whichCol2Pointer}[$j];
		my $str2Length = length($str2);
		
		next if ($str2Length == 0); # This should not happen, since grep should remove zero-length items above
		
		my $levDist = $levDists[$j];
		my $levFraction = $levDist / max($str1Length, $str2Length);

		if ($levFraction <= $relativeCutoff) {
		  # Ok, it makes the cutoff, so print this pair!
		  print $col1[$i];  # <-- Note: print the case-sensitive name under all circumstances
		  print "\t" . $col2[$j]; # <-- Note: print the case-sensitive name under all circumstances
		  print "\t" . $str1Length;
		  print "\t" . $str2Length;
		  print "\t" . $levDist;
		  print "\t" . sprintf("%.${numDecimalPointsToPrint}f", $levFraction);
		  if (!$onlyCalculateLev) {
			print "\t" . $directionalEditDists[$j];
			print "\t" . sprintf("%.${numDecimalPointsToPrint}f", $relativeDirectionalDists[$j]);
		  }
		  print "\n";
		}
	  }
	}

	print STDERR colorString("green");
	print STDERR "===============================\n";
	print STDERR "Done calculating edit distances\n";
	print STDERR colorResetString();
} # end main()


main();


END {
  # Runs after everything else.
  # Makes sure that the terminal text is back to its normal color.
  print colorResetString();
}

exit(0);
# ====

__DATA__

match_fuzzy.pl [OPTIONS]  FILENAME1   FILENAME2
by Alex Williams, 2009

"Fuzzy matching between strings"

If you want to automatically match a string like "Mitochondrial Cell
Metabolism" to "Mitochond. Cell Metab.", then you want to use this program.

Example: match_fuzzy.pl -c 0.3 file1 file2

This program takes in two columns of strings (one in each file), and outputs
the edit distance between each pair of items, as well as some other statistics.

The input files should be tab-delimited (although -d can override this) and
look like:

File1.tab:
porpoise           something    else   whatever
horse              a thing

File2.tab:
purpose          more_things     that do not matter
horseshoe crab

The output will only involve the first column from each file. (In this case, it
would indicate the number of changes required to turn the string "porpoise"
into "purpose", the number of changes from "porpoise"->"horseshoe crab",
"horse"->"purpose" and "horse"->"horseshoe crab".

The output columns give the strings being compared, the length of these
strings, the edit distance required to turn string 1 into string 2
(case-insensitively), and the number of edits required divided by the string
length. Additionally, "direction-dependent" edit distances are provided, which
depend on the order of specified strings. "horse"->"horseshoe crab" would have
a *directed* edit distance of 0 (the string "horse" is already in "horseshoe
crab"), but an un-directed edit distance of 9 (9 letters/spaces must be added).

See the examples below for more information.

CAVEATS:

Default is case-insensitive. Use --casesens to care about case.

Default prints out ALL pairs. So this is O(N*M) if N is the number of strings
in file1 and M is the number of strings in file2.

Use -c <THRESHOLD> to reduce this, or manually sort/filter later.

OPTIONS:

  -c CUTOFF   (Default: 1.0)
     Only print pairs of strings that are similar enough to make the cutoff.
     The cutoff is defined as: (edit_distance)/max(length(string1),
     length(string2)). -c 1.0 prints EVERY pair. -c 0.0 prints only perfect
     matches. -c 0.15 would print only strings that are pretty close, but not
     necessarily exact.

  --fast or --faster or --levonly
     Only calculate Levenshtein distance, do not output the other distances.
     Speeds things up if you only care about the Levenshtein edit distance.
     (Note: probably you can run this, since it is unlikely that you care about
     the extra columns).

  --casesens or -s (Default: OFF)
     Case-sensitive edit distances. By default, capitalization is disregarded,
     so ITEM and item are identical. But with --casesens, ITEM and item have an
     edit distance of 4 (4 changes required to turn ITEM into item or vice
     versa).

  -d DELIM or --delim = DELIMITER   (Default: tab)
     Sets the input delimiter to DELIMITER. For comma-separated, you would say
     -d ','

EXAMPLES:

Assuming that the first column of both FILE1 and FILE2 are strings that you
want to compare:
     Show only strings that are somewhat similar:
          match_fuzzy.pl -c 0.3   FILE1   FILE2   >   myOutputFile

     Same as above, but only care about the most important fields:
          match_fuzzy.pl -c 0.3  --faster  FILE1   FILE2   >   myOutputFile

     Show ALL information:
          match_fuzzy.pl  FILE1  FILE2

     Care about case, run faster and show only the most useful information:
          match_fuzzy.pl  --casesens  --faster  FILE1   FILE2

     Pipe in a file, then process it:
          cat FILE1 | sed 's/natl/national/g' | match_fuzzy.pl - FILE2  > OUTPUT


KNOWN BUGS:

  None known.

TO DO:

  No to-do items yet.

--------------
