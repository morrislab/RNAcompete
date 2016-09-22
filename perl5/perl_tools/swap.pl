#!/usr/bin/perl

##############################################################################
##############################################################################
##
## swap.pl
##
##############################################################################
##############################################################################
##
## Written by Josh Stuart.
##
##  Email address: jstuart@ucsc.edu
##          Phone: (650) 725-7612
##
## Postal address: Department of Bioengineering, UCSC
##                 1156 High Street
##                 Santa Cruz, CA 95060
##
##       Web site: http://www.soe.ucsc.edu/~jstuart/
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
                , [    '-k', 'scalar', '1,2', undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-1', 'scalar', undef, undef]
                , [    '-2', 'scalar', undef, undef]
                , [   '-or', 'scalar',     0,     1]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose    = not($args{'-q'});
my $col        = $args{'-k'};
my $delim      = $args{'-d'};
my $condition1 = $args{'-1'};
my $condition2 = $args{'-2'};
my $or         = $args{'-or'};
my $file       = $args{'--file'};

my @cols = split(',', $col);
for(my $i = 0; $i < @cols; $i++) { --$cols[$i]; }

my $filep;
open($filep, $file) or die("Could not open file '$file' for reading");
while(<$filep>)
{
   my @tuple = split($delim, $_);
   chomp($tuple[$#tuple]);
   my $item1  = $tuple[$cols[0]];
   my $item2  = $tuple[$cols[1]];

   my $result = 0;
   if($or)
   {
      $result = (&isTrue($item1, $condition1) or &isTrue($item2, $condition2)) ? 1 : 0;
   }
   else
   {
      $result = (&isTrue($item1, $condition1) and &isTrue($item2, $condition2)) ? 1 : 0;
   }
   if($result)
   {
      $tuple[$cols[0]] = $item2;
      $tuple[$cols[1]] = $item1;
   }
   print STDOUT join($delim, @tuple), "\n";
}
close($filep);

exit(0);

__DATA__
syntax: swap.pl [OPTIONS]

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL1,COL2: Swap columns 1 and 2 if the condition is met (default 1 and 2)

-d DELIM: Set the field delimiter to DELIM (default is tab).

-1 CONDITION: Apply the condition to the value in the first column.  Swap if the
              condition is true.

-2 CONDITION: Same as -1 but apply to column 2.

-or: Logically OR the results of testing 1 and 2 (default is AND).


