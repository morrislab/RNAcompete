#!/usr/bin/perl

##############################################################################
##############################################################################
##
## hyper_geometric.pl
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

use strict;

require "libfile.pl";
require "$ENV{MYPERLDIR}/lib/libstats.pl";

use strict;

my $verbose = 1;
my $k_col   = 1;
my $n_col   = 2;
my $K_col   = 3;
my $N_col   = 4;
my $delim   = "\t";
my @files;

while(@ARGV)
{
   my $arg = shift @ARGV;
   if($arg eq '--help')
   {
      print STDOUT <DATA>;
      exit(0);
   }
   elsif(-f $arg)
   {
      push(@files, $arg);
   }
   elsif($arg eq '-q')
   {
      $verbose = 0;
   }
   elsif($arg eq '-k')
   {
      $k_col = int(shift @ARGV);
   }
   elsif($arg eq '-n')
   {
      $n_col = int(shift @ARGV);
   }
   elsif($arg eq '-K')
   {
      $K_col = int(shift @ARGV);
   }
   elsif($arg eq '-N')
   {
      $N_col = int(shift @ARGV);
   }
   elsif($arg eq '-d')
   {
      $delim = shift @ARGV;
   }
   else
   {
      die("Invalid argument '$arg'");
   }
}

$k_col--;
$n_col--;
$K_col--;
$N_col--;

if($#files == -1)
{
   push(@files,'-');
}

foreach my $file (@files)
{
   my $filep;
   open($filep, $file) or die("Could not open file '$file' for reading");
   while(<$filep>)
   {
      my @tuple = split($delim, $_);
      chomp($tuple[$#tuple]);
      my ($k,$n,$K,$N) = ($tuple[$k_col],$tuple[$n_col],$tuple[$K_col],$tuple[$N_col]);
      my $pvalue = &ComputeLog10HyperPValue($k, $n, $K, $N);
      print "$pvalue\n";
   }
   close($filep);
}

exit(0);


__DATA__
syntax: hyper_geometric.pl [OPTIONS] < FILE

FILE has on each line:

k <tab> n <tab> K <tab> N

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: The column k is in (default is 1)

-n COL:

-K COL: The column K is in (default is 2)

-N COL:

-d DELIM: Set the field delimiter to DELIM (default is tab).


