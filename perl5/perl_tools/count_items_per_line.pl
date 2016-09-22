#!/usr/bin/perl

# By Alex Williams, July 2006
# alexgw@soe.ucsc.edu

# Input: pipe in a file
# Output: output to STDOUT the number of delimiters per line

use strict;
use Getopt::Long;

my $delimiter = "\t";
my $incrementAmt = 0;
my $printTitle = 0;

sub printUsage {
    print STDOUT <DATA>;
    exit(0);
}

GetOptions("help|?|man" => sub { printUsage(); }
	   , "delim|d:s" => \$delimiter
	   , "addamt|a:i" => \$incrementAmt
	   , "title|t" => sub { $printTitle = 1; }
	   ) or printUsage();


my $i = 1;
while (<>) {
    my $line = $_;
    my @lineArr = split(/$delimiter/, $line);
    my $numDelimiters = (scalar(@lineArr) - 1); #() = $line =~ /${delimiter}/g; # count how many delimiters are on this line

    if ($printTitle) {
	my $title = $lineArr[0];
	chomp($title); # just in case it was the only item in its row, so it has a newline
	print STDOUT $title . "\t"; # Note that $lineArr[1] is the FIRST element ([0] contains the entire string)
    }

    print STDOUT ($incrementAmt + $numDelimiters) . "\n";
    
    $i++;
}

exit(0);


__DATA__

count_items_per_line:
 Counts the number of items per line, AFTER the initial item, which is assumed to be a header for
 the row (although you can change that with -addamt=1) . Counts based on the delimiter on that line.

IMPORTANT NOTE:
  You may want to use "row_stats.pl -count" instead of this program!

Usage:
  count_items_per_line.pl [OPTIONS]  <FILE|STDIN>


Options:
 -d=DELIMITER or  --delim=DELIMITER   Default: tab
    Sets the column delimiter. Can be a regular expression, but make sure to format it properly.
    Uses the perl "split" command, so it can take any regular expression that split can understand.
    Normal usage example: -d=',' would count the number of items on a column-delimited file

 -a=NUMBER  or  --addamt=NUMBER   (Default: 0)   Short for "add amount"
    Adds NUMBER to each count, so you do not have to manually post-process the file.

 -t  or --title  (Default: do not print titles, just counts)
    Print the item title at the beginning of each line, then a tab, then the count of remaining items.

Q: If you are using this program, have you considered using row_stats.pl -count instead?
