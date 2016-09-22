#!/usr/bin/perl -w

# A program for printing ranking lines.
# By Alex Williams, 2007.

require "libfile.pl";
require "$ENV{MYPERLDIR}/lib/libstats.pl";

use POSIX qw(ceil floor); # import the ceil(ing) and floor functions for handling fractions/integers
use List::Util qw(max min); # import the max and min functions

use File::Basename;
use Getopt::Long;

use strict;
use warnings;
#use diagnostics;

no warnings 'redefine';

sub main();

sub printUsage() {
    print STDOUT <DATA>;
    exit(0);
}


sub readInputFile($$$) {
	# Note: reads GZipped and regular files
	# transparently (based on file extension)
	my ($filename) = @_;

	my $reader = undef;
	if ($filename =~ /\.gz$/) {
		$reader = 'zcat';
	} else {
		$reader = 'cat';
	}

	my $dat = `$reader $filename`; # <-- might be gzipped, hence $reader
	my @arr = split(/\n/, $dat);
	my @matrix = [];
	for (my $i = 0; $i < scalar(@arr); $i++) {
		my $lineStr = $arr[$i];
		chomp($lineStr);
	}

}

# ==1==

use constant DEFAULT_NUM_HEADERS => 0;
use constant kBLANK => '';
use constant kNA => 'NA';

use constant A_SORTS_HIGHER => -1;
use constant A_SORTS_LOWER  => 1;
use constant A_B_ARE_SAME   => 0;

sub my_sort_positive_to_top {
	# More positive values go to the top
	if (($a eq kBLANK) || ($a eq kNA)) {
		# Blank needs to always sort as the WORST
		if (($b eq kBLANK) || ($b eq kNA)) { return A_B_ARE_SAME; }
		else { return A_SORTS_LOWER; }
	} else {
		if (($b eq kBLANK) || ($b eq kNA)) { return A_SORTS_HIGHER; }
	}
	return ($a <=> $b);

}

sub my_sort_negative_to_top {
	# More negative values go to the top
	if (($a eq kBLANK) || ($a eq kNA)) {
		# Blank needs to always sort as the WORST
		if (($b eq kBLANK) || ($b eq kNA)) { return A_B_ARE_SAME; }
		else { return A_SORTS_LOWER; }
	} else {
		if (($b eq kBLANK) || ($b eq kNA)) { return A_SORTS_HIGHER; }
	}
	return (-1 * ($a <=> $b)); #  <-- note the -1 here! that's where we reverse it to make positives show up earlier!
}


sub main() { # Main program

	my ($delim) = "\t";
	my ($numHeaders) = DEFAULT_NUM_HEADERS;

	my ($sortColInput) = 1; # <-- where is the value we use to determine the rank of this row?
	my ($nameColInput) = undef;

	my ($reverse) = 0; # <-- 0 means "positive is better" (+Inf would be rank #1), 1 means "negative is better" (-Inf would be rank #1)
	
	my ($printValuesFirst) = 0;

    GetOptions("help|?|man" => sub { printUsage(); }
			   , "delim|d=s"  => \$delim
			   , "e=i"        => \$nameColInput
			   , "k=i"        => \$sortColInput
			   , "print_values_first|p!" => \$printValuesFirst
			   , "num_header_lines|h=i" => \$numHeaders   # <-- default: 0
			   , "negative_is_better|reverse|r" => sub { $reverse = 1; } # <-- note: blanks always do worst, no matter what
			   ) or printUsage();

	my $sortValueCol = ($sortColInput - 1); # the actual INDEX is one less than what the user puts in (the user starts counting at 1, we start at 0)
	my $nameCol = (defined($nameColInput)) ? ($nameColInput - 1) : undef;

	if ($sortValueCol < 0) {
		die "You passed in a sort column index of $sortColInput. This is invalid... the first valid input is -k 1, for the leftmost column.\n";
	}

	if (defined($nameCol) && $nameCol < 0) {
		die "You passed in a name column index of $nameColInput. This is invalid... the first valid input is -e 1, for the leftmost column.\n";
	}

	if (defined($nameCol) && $nameCol == $sortValueCol) {
		print STDERR "Warning: you specified the same columns for the sort value (-k) as for the item key (-e). This will result in weird reults. You probably don't want to do this.\n";
	}

	my @allValueLines = ();
	my %dhash = (); # keeps track of all the lines with the given value (first key is the name, secondkey is the sort value, value is an array of all the rows with this value)

	for (my $linesRead = 0; my $line = <>; $linesRead++) {
		# let's see if we should be reading the header line
		if ($linesRead < $numHeaders) {
			# Looks like we need to read some header lines...
			if ($printValuesFirst) {
				print "VALUE" . "\t"; # more goes on the header line...
			}
			print "BEST_RANK" . "\t" . "AVG_RANK" . "\t" . "PERCENTILE" . "\t" . $line; # Just print the header lines out directly
			next;
		}

		# ok, we read all the header lines we needed to
		chomp($line);
		my @larr           = split($delim, $line); # <-- @larr is the line as an *array*
		my $value          = (defined($larr[$sortValueCol])) ? $larr[$sortValueCol] : kBLANK;
		my $nameOfThisItem = (defined($nameCol) && defined($larr[$nameCol])) ? $larr[$nameCol] : '';
		
		if (($value ne kBLANK) && ($value ne kNA) && (not ($value =~ /^[-+0-9.eE,]+$/))) { die "rank_items.pl: ERROR IN INPUT FILE (Exiting program): It looks like the item in column $sortValueCol at line " . ($linesRead+1) . " (\"$value\") was not a number!\nYou can only use numbers and blanks in this ranking! (Blanks sort to the bottom--worst--spot). You should change all NA or ND or NaN values to either the literal string NA, or to blank entries before you run rank_items.pl\n"; }
		
		if (!defined($dhash{$nameOfThisItem}) || !defined($dhash{$nameOfThisItem}{$value})) {
			@{$dhash{$nameOfThisItem}{$value}} = ();
		}
		# dhash gives the index in @allValueLines where we'll find the corresponding line
		my $whichIndexToFindThisLineAt = scalar(@allValueLines);
		#print "Adding $nameOfThisItem : $value to the list\n";
		push(@{$dhash{$nameOfThisItem}{$value}}, $whichIndexToFindThisLineAt);
		push(@allValueLines, $line); # <-- NON-EMPTY value
	} # done reading...
	
	foreach my $nameKey (keys(%dhash)) {
		my @sortedValues =
			($reverse)
			? sort my_sort_positive_to_top (keys(%{$dhash{$nameKey}}))
			: sort my_sort_negative_to_top (keys(%{$dhash{$nameKey}}));
		
		#print "Num items is $totalItemsForThisName for key $nameKey\n";
		#print "Num items is " . scalar(@sortedValues) . " for key sortedvalues\n";

		my $totalItemsForThisName = 0;
		foreach my $v (@sortedValues) {
			$totalItemsForThisName += scalar(@{$dhash{$nameKey}{$v}});
		}

		my $rank = 1;
		foreach my $v (@sortedValues) {
			my $numItemsWithThisRank = scalar(@{$dhash{$nameKey}{$v}});
			foreach my $aLineIndex (@{$dhash{$nameKey}{$v}}) {
				my $lineThatWasAtIndex = $allValueLines[$aLineIndex];
				my $avgRank  = ($rank + $rank + $numItemsWithThisRank - 1) / 2;
				my $percentile = (( 1 - ( ($rank-1)/$totalItemsForThisName ) )) * 100;
				# percentile: percent of rows that are <= this rank (100 = best)
				if ($printValuesFirst) {   print $v . "\t";   }
				print $rank . "\t" . $avgRank . "\t" . sprintf("%.3f", $percentile) . "\t" . $lineThatWasAtIndex . "\n";
			}
			$rank += $numItemsWithThisRank;
		}
	}

} # end main()


main();
exit(0);
# ====

__DATA__

rank_items.pl -k KEYCOLUMN (-e ITEM_NAME_COLUMN)  [OPTIONS]  FILENAME
or cat FILENAME | rank_items.pl [OPTIONS]

You give this a file, and it sorts the file by the key
and then prints out the results in order, along with
their ranks. Items with a blank key field, ND, or NA are sorted to the bottom.

You can OPTIONALLY add an "-e COL_NUMBER" parameter to separately
sort items by the string in this column. For example, if you had
100 different experiments in a single file, you could find the top
results for *each* experiment this way, instead of splitting the
file up into 100 separate files first.


The file is printed out with the following additional 3 columns:
  BEST_RANK    AVG_RANK     PERCENTILE      (REMAINDER OF ROW)
(See below for descriptions of what each of these means.)

If the file has a header (specify with -h NUMBER),
then the original header is modified to add these three items.

Example Usage:

 If you have a tab-delimited file that looks like:
  USA      42    21    8
  Japan    32    13    12
  China    40    30    18
  Russia   30    13    8

Then you could sort AND rank the items by, for example,
the fourth column (the last one, in this example), by saying:
  cat YOUR_INPUT_FILE | rank_items.pl -k 4

And the output will give you the percentiles and ranks for
each item, based on the 8, 12, 18, 8 column. You can see
how ties are broken with this example, or by reading
the "average rank" vs "best rank" discussion below.

Note that this program is not the same as "nums.pl" or just
adding line numbers! This program gives *tied* items
the same rank, and prints out percentiles!

This program is similar to count_ranks.pl.

Description of Ranks & Percentile:

Average Rank: (AVG_RANK)
	This means that tied ranks get the average of those ranks.
	This is *not* how sports work--this means if three people tied for
	first place, then they would all get awarded second place,
	and the next person would get fourth place.
  Example: values:  90   80   70   70   60   60   60   60   40
    are ranked as:  1    2   3.5  3.5  6.5  6.5  6.5  6.5   9

Best Rank: (BEST_RANK)
	This means that tied ranks get the best rank, but then the next
	rank skips. This is how some sports work--two people can get first
	place, then the next-best person gets third place.
  Example: values:  90   80   70   70   60   60   60   60   40
    are ranked as:  1    2    3    3    5    5    5    5    9

Percentile:
	Print out percentile instead of direct rank. So instead
	of "rank 1" being printed out, we would print out
	"100th percentile". Percentile tells
	us what percentage of items this item was
	ranked better than **or equal to**. The best rank will
	always be 100th percentile. In a file where everything has
	the same rank, EVERY item will be 100th percentile.
	No items will ever be exactly 0th percentile, because an
	item is always ">=" to itself.

Options:

-d DELIMITER  or  --delim=DELIMITER:   (default: tab)
	Set the between-columns delimiter.

-p or --print_values_first:  (default: OFF)
	If specified, this flag causes the sorted-by value
	to be printed at the beginning of the output line,
	before the ranks and percentiles.

-k COL_NUMBER:   (default: 1)
	Specify which column has the sort key. (The sort
    key is the value that is used to rank the rows.)
	Starts counting from 1 (1 is the leftmost column).

-e COL_NUMBER:   (OPTIONAL)
	Specify which column has the "item name" key.
	If you specify this, then the input file is divided
	up by the string in this column, and the results are
	sorted and printed completely independently. This gives the
	same effect as cutting up the input file based on the string
	in COL_NUMBER and passing the pieces to rank_items.pl
	separately.

-h NUMBER  or  --num_header_lines=NUMBER:   (default: 0)
	Specify how many header lines are in the input file.
	Header lines are printed out before the output. Note
	that we add a "RANK" column header so that the header
	lines up with the final output.

-r  or  --negative_is_better  or  --reverse:  (OFF by default)
	Indicate that *negative* values are of better (lower)
	rank. So -999 might be rank 1, then 400 would be rank 2.
	A blank line would still be rank 3, just as it is without
	the reverse option.
	Blank/NA sort keys always sort to the end (worst)
	rank no matter what, even when -r is specified.
    Note that NA is a special value that acts like a blank entry.

