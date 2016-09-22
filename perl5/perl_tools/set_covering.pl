#!/usr/bin/perl

##############################################################################
##############################################################################
##
## set_covering.pl
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

use strict;

require "libfile.pl";
require "$ENV{MYPERLDIR}/lib/libset.pl";
require "$ENV{MYPERLDIR}/lib/libattrib.pl";

use strict;
use warnings;

$| = 1;

my @flags   = (
                  [     '-q', 'scalar',     0,     1]
                , [     '-k', 'scalar',     1, undef]
                , [     '-d', 'scalar',  "\t", undef]
                , [     '-h', 'scalar',     1, undef]
                , [   '-max', 'scalar',   500, undef]
                , [   '-min', 'scalar',    10, undef]
                , [   '-tol', 'scalar',    10, undef]
                , [   '-rem', 'scalar', undef, undef]
                , [   '-ign', 'scalar', undef, undef]
                , [ '-growing_union', 'scalar',     0,     1]
                , ['-nosort', 'scalar',     0,     1]
                , [ '--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose = not($args{'-q'});
my $col     = $args{'-k'};
my $delim   = $args{'-d'};
my $headers = $args{'-h'};
my $max     = $args{'-max'};
my $min     = $args{'-min'};
my $tol     = $args{'-tol'};
my $removed = $args{'-rem'};
my $ignore  = $args{'-ign'};
my $union   = $args{'-union'};
my $nosort  = $args{'-nosort'};
my $file    = $args{'--file'};

$col--;

my $remfp = undef;
if(defined($removed))
{
   open($remfp, ">$removed") or die("Could not open removed file '$removed'");
}

# my @header = @{&getHeader($file, $headers, $delim)};
# my $num_sets = scalar(@header) - 1;

print STDERR "Reading sets from '$file' ($headers headers).\n";
my %set_order;
my $sets     = &setsReadTable($file, 1, $delim, $col, $headers, \%set_order);
my $num_sets = &setSize($sets);
print STDERR "Read $num_sets sets from '$file'.\n";

# Remove sets that the user wants to ignore.
if(defined($ignore))
{
   open(IGNORE, "$ignore") or die("Could not open ignore file '$ignore'");
   while(<IGNORE>)
   {
      chomp;
      if(exists($$sets{$_}))
      {
         my $size = exists($$sets{$_}) ? &setSize($$sets{$_}) : 0;
         $verbose and print STDERR "Removing set '$_' (size = $size) since in ignore file.\n";
         delete($$sets{$_});
         delete($set_order{$_});
         defined($remfp) and print $remfp "$_\t$size\tignored\n";
      }
   }
   close(IGNORE);
}

# Remove sets that are too big or too small.
$verbose and print STDERR "Removing sets that are too big or too small.\n";
my $num_deleted = 0;
foreach my $set_key (keys(%{$sets}))
{
   my $size = &setSize($$sets{$set_key});

   if($min >= 0 and $size < $min)
   {
      $verbose and print STDERR "Removing set '$set_key'; it's too small ($size < $min).\n";
      delete($$sets{$set_key});
      delete($set_order{$set_key});
      $num_deleted++;
      defined($remfp) and print $remfp "$set_key\t$size\ttoo small\n";
   }
   elsif($max >= 0 and $size > $max)
   {
      $verbose and print STDERR "Removing set '$set_key'; it's too big ($size > $max).\n";
      delete($$sets{$set_key});
      delete($set_order{$set_key});
      $num_deleted++;
      defined($remfp) and print $remfp "$set_key\t$size\ttoo big\n";
   }
}

# my @set_order = @{&attribGetAttribSortByNumericValue(\%set_order)};

# print join("\n",@set_order);

my %set_keys_remaining;
foreach my $set_key (keys(%{$sets}))
{
   $set_keys_remaining{$set_key} = 1;
}
my $remaining = &setSize(\%set_keys_remaining);
$verbose and print STDERR "Removed $num_deleted sets (out of $num_sets) that were either too big or too small ($remaining sets remain).\n";

my $done = 0;
my %kept_sets;
my $growing_union;
print STDOUT "Set\tSize\tAdded\tRunning Union\n";
while(scalar(keys(%set_keys_remaining)) > 0)
{
   # Find out the next set on the queue.
   my $next_key  = undef;

   if($nosort)
   {
      $next_key = &attribGetAttribWithMinNumericValue(\%set_order);
   }
   else
   {
      my $sets_remaining = &setSubset($sets, \%set_keys_remaining);
      $next_key          = &setsFindBiggest($sets_remaining);
   }

   my $next_set  = $$sets{$next_key};
   my $next_size = &setSize($next_set);

   # In a greedy fashion, add the set if the intersection is small enough.
   my $intersection      = &setIntersection($growing_union, $next_set);
   my $intersection_size = &setSize($intersection);

   my $new = $next_size - $intersection_size;
   my $percent = $intersection_size / $next_size * 100.0;
   my $keep = $percent <= $tol ? 1 : 0;

   if(not($union))
   {
      $keep = 1;
      my @set_keys = keys(%kept_sets);
      for(my $i = 0; ($i < scalar(@set_keys)) and $keep; $i++)
      {
         my $set_key           = $set_keys[$i];
         my $intersection      = &setIntersection($$sets{$set_key}, $next_set);
         my $intersection_size = &setSize($intersection);
         my $new = $next_size - $intersection_size;
         my $percent = $intersection_size / $next_size * 100.0;
         if($percent > $tol)
         {
            $keep = 0;
         }
      }
   }

   if($keep)
   {
      $kept_sets{$next_key} = 1;
      $growing_union = &setUnion($growing_union, $next_set);
      my $union_size = &setSize($growing_union);
      $verbose and print STDERR "Added set '$next_key' (contributes $new new members ($percent% percent of its $next_size members), growing_union now has $union_size members.\n";
      print STDOUT "$next_key\t$next_size\t$new\t$union_size\n";
   }
   else
   {
      defined($remfp) and print $remfp "$next_key\t$next_size\talgorithm ($percent > $tol)\n";
   }

   delete($set_keys_remaining{$next_key});
   delete($set_order{$next_key});
}

exit(0);

# sub by_decreasing_size
# {
#    return $$b[1] <=> $$a[1];
# }


__DATA__
syntax: set_covering.pl [OPTIONS] < SETS_MATRIX

The method prints out a list of set names that have been selected based on
coverage criteria.

SETS_MATRIX contains a tab-delimited list of sets.  The first column should contain
the keys to the elements that can belong to sets while the first row should contain
a header with the keys to the set names.  Each column then contains a binary
vector denoting which members are in the set.

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Compare the values in column COL to the threshold in the file (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of row headers to HEADERS (default is 1).

-max SIZE: Set the maximum set size to include to SIZE (default is 500).  Set this to -1
           for no restriction on maximum size.

-min SIZE: Set the minimum set size to include to SIZE (default is 10).  Set this to -1
           for no restriction on minimum size.

-tol TOLERANCE: Set the tolerance for intersections to TOLERANCE (default is 50%).

-rem FILE: Write which sets were removed to file FILE.

-ign FILE: File containing names of sets to ignore.

-union Compute intersection on growing growing_union (default computes it between individual sets)

-nosort: Do not sort the sets by size, preserve the original order as they were read in.


