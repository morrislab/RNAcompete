#!/usr/bin/perl

##############################################################################
##############################################################################
##
## collapse.pl
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
require "libstats.pl";

use strict;
use warnings;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-k', 'scalar',     1, undef]
                , [   '-di', 'scalar',  "\t", undef]
                , [   '-do', 'scalar',   ",", undef]
                , [    '-f', 'scalar', undef, undef]
                , ['--file', 'scalar',   '-', undef]
	        , [    '-h', 'scalar',     0, undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose    = not($args{'-q'});
my $col        = int($args{'-k'}) - 1;
my $delim_in   = $args{'-di'};
my $delim_out  = $args{'-do'};
my $function   = $args{'-f'};
my $file       = $args{'--file'};
my $headers    = int($args{'-h'});

my @order;

my %data;
my $filep;
open($filep, $file) or die("Could not open file '$file' for reading");

while($headers-- > 0) { $_ = <$filep>; print;}

while(<$filep>)
{
   my @tuple = split($delim_in, $_);
   chomp($tuple[$#tuple]);
   my $key = splice(@tuple, $col, 1);

   if(not(exists($data{$key})))
   {
      $data{$key} = \@tuple;

      push(@order, $key);
   }
   else
   {
      my $list = $data{$key};

      my $n = scalar(@{$list});

      my $m = scalar(@tuple);

      my $min = ($n < $m) ? $n : $m;

      for(my $i = 0; $i < $min; $i++)
      {
         $$list[$i] .= $delim_out . $tuple[$i];
      }

      for(my $i = $m; $i < $n; $i++)
      {
         $$list[$i] .= $delim_out;
      }
   }
}
close($filep);

foreach my $key (@order)
{
   my $list = $data{$key};

   if(defined($function))
   {
      my @tuple;
      foreach my $field (@{$list})
      {
         my @vector = split($delim_out, $field);
         my $val    = &vec_eval(\@vector, $function);
         push(@tuple, defined($val) ? $val : '');
      }
      $list = \@tuple;
   }
   print $key, $delim_in, join($delim_in, @{$list}), "\n";
}

exit(0);

__DATA__
syntax: collapse.pl [OPTIONS]

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Compare the values in column COL to the threshold in the file (default is 1).

-di DELIM: The fields in the input file are seperated by DELIM (default is tab).

-do DELIM: Use this to seperate within a field when duplicates are found (default is comma).

-f FUNCTION: Instead of concatenating entries, apply the function
             FUNCTION to the vector.  Possible values for 
             FUNCTION are:

     mean    - Compute the mean
     ave     - Same as mean
     min     - Compute the minimum
     max     - Compute the maximum
     median  - Compute the median
     sum     - Compute the sum.
     count   - Compute the number of non-empty values
     std     - Compute the standard deviation
     var     - Compute the variance
     entropy - Compute the Shannon entropy

