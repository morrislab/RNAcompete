#!/usr/bin/perl

use strict;
use warnings;

require "libstats.pl";
require "libfile.pl";

$| = 1;

my @flags   = (
                  [     '-q', 'scalar',     0,     1]
                , [     '-h', 'scalar',     1, undef]
                , [     '-k', 'scalar',     0, undef]
                , [    '-sc', 'scalar',     1, undef]
                , [    '-ec', 'scalar',    -1, undef]
                , ['-allstats', 'scalar',   0,     1]
                , [   '-abs', 'scalar',     0,     1]
                , [  '-mean', 'scalar',     0,     1]
                , [  '-trimmedmean', 'scalar',     undef,     undef]
                , ['-median', 'scalar',     0,     1]
                , [ '-quant', 'scalar', undef, undef]
                , [   '-std', 'scalar',     0,     1]
                , [   '-sem', 'scalar',     0,     1]
                , [ '-count', 'scalar',     0,     1]
                , [ '-countgt', 'scalar',    undef,     undef]
                , [ '-countlt', 'scalar',    undef,     undef]
                , [   '-max', 'scalar',     0,     1]
                , [   '-min', 'scalar',     0,     1]
                , ['-argmax', 'scalar',     0,     1]
                , ['-argmin', 'scalar',     0,     1]
                , [   '-sum', 'scalar',     0,     1]
                , [  '-miss', 'scalar',    '', undef]
                , [     '-d', 'scalar',  "\t", undef]
                , [ '--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose        = not($args{'-q'}); # default is verbose
my $header_rows    = $args{'-h'};
my $key_column     = $args{'-k'};
my $start_column   = $args{'-sc'};
my $end_column     = $args{'-ec'};
my $take_abs       = $args{'-abs'};
my $compute_mean   = $args{'-mean'};
my $compute_median = $args{'-median'};
my $quantile       = $args{'-quant'};
my $compute_std    = $args{'-std'};
my $compute_sem    = $args{'-sem'};
my $compute_count  = $args{'-count'};
my $compute_max    = $args{'-max'};
my $compute_min    = $args{'-min'};
my $compute_argmax = $args{'-argmax'};
my $compute_argmin = $args{'-argmin'};
my $compute_sum    = $args{'-sum'};
my $delim          = $args{'-d'};
my $missing        = $args{'-miss'};
my $file           = $args{'--file'};

my $trim   = $args{'-trimmedmean'};
my $gtval          = $args{'-countgt'};
my $ltval          = $args{'-countlt'};

my $compute_all_stats = $args{'-allstats'};
if ($compute_all_stats) {
    $compute_std  = $compute_sem = $compute_count = $compute_mean = $compute_median = $compute_max = $compute_min = $compute_sum = 1;
}

print "Key";
if ($compute_mean)      { print "\tMean";   }
if ($compute_median)    { print "\tMedian"; }
if (defined($quantile)) { print "\tQuantile_$quantile"; }
if ($compute_std)       { print "\tStd";    }
if ($compute_sem)       { print "\tSEM";    }
if ($compute_count)     { print "\tCount";  }
if (defined($gtval)) { print "\tCount_gt_$gtval"; }
if (defined($ltval)) { print "\tCount_lt_$ltval"; }
if ($compute_max)       { print "\tMax";    }
if ($compute_min)       { print "\tMin";    }
if ($compute_argmax)    { print "\tArgMax"; }
if ($compute_argmin)    { print "\tArgMin"; }
if ($compute_sum)       { print "\tSum";    }
if (defined($trim))       { print "\tTrimmed_mean_${trim}";    }
print "\n";

open(FILE, "<$file") or die "ERROR: Can't open file $file for reading!";

my $numNonNumericInHeader = 0;
my $numItemsInHeader = 0;
for (my $i = 0; $i < $header_rows; $i++) { 
    my $line = <FILE>;
    chomp($line);
    my @row = split(/\t/, $line);
    shift(@row); # remove the front item
    foreach my $item (@row) {
	if ($item !~ /^[0-9|.|,|e]*$/) {
	    $numNonNumericInHeader++;
	}
	$numItemsInHeader++;
    }
}

if ($verbose && ($numNonNumericInHeader == 0) && ($numItemsInHeader > 0) ) {
    # everything in the header was a number, so this means the user
    # PROBABLY forgot to properly specify the number of items in the
    # header
    print STDERR
	  "WARNING: row_stats.pl: every item in the header was a number.\n"
	. "         This indicates that you may have forgotten to specify -h 0 (no header lines).\n"
	. "         If input file \"$file\" does NOT have a header line, you MUST specify -h 0, or\n"
	. "         the first line in the file will be assumed to be a header and will be ignored.\n"
	. "         If you are obtaining this message in error, you can specify -q to suppress this output.\n";
}


while(<FILE>)
{
  chomp;

  my @row = split(/\t/);

  if(defined($row[$key_column])) {
     my @vec;

     my $last_column = $end_column == -1 ? (@row - 1) : $end_column;

     for (my $i = $start_column; $i <= $last_column; $i++) {
       my $x = $row[$i];
       if($x eq $missing or ($x !~ /\S/)) {
          $x = undef;
       }
       elsif($take_abs) {
          $x = $x > 0 ? $x : -$x;
       }
       $vec[$i - $start_column] = $x;
     }

     print "$row[$key_column]";

     if ($compute_mean) {
       my $stat = (scalar(@vec) > 0) ? &format_number(&vec_avg(\@vec), 3) : 'NaN';
       print "\t$stat";
     }
     if ($compute_median) {
       # vec_median prints out an error if you pass in a zero-length array
       my $stat = (scalar(@vec) > 0) ?    &format_number(&vec_median(\@vec), 3)  :  'NaN';
       print "\t$stat";
     }
     if(defined($trim)) {
       my $stat = (scalar(@vec) > 0)   ?    &format_number(&vec_trim_mean(\@vec,$trim), 3)  :  'NaN';
       print "\t$stat";
     }
     
     if(defined($quantile)) {
       my $stat = (scalar(@vec) > 0)   ?    &format_number(&vec_quantile(\@vec,$quantile), 3)  :  'NaN';
       print "\t$stat";
     }
     
     if(defined($gtval)) {
       my $stat = (scalar(@vec) > 0)   ?    &format_number(&vec_count_greater_than(\@vec,$gtval), 3)  :  'NaN';
       print "\t$stat";
     }
     
     if(defined($ltval)) {
       my $stat = (scalar(@vec) > 0)   ?    &format_number(&vec_count_less_than(\@vec,$ltval), 3)  :  'NaN';
       print "\t$stat";
     }

     if ($compute_std) {
       my $std = (scalar(@vec) > 0)      ? &format_number(&vec_std(\@vec), 3) : 'NaN';
       my $result = (defined($std) and length($std) > 0) ? sprintf('%f',$std) : 'NaN';
       print "\t", $result;
     }

     if ($compute_sem) {
       my $sem = (scalar(@vec) > 0)      ? &format_number(&vec_std(\@vec)/ sqrt(&vec_count_full_entries(\@vec)), 3) : 'NaN';
       my $result = (defined($sem) and length($sem) > 0) ? sprintf('%f',$sem) : 'NaN';
       print "\t", $result;
     }

     if ($compute_count) {
       my $count = &vec_count_full_entries(\@vec);
       print "\t$count";
     }

     if ($compute_max) {
       my $max = &vec_max(\@vec);
       my $result = (defined($max) and length($max) > 0) ? sprintf('%f',$max) : $missing;
       print "\t", $result;
     }

     if ($compute_min) {
       my $min = &vec_min(\@vec);
       my $result = (defined($min) and length($min) > 0) ? sprintf('%f',$min) : $missing;
       print "\t", $result;
     }

     if ($compute_argmax) {
       my ($arg, $max) = &vec_max(\@vec);
       my $result = (defined($arg) and length($arg) > 0) ? sprintf('%i',$arg+1) : $missing;
       print "\t", $result;
     }

     if ($compute_argmin) {
       my ($arg, $min) = &vec_min(\@vec);
       my $result = (defined($arg) and length($arg) > 0) ? sprintf('%i',$arg+1) : $missing;
       print "\t", $result;
     }

     if ($compute_sum) {
       my $sum = &vec_sum(\@vec);
       my $result = (defined($sum) and length($sum) > 0) ? sprintf('%f',$sum) : $missing;
       print "\t", $result;
     }

     print "\n";
  }
}
close(FILE);

__DATA__

row_stats.pl (-h NUM_HEADER_LINES) (-k KEY_COLUMN) <data file>

   Computes stats for rows. Different commands can be selected.

** NOTE: Default assumes there is ONE header line,
** Set -h 0 if your file has no header, or you will lose the first line!

   -h <num>:  Number of header rows (default: 1)
   -k <num>:  The key column (default: 0)

   -sc <num>: Start column of the data in each row (default: 1)
   -ec <num>: End column of the data in each row (default: -1, means last columns)

** Note that the statistics are printed out in a fixed order.
** You CANNOT change the order of printing
** by changing the order of options on the command line.

   -mean:     Compute mean for each row
   -median:   Compute the median for each row 
   -quant Q:  Compute the Qth quantile of the vector. E.g. -quant 50 is the same as -median. As another
              example, -quant 90 returns the upper 90th quantile of the vector in each row.
   -abs:      Take the absolute value of each data point (?)
   -std:      Compute standard deviation for each row
   -sem:      Compute standard error of the mean estimate for each row
   -count:    Count the number of non-empty entries in each row
   -max:      Compute the maximum for each row
   -min       Compute the minimum for each row
   -sum       Compute the sum of each row
   -argmax    Print which column has the maximum value
   -argmin    Print which column has the minimum value
   -miss VAL  Sets the missing value to VAL (default is blank).
   -allstats  Print out ALL the statistics (pay attention to the order!)
