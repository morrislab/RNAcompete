#!/usr/bin/perl

##############################################################################
##############################################################################
##
## integrate.pl
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
require "$ENV{MYPERLDIR}/lib/libmath.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-h', 'scalar',     0, undef]
                , [    '-i', 'scalar', undef, undef]
                , [    '-m', 'scalar',     5, undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose   = not($args{'-q'});
my $delim     = $args{'-d'};
my $headers   = $args{'-h'};
my $intervals = $args{'-i'};
my $multiple  = $args{'-m'};
my $file      = $args{'--file'};

my $line_no = 0;
my $filep = &openFile($file);
my @X;
my $min_y = undef;
while(<$filep>)
{
   $line_no++;
   if($line_no > $headers)
   {
      my @x = split($delim);
      chomp($x[$#x]);
      push(@X, \@x);

      if(not(defined($min_y)) or abs($x[1]) < $min_y)
      {
         $min_y = abs($x[1]);
      }
   }
}
close($filep);

my $n = scalar(@X);

$intervals = defined($intervals) ? $intervals : $n * $multiple;

my $area = &integrate(\@X, $intervals);

print STDOUT "$area\n";

$verbose and print STDERR "Area = $area\n";

exit(0);

__DATA__
syntax: integrate.pl [OPTIONS] [FILE | < FILE]

Computes the integral under the curve supplied in the file.  FILE
should contain an n-dimensional a vector on each line.

OPTIONS are:

-q: Quiet mode (default is verbose)

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 0).

-i INT: Set the number of intervals to INT (default is 5 * number of vectors).

-m MUL: Same as -i only sets the number of intervals as a multiple of the number of
        supplied vectors (default is 5).



