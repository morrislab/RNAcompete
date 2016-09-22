#!/usr/bin/perl

##############################################################################
##############################################################################
##
## set_diff.pl
##
##############################################################################
##############################################################################
##
## Written by Josh Stuart in the lab of Stuart Kim, Stanford University.
##
##  Email address: jstuart@stanford.edu
##          Phone: (650) 725-7612
##
## Postal address: Department of Developmental Biology
##                 Beckman Center Room B314
##                 279 Campus Dr.
##                 Stanford, CA 94305
##
##       Web site: http://www.smi.stanford.edu/people/stuart
##
##############################################################################
##############################################################################
##
## Written: 00/00/02
## Updated: 00/00/02
##
##############################################################################
##############################################################################

require "libfile.pl";
require "$ENV{MYPERLDIR}/lib/libset.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-k', 'scalar',     1, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-h', 'scalar',     1, undef]
                , [    '-m', 'scalar',     1, undef]
                , ['--file',   'list', ['-'], undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose = not($args{'-q'});
my $key_col = $args{'-k'};
my $delim   = $args{'-d'};
my $mem_val = $args{'-m'};
my $headers = $args{'-h'};
my @files   = @{$args{'--file'}};

scalar(@files) == 2 or die("Please supply exactly 2 files");

$key_col--;

$verbose and print STDERR "Reading in first set of sets from '$files[0]'...";
my $sets1 = &setsReadTable($files[0], $mem_val, $delim, $key_col, $headers);
$verbose and print STDERR " done.\n";

$verbose and print STDERR "Reading in second set of sets from '$files[1]'...";
my $sets2 = &setsReadTable($files[1], $mem_val, $delim, $key_col, $headers);
$verbose and print STDERR " done.\n";

$verbose and print STDERR "Taking the difference between two...";
my $diffs = &setsDifference($sets1, $sets2);
$verbose and print STDERR " done.\n";

$verbose and print STDERR "Printing out the result...";
&setsPrintMatrix($diffs, \*STDOUT);
$verbose and print STDERR " done.\n";

exit(0);


__DATA__
syntax: set_diff.pl [OPTIONS] FILE1 FILE2

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Compare the values in key_column COL to the threshold in the file (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-m MEM: Set the value that indicates membership to MEM (default is 1).

-h HEADERS: Set the number of header lines to HEADERS (default is 1).

