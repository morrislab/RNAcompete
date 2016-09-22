#!/usr/local/bin/perl

##############################################################################
##############################################################################
##
## fasta2single_line.pl
##
## Fasta to one line: turns the lines from normal fasta format:
## >SOMETHING
## blah blah
## more blah
## blah 2 3 4
## something else
##
## Into a set of lines like:
## SOMETHING  blah blah
## SOMETHING  more blah
## SOMETHING  blah 2 3 4
## SOMETHING  something else
##
## This way you can sort them afterward.
##
##  Alex Williams
##############################################################################
##############################################################################


use warnings;
use strict;

use Getopt::Long;

my $caretGuy = undef;
my $delim = qq{\t}; # default delimiter is the TAB

GetOptions("help|man|?", sub { print STDOUT <DATA>; exit(0); }
		   , "d|delim=s", \$delim,
		   );

my $numPrintedForThisCaret;

while (my $line = <>) {
    if (($line) =~ m/^>(.*)/) {

	if (defined($caretGuy) && ($numPrintedForThisCaret == 0)) {
	    print $caretGuy . "\n"; # <-- we want to print out just the blank fasta line in the event that it has no description below it
	    # This takes care of situations like this following sample fasta file:
	    ### >ONE
	    ### >TWO
	    ### alpha beta
	    ### beta alpha
	    ### >THREE
	    # Otherwise, ONE and THREE will just not be printed out at all.
	}

	# Match the >SOMETHING line. We want to capture "SOMETHING" into $1
	$caretGuy = $1; # <-- "caretguy" is the text following the caret, on the same line
	$numPrintedForThisCaret = 0; # reset the count
	# Note that we don't print out this header line, so the final file doesn't have these anymore.
    } else {
		if (defined($caretGuy)) {
			# Prints the header, then the delimiter, then whatever was on this line previously
			print $caretGuy . $delim . $line;
			$numPrintedForThisCaret++;
		}
    }
}


__DATA__

fasta2single_line.pl:

This is primarily used for formatting sets_overlap.pl output. It does the following:

It turns these fasta-format lines:
 >SOMETHING
 blah blah
 more blah
 blah 2 3 4
 something else

Into a set of lines like this, where the set name appears on every line:
 SOMETHING  blah blah
 SOMETHING  more blah
 SOMETHING  blah 2 3 4
 SOMETHING  something else

 This way you can easily sort them afterward.

Usage:

One common usage is:
 sets_overlap.pl -dot -p 1 SETFILE1 SETFILE2 | fasta2single_line.pl > OUTPUT_FILE

Options:

 -d=DELIMITER  or  --delim=DELIMITER (default: <tab>)
  For example,  -d ','   or   -d 'x'   sets the delimiter to comma or x, respectively.
  Note that this *only* sets the new delimiter between the fasta header and the rest
  of the lines, and not any delimiters that may already exist in the fasta file.

