#!/usr/bin/perl

##############################################################################
##############################################################################
##
## topk.pl
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
                , [    '-v', 'scalar',     2, undef]
                , [    '-k', 'scalar',    10, undef]
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

my $verbose = not($args{'-q'});
my $key_col = int($args{'-f'}) - 1;
my $val_col = int($args{'-v'}) - 1;
my $rev     = $args{'-r'};
my $topk    = $args{'-k'};
my $delim   = $args{'-d'};
my $file    = $args{'--file'};

my %data;
my @keys;
my $line_no = 0;

my $filep;
open($filep, $file) or die("Could not open file '$file' for reading");
while(<$filep>) {
   $line_no++;
   my @x = split($delim, $_);
   chomp($x[$#x]);
   my $key   = $x[$key_col];
   my $value = $x[$val_col];

   if(defined($key) and (&isNumber($value) or &isEmpty($value))) {
      if(not(exists($data{$key}))) {
         $data{$key} = [];
         push(@keys,$key);
      }
      push(@{$data{$key}},[$value,$_]);
   }
   else {
      $verbose and print STDERR "Line number $line_no had non-numeric value '$value'.\n";
   }
}
close($filep);

foreach my $key (@keys) {
   my @data = $rev ? (sort {&compareNumbers($$a[0],$$b[0]);} @{$data{$key}}) :
                     (sort {&compareNumbers($$b[0],$$a[0]);} @{$data{$key}});
   my $n = $topk < scalar(@data) ? $topk : scalar(@data);
   for(my $i = 0; $i < $n; $i++) {
      print $data[$i][1];
   }
}

exit(0);

__DATA__
syntax: topk.pl [OPTIONS]

# Note: this program may be functionally similar to select_best_item_per_line.pl
# So check that out if you find that this program doesn't support the functionality
# you are looking for.

OPTIONS are:

-q: Quiet mode (default is verbose)

-k K: Keep the top K examples (default is 10).

-f COL: Keys are in column COL.

-v COL: Compare the values in column COL

-r: Reverse the sort. By default it keeps K entries with the corresponding
    largest values. If this option is supplied, it keeps those entries with
    the smallest values.

-d DELIM: Set the field delimiter to DELIM (default is tab).



