#!/usr/bin/perl

##############################################################################
##############################################################################
##
## rep.pl
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

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-f', 'scalar',     1, undef]
                , [    '-n', 'scalar',     2, undef]
                , [    '-c', 'scalar',     0, undef]
                , [    '-r', 'scalar',     0,     1]
                , [    '-d', 'scalar',  "\t", undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose   = not($args{'-q'});
my $col       = int($args{'-f'}) - 1;
my $num       = int($args{'-n'});
my $count_col = int($args{'-c'}) - 1;
my $rev       = $args{'-r'};
my $delim     = $args{'-d'};
my $file      = $args{'--file'};

my $filep;
open($filep, $file) or die("Could not open file '$file' for reading");
while(<$filep>)
{
   my @tuple = split($delim, $_);
   chomp($tuple[$#tuple]);
   my $item  = $tuple[$col];

   my $replicates = ($count_col >= 0 and $count_col <= $#tuple) ?
                       $tuple[$count_col] :
                       $num;

   for(my $i = 0; $i < $replicates; $i++)
   {
      print STDOUT "$item\n";
   }
}
close($filep);

exit(0);

__DATA__
syntax: rep.pl [OPTIONS]

OPTIONS are:

-q: Quiet mode (default is verbose)

-f COL: Replicate the data in field COL (default is 1).

-n NUM: Produce NUM replicates of each entry (default is 2).

-c COL: Use the counts from column COL to determine the number
        of replicates for each entry (default is undef since
        uses the same global number).  Note this overwrites
        any assignment given through the -n option.

-r: Do the reverse operation: Print the number of times an
    item appears consecutively (note this is different than
    unique because an item can appear multiple times in
    non-consecutive arrangement).

-d DELIM: Set the field delimiter to DELIM (default is tab).



