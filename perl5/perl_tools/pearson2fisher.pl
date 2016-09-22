#!/usr/bin/perl

##############################################################################
##############################################################################
##
## pearson2fisher.pl
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
require "$ENV{MYPERLDIR}/lib/libstats.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-f', 'scalar',     1, undef]
                , [  '-dim', 'scalar',     2, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-n', 'scalar', undef, undef]
                , [    '-h', 'scalar',     0, undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose    = not($args{'-q'});
my $field      = $args{'-f'} - 1;
my $delim      = $args{'-d'};
my $headers    = $args{'-h'};
my $dimensions = $args{'-n'};
my $dim_col    = $args{'-dim'} - 1;
my $file       = $args{'--file'};
my @extra      = @{$args{'--extra'}};

my $line_no = 0;
my $filep = &openFile($file);
while(<$filep>)
{
   $line_no++;
   if($line_no > $headers)
   {
      my @x = split($delim);
      chomp($x[$#x]);
      my $val = $x[$field];
      my $dim = defined($dimensions) ? $dimensions : $x[$dim_col];
      my $z   = &Pearson2FisherZscore($val, $dim);
      print "$z\n";
   }
   else
   {
      print;
   }
}
close($filep);

exit(0);


__DATA__
syntax: pearson2fisher.pl [OPTIONS] [FILE | < FILE]

OPTIONS are:

-q: Quiet mode (default is verbose)

-f COL: Set the column from which to read the pearson correlation (default 1)

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 0).

-n DIMENSIONS: Set the dimensions for the entire file to DIMENSIONS.

-dim COL: Set the column from which to read the dimension (default is 2).




