#!/usr/bin/perl

##############################################################################
##############################################################################
##
## fill.pl - Removes "ragged" edges from a tab-delimited file by filling
##            in trailing blanks.
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

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-d', 'scalar',  "\t", undef]
                , [  '-pad', 'scalar',     0,     1]
                , [    '-i', 'scalar', undef, undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose  = not($args{'-q'});
my $delim    = $args{'-d'};
my $pad      = $args{'-pad'};
my $I        = $args{'-i'};
my $file     = $args{'--file'};
my $filling  = $args{'--extra'};
my @eaten;
my $max_cols = &maxCols($delim, $file, \@eaten);

$I = defined($I) ? $I - 1 : undef;

foreach $_ (@eaten)
{
   my $filled = &fill($max_cols, $filling, $pad, $delim, $_, $I);
   print $filled;
}

my $filep;
open($filep, $file) or die("Could not open file '$file' for reading");
while(<$filep>)
{
   my $filled = &fill($max_cols, $filling, $pad, $delim, $_, $I);
   print $filled;
}
close($filep);

exit(0);


__DATA__
syntax: fill.pl [OPTIONS] [FILL1 FILL2 ...] [FILE | < FILE]

FILLi: Fill the deficient empty columns with the string FILLi (default is blank).

OPTIONS are:

-q: Quiet mode (default is verbose)

-d DELIM: Set the field delimiter to DELIM (default is tab).

-pad: Just fix ragged edges, leave internal blanks alone.

-i I: Fill the space with the value that's in column I.



