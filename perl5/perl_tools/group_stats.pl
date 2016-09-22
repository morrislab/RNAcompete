#!/usr/local/bin/perl

##############################################################################
##############################################################################
##
## group_stats.pl
##
##############################################################################
##############################################################################
##
## Written by Josh Stuart.
##
##  Email address: jstuart@soe.ucsc.edu
##          Phone: (831) 459-1344
##
## Postal address: 1156 High Street, 308 Physical Sciences
##                 Mail Stop: SOE2
##                 Santa Cruz, CA 95064
##
##       Web site: http://www.soe.ucsc.edu/~jstuart/
##
##############################################################################
##############################################################################

require "libfile.pl";
require "$ENV{MYPERLDIR}/lib/libstats.pl";
require "$ENV{MYPERLDIR}/lib/libset.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;


my @flags   = (
                  [       '-q', 'scalar',     0,     1]
                , [       '-k', 'scalar', undef, undef]
                , [      '-dk', 'scalar',     1, undef]
                , [      '-gk', 'scalar',     1, undef]
                , [       '-d', 'scalar',  "\t", undef]
                , [       '-h', 'scalar',     1, undef]
                , [   '--file',   'list',    [], undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose       = not($args{'-q'});
my $key_col       = $args{'-k'};
my $key_col_data  = int($args{'-dk'}) - 1;
my $key_col_group = int($args{'-gk'}) - 1;
my $delim         = $args{'-d'};
my $headers       = $args{'-h'};
my @files         = @{$args{'--file'}};
my @extra         = @{$args{'--extra'}};

if(defined($key_col)) {
   $key_col_data  = $key_col - 1;
   $key_col_group = $key_col - 1;
}

scalar(@files) == 2 or die("Please supply 2 files");

my ($data_file, $grouping_file) = @files;

my $data = &readKeyedTuples($data_file, $delim, $key_col_data, $headers, 0);

my $groups = &readKeyedValues($grouping_file, $delim, $key_col_group, undef, 0, 1);

foreach my $group (keys(%{$groups})) {
   my $member_keys = $$groups{$group};
   # print STDOUT $group, "\t", join("\t", @{$member_keys}), "\n";

   my $member_data = &getSubset($data, $member_keys);

   my @X;
   foreach my $member (keys(%{$member_data})) {
      my $x = $$member_data{$member};
      push(@X, $x);
   }

   foreach my $stat (@extra) {

      my ($Nums, $Means, $Stdevs);
      if($stat eq '-count' or $stat eq '-mean' or $stat eq '-std') {
         ($Nums, $Means, $Stdevs) = &mat_stats(\@X);
      }

      ($stat eq '-count') and print STDOUT $group
         , "\tNum\t", join("\t", @{$Nums}), "\n";

      if($stat eq '-sum') {
         my ($nums,$sums) = &mat_sum(\@X);
         print STDOUT "$group\tNum\t", join("\t", @{$sums}), "\n";
      }

      ($stat eq '-mean') and print STDOUT $group
         , "\tMean\t", join("\t", @{$Means}), "\n";

      ($stat eq '-std') and print STDOUT $group
         , "\tStdDev\t", join("\t", @{$Stdevs}), "\n";

      ($stat eq '-median') and print STDOUT $group
         , "\tMedian\t", join("\t", @{&mat_median(\@X)}), "\n";

      if($stat eq '-min' or $stat eq '-argmin') {
         my ($args, $mins) = &mat_min(\@X);
         ($stat eq '-min') and print STDOUT $group
            , "\tMin\t", join("\t", @{$mins}), "\n";
         ($stat eq '-argmin') and print STDOUT $group
            , "\tArgMin\t", join("\t", @{$args}), "\n";
      }

      if($stat eq '-max' or $stat eq '-argmax') {
         my ($args, $maxs) = &mat_max(\@X);
         ($stat eq '-max') and print STDOUT $group
            , "\tMax\t", join("\t", @{$maxs}), "\n";
         ($stat eq '-argmax') and print STDOUT $group
            , "\tArgMax\t", join("\t", @{$args}), "\n";
      }
   }
}

exit(0);

__DATA__
syntax: group_stats.pl [OPTIONS] DATA_FILE GROUPING_FILE

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Compare the values in column COL to the threshold in the file (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h NUM: Set the number of headers for the DATA_FILE to NUM. Default is 1.

Specify any combination of the following flags to report different
statistics of the columns of the data matrix of the various groups:
-count
-sum
-mean
-std
-median
-min
-max
-argmin
-argmax


