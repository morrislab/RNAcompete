#!/usr/bin/perl

##############################################################################
##############################################################################
##
## condense.pl
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
require "$ENV{MYPERLDIR}/lib/libfunc.pl";

use strict;
use warnings;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-k', 'scalar',     1, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-h', 'scalar',     1, undef]
                , [    '-c', 'scalar',     2, undef]
                , ['--file', 'scalar',   '-', undef]
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
my $headers = $args{'-h'};
my $cols    = $args{'-c'};
my $file    = $args{'--file'};

my $passify = 100;

$key_col--;

my $filep;
open($filep, $file) or die("Could not open file '$file' for reading");
my $row = 0;
while(<$filep>)
{
   $row++;
   my @tuple = split($delim, $_);
   chomp($tuple[$#tuple]);
   my $key = splice(@tuple, $key_col, 1);
   print $key;
   while(scalar(@tuple) >= $cols)
   {
      my @x = splice(@tuple, 0, $cols);
      my $x = $row > $headers ? &evalFunction('mean', \@x) : $x[0];
      print $delim, (not(defined($x)) ? '' : $x);
   }
   if(scalar(@tuple) > 0)
   {
      my $x = $row > $headers ? &evalFunction('mean', \@tuple) : $tuple[0];
      print $delim, (not(defined($x)) ? '' : $x);
   }
   print "\n";

   $verbose and ($row % $passify == 0) and print STDERR "Condensed $row rows.\n";
}
close($filep);

exit(0);


__DATA__
syntax: condense.pl [OPTIONS]

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Compare the values in key_column COL to the threshold in the file (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines (default is 1).

-c COLS: Will condense COLS consecutive columns into one column.


