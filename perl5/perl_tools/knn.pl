#!/usr/bin/perl

##############################################################################
##############################################################################
##
## knn.pl
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

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-k', 'scalar',     1, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-h', 'scalar',     1, undef]
                , ['--file',   'list',    [], undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose = not($args{'-q'});
my $key_col = $args{'-k'} - 1;
my $delim   = $args{'-d'};
my $headers = $args{'-h'};
my @files   = @{$args{'--file'}};

scalar(@files) == 2 or die("Please supply a training and test set file.");

my @data;
my @labels;
open(TRAIN, $files[0]) or die("Could not open file '$files[0]' for reading");
while(<TRAIN>)
{
   my @x = split($delim, $_);
   chomp($x[$#x]);
   push(@labels, (shift @x));
   push(@data, \@x);
}
close(TRAIN);

my $test_case = 0;
open(TEST, $files[1]) or die("Could not open file '$files[1]' for reading");
my @test = <TEST>;
close(TEST);
my $total = scalar(@test);
foreach $_ (@test)
{
   $test_case++;

   my @x = split($delim, $_);
   chomp($x[$#x]);

   my $min_dist = undef;
   my $best_i   = 0;
   for(my $i = 0; $i < scalar(@data); $i++)
   {
      my $dist = &squared_euclid(\@x, $data[$i]);

      if(not(defined($min_dist)) or $dist < $min_dist)
      {
         $best_i = $i;

         $min_dist = $dist;
      }
   }

   my $prediction = $labels[$best_i];

   my $perc_done  = int($test_case / $total * 100);

   $verbose and print STDERR "$test_case. $best_i $prediction ($perc_done%)\n";

   print STDOUT "$prediction\n";
}

exit(0);

sub squared_euclid
{
   my ($x, $y) = @_;

   my $n = defined($x) ? scalar(@{$x}) : 0;

   my $m = defined($y) ? scalar(@{$y}) : 0;

   my $N = $n < $m ? $n : $m;

   my $sum = 0.0;

   for(my $i = 0; $i < $N; $i++)
   {
      $sum += ($$x[$i] - $$y[$i]) * ($$x[$i] - $$y[$i]);
   }

   return $sum;
}

__DATA__
syntax: knn.pl [OPTIONS] TRAIN TEST

TRAIN: training file.  Contains <label> <x1> <x2> ... in tab-delimited format.

TEST:  test file.  Contains <x1> <x2> ... in tab-delimited format.

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Set the key column to COL (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 1).



