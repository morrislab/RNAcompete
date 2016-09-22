#!/usr/bin/perl

##############################################################################
##############################################################################
##
## aggregate.pl
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

## Support for MEDIAN calculation added by Alex Williams, 2007


require "libfile.pl";
require "$ENV{MYPERLDIR}/lib/libstats.pl";

use strict;
use warnings;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-k', 'scalar',     1, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-h', 'scalar',     0, undef]
                , [  '-sig', 'scalar',     3, undef]
                , [    '-f', 'scalar','mean', undef]
                , ['--file', 'scalar',   '-', undef]
			    , ['--emptyval', 'scalar',     'NaN',     undef]
			    , ['--test', 'scalar',     0,     1]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $emptyVal = $args{'--emptyval'};
my $runTest  = $args{'--test'}; # <-- this doesn't do anything right now. Theoretically it should run a test to make sure the values actually work for a few known cases (sanity check for this program)
my $verbose  = not($args{'-q'});
my $col      = int($args{'-k'}) - 1;
my $delim    = $args{'-d'};
my $function = lc($args{'-f'}); # lower-case whatever the function name was
my $headers  = $args{'-h'};
my $sigs     = $args{'-sig'};
my $file     = $args{'--file'};

my $sprintf_ctrl = '%.' . $sigs . 'f';


if ($function ne 'mean' && $function ne 'median') {
	die "ERROR in aggregate.pl: You must specify a function ( -f  FUNCTION_NAME ). The supported functions are mean and median.\n";
}

# my ($ids, $rows) = &readIds($file, $col, $delim);
# my $data = &readDataMatrix($file, $col, $delim, \$max_cols);
my ($data, $ids, $rows, $max_cols) = &readDataAndIds($file, $col, $delim);

for(my $i = 0; $i < scalar(@{$rows}) and $i < $headers; $i++) {
   print $$ids[$i], $delim, join($delim, @{$$data[$i]}), "\n";
}

for(my $i = $headers; $i < scalar(@{$rows}); $i++)
{
   my $id = $$ids[$i];

   my $useMedian = ($function eq 'median');
   my $useMean   = ($function eq 'mean');

   my @sum;
   my @count;
   my @medianCalcArray; # this is actually just a list of all the items in the column for each key
   # Note: medianCalcArray is an array of ARRAYS.

   for(my $j = 0; $j < $max_cols; $j++) {
      $sum[$j] = 0;
      $count[$j] = 0;
   }

   #my @r = @{$$rows[$i]};

   for(my $k = 0; $k < scalar(@{$$rows[$i]}); $k++) {
	   my $row = $$rows[$i][$k];
	   
	   #print "Row is $row\n";
	   for(my $j = 0; $j < $max_cols; $j++) {
		   my $thisEntry = $$data[$row][$j];
		   if(defined($thisEntry)) {
			   if($thisEntry =~ /^\s*[\d+\.eE-]+\s*$/) {
				   $count[$j]++;
				   $sum[$j] += $thisEntry;
				   if ($useMedian) {
					   if (!defined($medianCalcArray[$j])) {
						   @{$medianCalcArray[$j]} = ();
					   }
					   push(@{$medianCalcArray[$j]}, $thisEntry);
					   #print "$j: $k: $row: ";
					   #print @{$medianCalcArray[$j]};
					   #print "\n";
				   }
			   }
		   }
	   }
   }

   my @agg;
   for(my $j = 0; $j < $max_cols; $j++) {
      $agg[$j] = ${emptyVal};
      if($useMean) {
         $agg[$j] = ($count[$j] > 0) ? sprintf($sprintf_ctrl, ($sum[$j] / $count[$j])) : ${emptyVal};
      }
	  if($useMedian) {
		  # Only calculate the median if we actually specifically want it... otherwise it slows us down
		  if (defined($medianCalcArray[$j]) && (scalar(@{$medianCalcArray[$j]}) > 0) ) {
			  $agg[$j] = vec_median(\@{$medianCalcArray[$j]}); # <-- vec_median is in libstats.pl
		  }
	  }
	  if ($useMean && $useMedian) { die "Cannot specify both mean AND median currently! We are overwriting the storage variable!\n"; }
   }

   print STDOUT $id, (($max_cols > 0) ? ($delim . join($delim, @agg)) : ""), "\n";
}

exit(0);


__DATA__
syntax: aggregate.pl [OPTIONS]

Combines the numeric data across rows with the same key. Useful if you have experiments
with replicates. See below for a complete example.


OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Use the column COL as the key column. The script uses the entries found on
        each line of this column as keys. Duplicates are merged by applying an
        aggregation function for each value in their records.

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h NUM: The number of headers in the input file (default is 0).

-f FUNCTION: Set the aggregation function to FUNCTION (default is mean).
             The possible values are:

                 mean: The mean of the values (default)

                 median: The median of the values.

--emptyval VALUE: Sets the "empty"/"no data" values to VALUE. (defalut is NaN)

EXAMPLE:

Works like this:

If this is the input file (tab-delimited, although spaces are shown here):

Experiment_Alpha 1     0  77
Experiment_Alpha 2     0
Expr_Beta        10
Expr_Beta        30
Experiment_Alpha 3     6
Expr_Beta           5

(Note that the second column, between "1" and "0" on the first row for Experiment_Alpha, is blank)

And you say: aggregate.pl -f mean

Then the output will be:

Experiment_Alpha   2.0   NaN   3.0   77
Expr_Beta          20    5     NaN   NaN

Note that the "77" case (the last item in the first row) is the corect mean,
because the other Experiment_Alpha items for that column
do not have any data ta all. Even though there are 3 rows labeled "Experiment_Alpha",
only one of them has data for the last column (column 4), so 77 is the mean. The output is always
a matrix (although it could be a single-column matrix). Empty values are padded with NaN (although
you can change this with --emptyval).


TO DO / FUTURE WORK:

Future possibility (NOT IMPLEMENTED YET): smean: Standardized mean (mean/stddev).

KNOWN BUGS / ISSUES:

None so far.
