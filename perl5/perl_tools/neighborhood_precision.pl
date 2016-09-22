#!/usr/bin/perl

##############################################################################
##############################################################################
##
## neighborhood_precision.pl
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

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [        '-q', 'scalar',     0,     1]
                , [       '-kn', 'scalar',     1, undef]
                , [       '-kc', 'scalar',     1, undef]
                , [       '-dn', 'scalar',  "\t", undef]
                , [       '-dc', 'scalar',  "\t", undef]
                , [      '-max', 'scalar', undef, undef]
                , [        '-c', 'scalar', undef, undef]
                , [        '-i', 'scalar', undef, undef]
                , ['-fractions', 'scalar',     0,     1]
                , [   '-counts', 'scalar',     1,     1]
                , [    '--file',   'list', ['-'], undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose     = not($args{'-q'});
my $nbr_key_col = $args{'-kn'};
my $cat_key_col = $args{'-kc'};
my $nbr_delim   = $args{'-dn'};
my $cat_delim   = $args{'-dc'};
my $max         = $args{'-max'};
my $cutoff      = $args{'-c'};
my $cutoff_inc  = $args{'-i'};
my $fractions   = $args{'-fractions'};
my $counts      = $args{'-counts'};
my @files       = @{$args{'--file'}};

$counts = not($fractions);

$cutoff_inc = defined($cutoff_inc) ? $cutoff_inc : ($counts ? 1 : .1);

$nbr_key_col--;
$cat_key_col--;

scalar(@files) == 2 or die("Please supply 2 files: NEIGHBORHOODS ANNOTATIONS");

my $nbr_file = $files[0];
my $cat_file = $files[1];

# Read in the neighborhoods
$verbose and print STDERR "Reading in the neighborhoods...";
my $neighborhoods = &setsReadLists($nbr_file, $nbr_delim, $nbr_key_col, 0, undef, $max);
$verbose and print STDERR " done.\n";
# &setsPrint($neighborhoods, \*STDOUT, 0, 1);

# Read in the categories:
$verbose and print STDERR "Reading in the categories...";
my $categories = &setsReadTable($cat_file, 1, $cat_delim, $cat_key_col);
$verbose and print STDERR " done.\n";
# &setsPrint($categories, \*STDOUT, 0, 1);

# Determine what cutoffs to try.
my @cutoffs  = &getCutoffs($neighborhoods, $cutoff_inc, $counts, $cutoff);

my $num_targets = &setSize($neighborhoods);
my $num_cat = &setSize($categories);
$verbose and print STDERR "Calculating precisions for $num_cat categories and $num_targets targets.\n",
                          "Will try the cutoffs: ", join(",",@cutoffs), " for each.\n";

# Iterate over each category
my @categories = sort(keys(%{$categories}));
my @targets     = sort(keys(%{$neighborhoods}));

print STDOUT "Category\tCutoff\tNum Predicted\tNum Correct\tPrecision (%)\n";

foreach my $category (@categories)
{
   my $category_set = $$categories{$category};
   my $cat_total  = &setSize($category_set);
   my @num_predicted;
   my @num_correct;
   foreach my $target (@targets)
   {
      my $neighborhood = $$neighborhoods{$target};

      my $annotated_neighbors = &setIntersection($neighborhood, $category_set);

      my $nbrs_total = &setSize($neighborhood);

      my $nbrs_annot = &setSize($annotated_neighbors);

      # print STDERR "annot: {", join(" ",keys(%{$category_set})), "}\n";
      # print STDERR "nbrhd: {", join(" ",keys(%{$neighborhood})), "}\n";
      # print STDERR "inter: {", join(" ",keys(%{$annotated_neighbors})), "}\n";

      my $is_target_annotated = exists($$category_set{$target});

      if($nbrs_total > 0)
      {
         $nbrs_annot = $counts ? $nbrs_annot : ($nbrs_annot / $nbrs_total);

         for(my $i = 0; $i < scalar(@cutoffs) and (not($counts) or $cutoffs[$i] <= $nbrs_total); $i++)
         {
            if($nbrs_annot >= $cutoffs[$i])
            {
               # Predict the category for this target at this cutoff and
               # see if we are correct.
               $num_correct[$i]   += $is_target_annotated;
               $num_predicted[$i] += 1;
            }
            else
            {
               $num_correct[$i]   += 0;
               $num_predicted[$i] += 0;
            }
         }
      }
   }

   for(my $i = 0; $i < scalar(@cutoffs); $i++)
   {
      if(defined($num_predicted[$i]) and defined($num_correct[$i]) and
         $num_predicted[$i] > 0)
      {
         my $accuracy = $num_correct[$i] / $num_predicted[$i] * 100.0;

         print STDOUT $category, "\t",
                      $cutoffs[$i], "\t",
                      $num_predicted[$i], "\t",
                      $num_correct[$i], "\t",
                      $accuracy, "\n";
      }
   }

   $verbose and print STDERR "Completed precision calculations for category '$category'.\n";
}


exit(0);


# @list &getCutoffs($neighborhoods, $increment, $counts, $cutoff)
sub getCutoffs
{
   my ($neighorhoods, $increment, $counts, $cutoff) = @_;

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
         my $max_size = undef;
         foreach my $target (keys(%{$neighborhoods}))
         {
            my $size = &setSize($$neighborhoods{$target});
            if(not(defined($max_size)) or $size > $max_size)
            {
               $max_size = $size;
            }
         }
         for(my $cut = 0; $cut <= $max_size; $cut += $increment)
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
syntax: neighborhood_precision.pl [OPTIONS] NEIGHBORHOODS ANNOTATIONS

NEIGHBORHOODS - Tab-delimited file listing a key in first column and neighbors
                in subsequent columns.

ANNOTATIONS   - Tab-delimited {0,1} matrix listing keys down the rows and categories
                across the columns.  Each (i,j) entry specifies whether key i
                is included in category j.

OPTIONS are:

-q: Quiet mode (default is verbose)

-kn COL: Set the key column to COL for the neighborhoods (default is 1).

-kc COL: Set the key column to COL for the categories (default is 1).

-dn DELIM: Set the field delimiter to DELIM for the neighborhoods (default is tab).

-dc DELIM: Set the field delimiter to DELIM for the categories (default is tab).

-c CUTOFF: Set the prediction cutoff to CUTOFF (default is undefined in which case
           the cutoff is varied producing accuracies for each cutoff value).

-i INC: Set the cutoff increment to INC (note this option is ignored if -c used).  The
        default is 1 if using counts (see -counts option) or 0.1 if using fractions
        (see -fractions option).

The next two options are mutually exclusive:

-fractions: If fraction of neighbors is greater or equal to CUTOFF (see -c option)
            then predict the category.

-counts If the number of neighbors is greater or equal to CUTOFF (see -c option)
        then predict the category.

