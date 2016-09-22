#!/usr/bin/perl

##############################################################################
##############################################################################
##
## overlaps.pl
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

require "$ENV{MYPERLDIR}/lib/libset.pl";
require "$ENV{MYPERLDIR}/lib/libstats.pl";

use strict;

my $verbose  = 1;
my $headers1 = 0;
my $headers2 = 0;
my $col1     = 1;
my $col2     = 1;
my $delim1   = "\t";
my $delim2   = "\t";
my $N        = undef;
my $pval     = 0;
my $names    = 0;
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
   elsif($arg eq '-h1')
   {
      $headers1 = int(shift @ARGV);
   }
   elsif($arg eq '-h2')
   {
      $headers2 = int(shift @ARGV);
   }
   elsif($arg eq '-h')
   {
      $headers1 = int(shift @ARGV);
      $headers2 = $headers2;
   }
   elsif($arg eq '-k1')
   {
      $col1 = int(shift @ARGV);
   }
   elsif($arg eq '-k2')
   {
      $col2 = int(shift @ARGV);
   }
   elsif($arg eq '-k')
   {
      $col1 = int(shift @ARGV);
      $col2 = $col1;
   }
   elsif($arg eq '-d1')
   {
      $delim1 = shift @ARGV;
   }
   elsif($arg eq '-d2')
   {
      $delim2 = shift @ARGV;
   }
   elsif($arg eq '-d')
   {
      $delim1 = shift @ARGV;
      $delim2 = $delim1;
   }
   elsif($arg eq '-pval')
   {
      $pval = 1;
   }
   elsif($arg eq '-names')
   {
      $names = 1;
   }
   elsif($arg eq '-N')
   {
      $N = shift @ARGV;
   }
   else
   {
      die("Invalid argument '$arg'");
   }
}

$col1--;
$col2--;

(scalar(@files) == 2) or die("Please supply two (use - for standard input).");

my $set1         = &setRead($files[0], $delim1, $col1);

my $set2         = &setRead($files[1], $delim2, $col2);

my $intersection = &setIntersection($set1, $set2);

my $size1        = &setSize($set1);

my $size2        = &setSize($set2);

my $overlaps     = &setSize($intersection);

my $frac1        = $overlaps / $size1;

my $frac2        = $overlaps / $size2;

if($names)
{
   print STDOUT "$files[0]\t$files[1]\t";
}

print STDOUT "$overlaps\t$size1\t$size2\t$frac1\t$frac2";

if($pval)
{
   $N = not(defined($N)) ? &setSize(&setUnion($set1, $set2)) : $N;

   my $pvalue = &ComputeLog10HyperPValue($overlaps, $size1, $size2, $N);
   $pvalue = not(defined($pvalue)) ? 0 : $pvalue;

   print STDOUT "\t$pvalue";
}

print STDOUT "\n";

exit(0);


__DATA__
syntax: overlaps.pl [OPTIONS] FILE1 FILE2

Reports the overlap between the sets read from FILE1 and FILE2.  The output
returned is:

OVERLAP <tab> SIZE1 <tab> SIZE2 <tab> FRAC1 <tab> FRAC2 [<tab> P-VALUE]

where OVERLAP is the number of elements in common between the two sets, 
SIZE1 and SIZE2 are the sizes of the sets read in, FRAC1 and FRAC2
is equal to SIZE1/OVERLAP and SIZE2/OVERLAP respectively.  The last optional
output is the hypergeometric p-value of getting the observed number of
overlapping elements or more by chance (see the -pval flag).  The
hypergeometric computation assumes the size of the entire population is
equal to the size of the union of the two sets unless a size is provided
using the -N flag.

OPTIONS are:

-q: Quiet mode (default is verbose)

-pval: Report the log base-10 hypergeometric pvalue associated with the overlap.

-N SIZE: Set the population size to SIZE (default assumes the union of the two
         sets is the total population).

-names: Include the file names with the output.  The output would then be:

Note: the following options can be appended with either 1 or 2 to
      specify the option only for FILE1 or FILE2 singly.

-k COL:  Extract elements for both FILE1 and FILE2 from COL.

-d DELIM: Set the field delimiter to DELIM (default is tab).

FILE1 <tab> FILE2 <tab> OVERLAP <tab> SIZE1 ...


