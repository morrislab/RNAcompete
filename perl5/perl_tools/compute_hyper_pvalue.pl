#!/usr/bin/perl

##############################################################################
##############################################################################
##
## compute_hyper_pvalue.pl
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

my @flags = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-l', 'scalar',     0,     1]
                , [    '-s', 'scalar', undef, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-k', 'scalar',     1, undef]
                , [    '-n', 'scalar',     2, undef]
                , [    '-K', 'scalar',     3, undef]
                , [    '-N', 'scalar',     4, undef]
                , ['--file', 'scalar', undef, undef]
            );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}
my $file            = $args{'--file'};
my $delim           = $args{'-d'};
my $take_log        = $args{'-l'};
my $sigdig          = $args{'-s'};
my $sample_succ_col = $args{'-k'} - 1;
my $sample_size_col = $args{'-n'} - 1;
my $pop_succ_col    = $args{'-K'} - 1;
my $pop_size_col    = $args{'-N'} - 1;
my @extra           = @{$args{'--extra'}};

my $pctl            = defined($sigdig) ? ('%.' . $sigdig . 'f') : '%g';

if(scalar(@extra) == 4)
{
   my $pvalue = $take_log ? &ComputeLog10HyperPValue(@extra) :
                             &ComputeHyperPValueUpper(@extra);

   my $printable = defined($pvalue) ? (defined($pctl) ? sprintf($pctl, $pvalue)
                                                      : "$pvalue") : "NaN";

   print STDOUT $printable, "\n";
}

if(defined($file) and (($file eq '-') or (-f $file) or (-l $file)))
{
   my $fp = &openFile($file);

   while(<$fp>)
   {
      my @x = split($delim);

      chomp($x[$#x]);

      my $sample_succ = $x[$sample_succ_col];
      my $sample_size = $x[$sample_size_col];
      my $pop_succ    = $x[$pop_succ_col];
      my $pop_size    = $x[$pop_size_col];

      my $pvalue = $take_log ? &ComputeLog10HyperPValue($sample_succ, $sample_size, $pop_succ, $pop_size)
                              : &ComputeHyperPValueUpper($sample_succ, $sample_size, $pop_succ, $pop_size);

      my $printable = defined($pvalue) ? (defined($pctl) ? sprintf($pctl, $pvalue)
                                                         : "$pvalue") : "NaN";

      print STDOUT $printable, "\n";
   }

   close($fp);
}

exit(0);


__DATA__
syntax: compute_hyper_pval.pl [FILE | < FILE] [k n K N]

Can supply a file with four columns containing k, n, K, and N in the first
three tab-delimited columns.  Can also supply the arguments to the hypergeometric
as command line arguments.  Four arguments must be specified; these are:

         k: The number of successes drawn in a sample.
         n: The size of the sample that was drawn.
         K: The number of successes that exist in the population.
         N: The size of the population from which the sample was drawn.

-d DELIM: The delimiter seperating the different numbers.

-l: Print the log of the cummalitive probability.

-s DIGITS: Number of significant digits to report (default is 5).

-k COL: Specify the column containing the number of sample successes (default is 1).

-n COL: Specify the column containing the sample size (default is 2).

-K COL: Specify the column containing the number of successes in the population (default is 3).

-N COL: Specify the column containing the size of the population (default is 4).

