#!/usr/bin/perl -w

require "libfile.pl";
require "$ENV{MYPERLDIR}/lib/libstats.pl";
require "$ENV{MYPERLDIR}/lib/libstring.pl";

use POSIX qw(ceil floor); # import the ceil(ing) and floor functions for handling fractions/integers
use List::Util qw(max min); # import the max and min functions
use Term::ANSIColor;

use strict;
use warnings;
use diagnostics;

use File::Basename;
use Getopt::Long;

sub main();

sub printUsage() {
    print STDOUT <DATA>;
    exit(0);
}

# ==1==
sub main() { # Main program

	my ($delim) = "\t";
	my ($dittoChar) = "\"";
	my ($separateItemsWithNewline) = 0; # <-- should we put newlines between ditto-marked different items?
	my ($fieldInput) = undef; # Which columns (fields) should we operate on? (format string)
	my ($undo) = 0; # Should we UNDO the ditto-marking? Note that this is a "best guess" and is not always possible if the ditto mark is sometimes also a real data value.
    GetOptions("help|?|man" => sub { printUsage(); }
			   , "d|delim=s" => \$delim
			   , "f=s"       => \$fieldInput
			   , "sep!"      => \$separateItemsWithNewline
			   , "m|mark=s"  => \$dittoChar   # actually could be a whole string, not just a char
			   , "undo"      => sub { $undo = 1; }
	       ) or printUsage();

	# --sep is currently not implemented!

	#print STDERR "Unprocessed by Getopt::Long\n" if $ARGV[0];
	#foreach (@ARGV) {
	#	print STDERR "$_\n";
	#}

	my $lineNum = 0;
	my @prevRow = undef;
	my $prev_cols = 0;
	my @cols; # which columns to operate on
	my %colHash = (); # which columns to operate on
	while (my $line = <>) {
	  chomp($line);

	  my @thisRow = split(/$delim/, $line);
	  
	  # Figure out which columns to operate on (or just do all of them)
	  if(defined($fieldInput)) {
		my $num_cols = scalar(@thisRow);
		if($num_cols != $prev_cols) {
		  # If there is a different number of columns on this line, then
		  # re-parse the ranges! (to handle -1 properly, and things like that)
		  @cols = &parseRanges($fieldInput, $num_cols, -1);
		  foreach my $i (@cols) {
			$colHash{$i} = 1; # sets up the hash
		  }
		}
		$prev_cols = $num_cols;
	  }


	  if ($lineNum == 0) {
		# Never operate on the very first line in a file.
		# It cannot be a "dittoed" item, because there was nothing before it.
		print STDOUT $line;

	  } else {
		my $numDittoedItemsThisLine = 0;

		my $colIndex = 0;
		foreach my $elem (@thisRow) {
		  if ($colIndex > 0) {
			print STDOUT $delim;
		  }

		  my $elemAbove = $prevRow[$colIndex];

		  if ($undo) { # <-- we are UNDOING the ditto operation
			if ($elem eq $dittoChar) {
			  # Restore this item to its pre-dittoed state.
			  $elem = $elemAbove;
			}
		  }

		  if (!$undo
			  && defined($elemAbove)
			  && ($elem eq $elemAbove)
			  && (!defined($fieldInput) ||
				  (exists($colHash{$colIndex}) && $colHash{$colIndex}))
			 ) {
			print STDOUT $dittoChar;
		  } else {
			print STDOUT $elem;
		  }
		  $colIndex++;
		}
	  } # <-- end of "for each element on this row..."

	  # For every line, we do these things no matter what...
	  print STDOUT "\n";
	  @prevRow = @thisRow; # Remember this row...
	  $lineNum++;
	} # <-- end of "for each line..."

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

ditto_mark.pl [OPTIONS] < STDIN

Alex Williams, 2008

Replaces two *consecutive* instances of the same value in the same column with a ditto mark.

Can *usually* be undone with the --undo flag (see CAVEAT section).

See the examples below.

CAVEATS:

 * "Undo" will not work if your ditto character is also a valid value (all by itself)
   for a cell in a column that is operated on.

OPTIONS:

-d DELIM or --delim=DELIM  (default: tab)
  Sets the column delimiter.

-m or --mark=STRING  (default: double quote mark)
  Sets the mark that indicates that a field is the same as the one above.

-f RANGES: specify column ranks to include. Default: ALL columns operated on.
           RANGES are comma-separated lists of single columns or a range of columns
           for example:

                   5-6,2,1-3

           would select columns 1 through 6 except column 4.  Note
           that 2 is redundantly specified, but no error results.

           If RANGES is a file, then cut.pl reads in the ranges from the given
           file. Each line is treated as a seperate range if multiple lines
           are given.

           Should work with negatives (counts from the end of the list instead).


--undo
   Does the opposite of normal execution, restoring a file to its pre-dittoed state.
   This will succeed *unless* the ditto character is also a valid data value that
   appears alone by itself in a cell.

EXAMPLES:

If you have a file like this:
ALPHA,1,1,2,3
ALPHA,2,4,5,1
BETA ,2,1,3,4
BETA ,4,1,5,1

Then you can say

ditto_mark.pl -d ',' -m 'SAME' THE_FILE

And the output will be:
ALPHA ,    1,    1,  2,  3
SAME  ,    2,    4,  5,  1
BETA  , SAME,    1,  3,  4
SAME  ,    4, SAME,  5,  1

As seen above, "SAME" is probably not a very good choice as a mark.
The default is a more-noticeable double-quote (\").

If you want to UNDO ditto-marking, run ditto_mark.pl with the --undo flag.

For example:
ditto_mark.pl FILE | ditto_mark.pl --undo FILE
will result in the original file... but ONLY as long as the ditto mark character 
  only appears alone in a cell as a result
  of ditto_mark.pl. If the ditto character is a valid data cell, then you will get
  different (and incorrect) results. This is one reason you should use a unique
  character for the ditto character.

KNOWN BUGS:

  None known.

TO DO:

--------------
