#!/usr/bin/perl

##############################################################################
##############################################################################
##
## neighborhood_pairs.pl
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
require "$ENV{MYPERLDIR}/lib/libset.pl";
require "$ENV{MYPERLDIR}/lib/libattrib.pl";
require "$ENV{MYPERLDIR}/lib/libgraph.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [        '-q', 'scalar',     0,     1]
                , [       '-kn', 'scalar',     1, undef]
                , [       '-kp', 'scalar',     1, undef]
                , [       '-dn', 'scalar',  "\t", undef]
                , [       '-dp', 'scalar',  "\t", undef]
                , [      '-max', 'scalar', undef, undef]
                , [        '-c', 'scalar', undef, undef]
                , [     '-maxc', 'scalar', undef, undef]
                , [     '-minc', 'scalar', undef, undef]
                , [        '-r', 'scalar',     0, undef]
                , [    '--file',   'list', ['-'], undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose        = not($args{'-q'});
my $nbr_key_col    = $args{'-kn'};
my $pair_key_col   = $args{'-kp'};
my $nbr_delim      = $args{'-dn'};
my $pair_delim     = $args{'-dp'};
my $max            = $args{'-max'};
my $cutoff         = $args{'-c'};
my $max_cut        = $args{'-maxc'};
my $min_cut        = $args{'-minc'};
my $randomizations = $args{'-r'};
my @files          = @{$args{'--file'}};

$nbr_key_col--;
$pair_key_col--;

scalar(@files) == 2 or die("Please supply 2 files: NEIGHBORHOODS ANNOTATIONS");

my $nbr_file  = $files[0];
my $pair_file = $files[1];

# Read in the neighborhoods
$verbose and print STDERR "Reading in the neighborhoods...";
my $neighborhoods = &setsReadLists($nbr_file, $nbr_delim, $nbr_key_col, 0, undef, $max);
$verbose and print STDERR " done.\n";
# &setsPrint($neighborhoods, \*STDOUT, 0, 1);

# Read in the pairs:
$verbose and print STDERR "Reading in pairs...";
my $sets = &edgesReadTable($pair_file, $pair_delim, $pair_key_col, 1);
$verbose and print STDERR " done.\n";
# &setsPrint($pairs, \*STDOUT, 0, 1);

my $pairs = &sets2List($sets, $pair_delim);

my $num_targets = &setSize($neighborhoods);
my $num_pairs   = scalar(@{$pairs});
$verbose and print STDERR "Calculating precisions for $num_pairs pairs and $num_targets targets.\n";

# Iterate over each pair
my @targets = sort(keys(%{$neighborhoods}));

my $increment  = 1;
my $counts     = 1;
my @cutoffs    = &getCutoffs($neighborhoods, $increment, $counts, $cutoff, $min_cut, $max_cut);

if($randomizations == 0)
{
   my $num_valids = &calcCorrespond($neighborhoods, $pairs, \@cutoffs, $verbose);

   print STDOUT "Cutoff\tValidated Neighborhoods\tPercent Validated\n";
   for(my $i = 0; $i < scalar(@cutoffs); $i++)
   {
      my $cut        = $cutoffs[$i];
      my $num_valid  = $$num_valids[$i];
      my $perc_valid = $num_valid / $num_targets * 100.0;
      print STDOUT $cut, "\t", $num_valid, "\t", $perc_valid, "\n";
   }
}
else
{
   for(my $r = 1; $r <= $randomizations; $r++)
   {
      $verbose and print STDERR "$r. Performing randomization.\n";
      $verbose and print STDERR "$r. Permuting neighborhoods.\n";
      my $permuted_neighborhoods = &attribPermute($neighborhoods);
      $verbose and print STDERR "$r. Done permuting neighborhoods.\n";
      $verbose and print STDERR "$r. Calculating correspondance to pairs.\n";
      my $num_valids = &calcCorrespond($permuted_neighborhoods, $pairs, \@cutoffs, 0);
      $verbose and print STDERR "$r. Done calculating correspondance to pairs.\n";
      print STDOUT "Randomization\tCutoff\tValidated Neighborhoods\tPercent Validated\n";
      for(my $i = 0; $i < scalar(@cutoffs); $i++)
      {
         my $cut        = $cutoffs[$i];
         my $num_valid  = $$num_valids[$i];
         my $perc_valid = $num_valid / $num_targets * 100.0;
         print STDOUT $r, "\t", $cut, "\t", $num_valid, "\t", $perc_valid, "\n";
      }
      $verbose and print STDERR "$r. Done performing randomization.\n";
   }
}

exit(0);

# \@list calcCorrespond($neighborhoods, $pairs, \@cutoffs, $verbose)
sub calcCorrespond
{
   my ($neighborhoods, $pairs, $cutoffs, $verbose) = @_;
   $verbose = defined($verbose) ? $verbose : 1;

   my %num_pairs;
   my $max_size = undef;
   $verbose and print STDERR "Comparing neighborhoods to pairing data.\n";
   my $i = 0;
   foreach my $target (@targets)
   {
      $verbose and print STDERR "Analyzing neighborhood '$target'...";
      my $neighborhood = $$neighborhoods{$target};
      foreach my $pair (@{$pairs})
      {
         my ($one, $two) = split($pair_delim, $pair);
         if((($target eq $one) and exists($$neighborhood{$two})) or
            (($target eq $two) and exists($$neighborhood{$one})))
         {
            $num_pairs{$target}++;
         }

         my $size = &setSize($neighborhood);
         if(not(defined($max_size)) or $size > $max_size)
         {
            $max_size = $size;
         }
      }
      $i++;
      my $perc_done = int($i / $num_targets * 100.0);
      $verbose and print STDERR " ($perc_done% done).\n";
   }

   my @num_valids;
   foreach my $cut (@cutoffs)
   {
      my $num_valid = 0;
      foreach my $target (@targets)
      {
         my $num = exists($num_pairs{$target}) ? $num_pairs{$target} : 0;
         $num_valid += ($num >= $cut) ? 1 : 0;
      }
      push(@num_valids, $num_valid);
   }
   return \@num_valids;
}

# @list &getCutoffs($neighorhoods, $increment, $counts, $cutoff, $lower, $upper)
sub getCutoffs
{
   my ($neighorhoods, $increment, $counts, $cutoff, $lower, $upper) = @_;

   my @cutoffs;

   if(defined($cutoff))
   {
      push(@cutoffs, $cutoff);
   }
   else
   {
      if($counts)
      {
         # Find the maximum neighborhood size.
         if(not(defined($upper)))
         {
            foreach my $target (keys(%{$neighborhoods}))
            {
               my $size = &setSize($$neighborhoods{$target});
               if(not(defined($upper)) or $size > $upper)
               {
                  $upper = $size;
               }
            }
         }
         $lower = defined($lower) ? $lower : 0;
         for(my $cut = $lower; $cut <= $upper; $cut += $increment)
         {
            push(@cutoffs, $cut);
         }
      }
      else
      {
         for(my $cut = 0.0; $cut <= 1.0; $cut += $increment)
         {
            push(@cutoffs, $cut);
         }
      }
   }

   return @cutoffs;
}


__DATA__
syntax: neighborhood_pairs.pl [OPTIONS] NEIGHBORHOODS PAIR_TABLE

NEIGHBORHOODS - Tab-delimited file listing a key in first column and neighbors
                in subsequent columns.

PAIR_TABLE    - Tab-delimited {0,1} matrix listing keys down the rows and keys
                across the columns.  Each (i,j) entry specifies whether key i
                and key j are considered to be a pair.

OPTIONS are:

-q: Quiet mode (default is verbose)

-kn COL: Set the key column to COL for the neighborhoods (default is 1).

-kp COL: Set the key column to COL for the pairs (default is 1).

-dn DELIM: Set the field delimiter to DELIM for the neighborhoods (default is tab).

-dp DELIM: Set the field delimiter to DELIM for the pairs (default is tab).

-c CUTOFF: Specify the cutoff at or above which we consider a neighborhood to
           contain a significant number of pairs (default is undefined in which
           case the cutoff is varied and results are returned for each value
           of the cutoff).

-maxc CUTOFF: Define the maximum cutoff to use (overridden if -c option used).

-minc CUTOFF: Define the minimum cutoff to use (overridden if -c option used).

-r RANDOMIZATIONS: Perform RANDOMIZATIONS randomizations where the centers of the
                   neighborhoods are permuted wrt the neigbors (default is 0).

