#!/usr/local/bin/perl

##############################################################################
##############################################################################
##
## gsea.pl
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
require "$ENV{MYPERLDIR}/lib/libset.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;


my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-k', 'scalar',     1, undef]
                , [    '-h', 'scalar',     1, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-e', 'scalar',    "", undef]
                , [    '-p', 'scalar',     1, undef]
                , [  '-min', 'scalar',     5, undef]
                , [   '-sf', 'scalar',     3, undef]
                , [ '--file',  'list',    [], undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'})) {
   print STDOUT <DATA>;
   exit(0);
}

my $verbose  = not($args{'-q'});
my $col      = int($args{'-k'}) - 1;
my $headers  = int($args{'-h'});
my $delim    = &interpMetaChars($args{'-d'});
my $empty    = $args{'-e'};
my $power    = $args{'-p'};
my $min_set  = $args{'-min'};
my $sig_figs = $args{'-sf'};
my @files    = @{$args{'--file'}};
my @extra    = @{$args{'--extra'}};

my @scores_order;
my @sets_order;
my $sets   = &setsReadLists($files[0], $delim, 0, 0, \@sets_order, undef, 0);
my $scores = &setsReadMatrix($files[1], undef, $delim, $col, $headers, $empty, \@scores_order);

# &setsPrintMatrix($scores, \*STDOUT, $delim, $empty, \@scores_order);
# &setsPrintMatrix($sets, \*STDOUT, $delim, $empty, \@sets_order);

my %gsea;

# Collect all of the GSEA ES results for all sets against all scores.
foreach my $score_key (keys(%{$scores})) {
   my %this_gsea;

   $verbose and print STDERR "Computing GSEA on scores from column '$score_key'.\n";
   my $score_set = $$scores{$score_key};
   my @scored_members;
   my $N = 0;
   foreach my $member (keys(%{$score_set})) {
      my $score = $$score_set{$member};
      push(@scored_members, [$member,$score]);
      $N += 1;
   }

   # Sort the members based on their scores.
   @scored_members = sort {$$b[1] <=> $$a[1];} @scored_members;

   # Loop over each set, S.
   foreach my $set_key (keys(%{$sets})) {
      my $S = $$sets{$set_key};

      # Determine the total absolute scores for members in the
      # set.
      my $NR = 0;
      my $NH = 0;

      for(my $i = 0; $i < @scored_members; $i++) {
         my ($member, $score) = @{$scored_members[$i]};
         if(exists($$S{$member})) {
            $NR += abs($score)**$power;
            $NH += 1;
         }
      }

      my $ES = undef;
      if($NR > 0 && $NH < $N && $NH >= $min_set) {
         # Get the maximum difference between Phit(i) and Pmiss(i).
         # Define this maximum to be the ES score for this set.
         $ES = 0;
         my $Phit  = 0;
         my $Pmiss = 0;
         for(my $i = 0; $i < @scored_members; $i++) {
            my ($member, $score) = @{$scored_members[$i]};
            if(exists($$S{$member})) {
               $Phit += (abs($score)**$power) / $NR;
            }
            else {
               $Pmiss += 1 / ($N - $NH);
            }
            my $delta = $Phit - $Pmiss;
            if(abs($delta) > abs($ES)) {
               $ES = $delta;
            }
         }
      }

      if(defined($ES)) {
         $this_gsea{$set_key} = &format_number($ES, $sig_figs);
      }
   }
   $gsea{$score_key} = \%this_gsea;
   $verbose and print STDERR "Finished computing GSEA on scores from column '$score_key'.\n";
}

&setsPrintMatrix(\%gsea, \*STDOUT, $delim, $empty, \@scores_order, \@sets_order);

exit(0);

__DATA__
syntax: gsea.pl [OPTIONS] SETS SCORES

Implementation of Gene Set Enrichment Analysis as described in
Subramanian et al., PNAS 2005. This returns the ES score for each set tested
against a set of scores found in SCORES.

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Set the key column in SCORES to COL (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header rows in SCORES to HEADERS (default is 1).

-e EMPTY: Assume the empty values in the SCORES are EMPTY (default is blank).  For
          example, Matlab friendly empty values would be NaN.

-p POWER: Set the exponent in the GSEA function to POWER (deafult is 1).

-min SIZE: Set the minimum gene set size to SIZE (default is 5). GSEA will only be
           computed for sets that have at least SIZE members that contain scores.

-sf SIGS: Set how many significant figures to print out (default is 3).
