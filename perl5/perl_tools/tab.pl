#!/usr/bin/perl

##############################################################################
##############################################################################
##
## tab.pl - Make a table
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
                , [    '-n', 'scalar',     2, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-h', 'scalar',     0, undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose  = not($args{'-q'});
my $num_cols = $args{'-n'} - 1;
my $delim    = $args{'-d'};
my $headers  = $args{'-h'};
my $file     = $args{'--file'};

my $line_no = 0;
my $i = 0;
my $filep = &openFile($file);
while(<$filep>)
{
   $line_no++;

   if($line_no > $headers)
   {
      my @x = split($delim);
      chomp($x[$#x]);
      foreach my $x (@x)
      {
         $i++;
         print STDOUT $x, ($i % $num_cols == 0 ? "\n" : "\t");
      }
   }
}
close($filep);

exit(0);


__DATA__
syntax: tab.pl [OPTIONS] [FILE | < FILE]

OPTIONS are:

-q: Quiet mode (default is verbose)

-n COLS: Set the number of columns to COLS (default is 2).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Skip the first HEADERS lines in the input file.


