#!/usr/bin/perl -w

# This perl script takes in a matrix, and outputs pairwise stuff.

# Sets.pl can't do this... it only does binary values. But this SHOULD be rolled into
# sets.pl eventually!

# In other words:
# start with:

# NAME   x   y
#  A    0.4 0.6
#  B    0.1 0.7

# And the output (in some order, not guaranteed to be any particular order) is:

# A x 0.4
# A y 0.6
# B x 0.1
# B y 0.7

# Alex Williams

require "libfile.pl";
require "libstats.pl";

use POSIX qw(ceil floor); # import the ceil(ing) and floor functions for handling fractions/integers
#use List::Util qw(max min); # import the max and min functions

use strict;
use warnings;

use File::Basename;
use Getopt::Long;

sub main();

sub printUsage() {
    print STDOUT <DATA>;
    exit(0);
}

my (%mat) = (); # the main matrix where all the data will go

my ($DEBUG) = 0;
# ==1==
sub main() { # Main program
    my ($delim) = "\t";
    
	my ($keyCol) = 1; # Default is 1. Counts from 1 and not 0
	my ($headerRow) = 1; # default is 1. Counts from 1 and not 0
	my ($verbose) = 1; # default is to report stuff. Turn it off with -q or --quiet

	GetOptions("help|?|man" => sub { printUsage(); }
			   , "delim|d=s" => \$delim
			   , "keycol|k=i" => \$keyCol
			   , "header|h=i" => \$headerRow
			   , "debug!" => \$DEBUG
			   , "q|quiet" => sub { $verbose = 0; }
			   ) or printUsage();
	

	my @file = <>;

	my $headerIndexFromZero = $headerRow - 1;
	my $keyIndexFromZero = $keyCol - 1;
	
	chomp($file[$keyIndexFromZero]); # strip "\n"s
	my (@header) = split(/$delim/, $file[$keyIndexFromZero]);

	for (my $r = ($keyIndexFromZero+1); $r < scalar(@file); $r++) {
		chomp($file[$r]); # strip "\n"s
		my @lar = split(/$delim/, $file[$r]);

		my $thisRowKey = $lar[$keyIndexFromZero];

		for (my $c = $keyCol+1; $c < scalar(@lar); $c++) {
			my $thisColHeader = $header[$c];
			my $thisCellValue = $lar[$c];

			if ($DEBUG) { print "Debug: got " . $thisRowKey . "\t" . $thisColHeader . "\t" . $thisCellValue . "\n"; }
			
			if (exists($mat{$thisRowKey}{$thisColHeader})
				&& defined($mat{$thisRowKey}{$thisColHeader})) {
				if ($verbose) { print STDERR "Note: Read in multiple entries for ($thisRowKey, $thisColHeader).\n"; }
				#print STDERR "We read in $thisRowKey and $thisColHeader another time. Basically this means we read something like DRUG and GENE1 in one file, and then DRUG and GENE1 elsewhere in the same file later on. We are adding an index like (2), (3), etc to the COLUMN HEADER of the second/3rd/etc ones.\n";
			} else {
				$mat{$thisRowKey}{$thisColHeader} = ();
			}
			push(@{$mat{$thisRowKey}{$thisColHeader}}, $thisCellValue);
		}
	}


	foreach my $rkey (keys(%mat)) {
		foreach my $ckey (keys(%{$mat{$rkey}})) {
			my @thisArr = @{$mat{$rkey}{$ckey}};
			foreach my $elem (@thisArr) {
				print $rkey . "\t" . $ckey . "\t" . $elem;
				print "\n";
			}
		}
	}

} # end main()






main();
exit(0);
# ====

__DATA__

my program.pl

Info not yet filled in

Better read the source for help...
