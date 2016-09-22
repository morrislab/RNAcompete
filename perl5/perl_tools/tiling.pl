#!/usr/bin/perl

##############################################################################
##############################################################################
##
## tiling.pl
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
                  [     '-q', 'scalar',     0,     1]
                , [     '-U', 'scalar', undef, undef]
                , [     '-N', 'scalar', undef, undef]
                , [     '-P', 'scalar', undef, undef]
                , [     '-I', 'scalar',     0,     1]
                , [     '-S', 'scalar', undef, undef]
                , [     '-M', 'scalar', undef, undef]
                , [    '-kt', 'scalar',     1, undef]
                , [    '-ks', 'scalar',     1, undef]
                , [    '-dt', 'scalar',  "\t", undef]
                , [    '-ds', 'scalar',  "\t", undef]
                , [    '-ht', 'scalar',     0, undef]
                , [    '-hs', 'scalar',     0, undef]
                , [    '-mt', 'scalar',     0,     1]
                , [    '-ms', 'scalar',     0,     1]
                , [    '-it', 'scalar',     0,     1]
                , [    '-is', 'scalar',     0,     1]
                , [  '-mems', 'scalar',     0,     1]
                , [     '-p', 'scalar',  .001, undef]
                , ['-ignore',   'list',    [], undef]
                , [  '-list', 'scalar',     0,     1]
                , [ '--file',   'list', ['-'], undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose       = not($args{'-q'});
my $U             = $args{'-U'};
my $N             = $args{'-N'};
my $I             = $args{'-I'};
my $P             = $args{'-P'};
my $max_tile_size = $args{'-S'};
my $max_tiles     = $args{'-M'};
my $key_col_tiles = $args{'-kt'} - 1;
my $key_col_sets  = $args{'-ks'} - 1;
my $delim_tiles   = $args{'-dt'};
my $delim_sets    = $args{'-ds'};
my $headers_tiles = $args{'-ht'};
my $headers_sets  = $args{'-hs'};
my $matrix_tiles  = $args{'-mt'};
my $matrix_sets   = $args{'-ms'};
my $invert_tiles  = $args{'-it'};
my $invert_sets   = $args{'-is'};
my $is_list       = $args{'-list'};
my $output_mems   = $args{'-mems'};
my $pval_cut      = log($args{'-p'}) / log(10);
my @ignore_files  = @{$args{'-ignore'}};
my @files         = @{$args{'--file'}};


scalar(@files) == 2 or die("Please supply two files");

$verbose and print STDERR "Reading in the tiles-standard classification.\n";
my $tiles = &setsReadLists($files[0], $delim_tiles, $key_col_tiles,
                        $headers_tiles, undef, undef, $invert_tiles);
my $num_tiles = &setSize($tiles);
$verbose and print STDERR "Done ($num_tiles sets read).\n";

$verbose and print STDERR "Reading in the sets classification.\n";
my $sets = undef;
if($is_list)
{
   $verbose and print STDERR "Reading in a list of genes.\n";
   my ($list, $header) = &listRead($files[1], undef, undef, undef, $headers_sets);
   $header = length($header) > 0 ? $header : 'anonymous';
   chomp($header);

   my %set;
   $set{$header} = &list2Set($list);

   $sets = \%set;
   $verbose and print STDERR "Done.\n";
}
else
{
   $sets = &setsReadLists($files[1], $delim_sets, $key_col_sets,
                          $headers_sets, undef, undef, $invert_sets);
}

my $num_sets = &setSize($sets);
$verbose and print STDERR "Done ($num_sets sets read).\n";

if(defined($U) and ((-f $U) or (-l $U)))
{
   $verbose and print STDERR "Reading in the universe from '$U'.\n";
   my $universe = &setRead($U);
   $verbose and print STDERR "Done reading in the universe from '$U'.\n";

   $tiles = &setsReduceBySet($tiles, $universe);

   $sets  = &setsReduceBySet($sets, $universe);

   $N     = &setSize($universe);
}

my $union_tiles  = undef;
my $union_sets   = undef;
my $intersection = undef;

if(not(defined($N)))
{
   if(defined($P))
   {
      $verbose and print STDERR "Reading population from '$P'.\n";
      my %population;
      $population{'pop'} = &list2Set(&listRead($P));
      $N = &setSize($population{'pop'});
      $verbose and print STDERR "Population size = $N.\n";

      $verbose and print STDERR "Reducing sets to population.\n";
      &setsReduce($sets, \%population);
      $verbose and print STDERR "Done.\n";

      $verbose and print STDERR "Reducing tiles to population.\n";
      &setsReduce($tiles, \%population);
      $verbose and print STDERR "Done.\n";
   }
   elsif($I)
   {
      $intersection = &setsReduce($sets, $tiles);

      $N = &setSize($intersection);

      $intersection = &setsReduce($tiles, $sets);

   }
   else
   {
      $N = &setSize(&setUnion(&setsUnionSelf($tiles), &setsUnionSelf($sets)));
   }
}

$verbose and print STDERR "Population Size = $N.\n";

foreach my $ignore_file (@ignore_files)
{
   open(IGNORE, $ignore_file) or die("Could not open ignore file '$ignore_file'");
   while(<IGNORE>)
   {
      chomp;
      delete($$tiles{$_});
   }
   close(IGNORE);
}

if(defined($max_tile_size))
{
   if($max_tile_size > 0 and $max_tile_size < 1)
   {
      $max_tile_size = int($N * $max_tile_size);
   }

   foreach my $tile_key (keys(%{$tiles}))
   {
      my $size = &setSize($$tiles{$tile_key});

      if($size > $max_tile_size)
      {
         $verbose and print STDERR "Removing tile '$tile_key' it has more members than the max ($size > $max_tile_size).\n";

         delete($$tiles{$tile_key});
      }
   }
}

my $passify = 1;
my $iter = 0;
my $total = $num_sets * $num_tiles;
foreach my $key_sets (@{&setMembersList($sets)})
{
   my $set = $$sets{$key_sets};

   my $tiles_copy = &setCopy($tiles);

   my $num_tiles = 0;

   not($output_mems) and
      print STDOUT ">$key_sets (Size = ", &setSize($set), ")\n";

   $verbose and print STDERR "\n>$key_sets\n";

   my $prev_pval = undef;

   while((not(defined($pval_cut)) or not(defined($prev_pval)) or $prev_pval < $pval_cut) and
         (&setSize($set) > 0) and
         (&setSize($tiles_copy) > 0) and
         (not(defined($max_tiles)) or $num_tiles < $max_tiles))
   {
      my $results = &setsOverlap($set, $tiles_copy, $N, $pval_cut, 1);

      if(defined($results) and defined($$results[0]))
      {
         $num_tiles++;

         my ($best_tiles_key, $pval, $o, $d, $s, $pop) = @{$$results[0]};

         my $best_tile_set = $$tiles_copy{$best_tiles_key};

         my $best_members = &setIntersection($best_tile_set, $set);

         if($pval < $pval_cut)
         {
            pop(@{$$results[0]});

            $verbose and print STDERR join(",",@{$$results[0]}), "\n";

            if(not($output_mems))
            {
               print STDOUT join(",",@{$$results[0]}), "\n";
            }
            else
            {
               foreach my $member (keys(%{$best_members}))
               {
                  print STDOUT $member, $delim_sets,
                               $key_sets, $delim_sets,
                               $best_tiles_key, $delim_sets,
                               $num_tiles, "\n";
               }
            }

            # Remove these members from the set.
            $set = &setDifference($set, $best_tile_set);

            # Remove this set from the tiles sets
            delete($$tiles_copy{$best_tiles_key});

            $verbose and print STDERR "$key_sets $best_tiles_key\n";
         }

         $prev_pval = $pval;
      }
      else
      {
         $prev_pval = 0;
      }
   }
   if($output_mems)
   {
      foreach my $member (keys(%{$set}))
      {
         print STDOUT $member, $delim_sets,
                               $key_sets, $delim_sets,
                               'NaN', $delim_sets,
                               "NaN\n";
      }
   }
}

exit(0);


__DATA__
syntax: tiling.pl [OPTIONS] TILES SETS

Determines the composition of a SETS classification in terms of another gold-standard
classification.  The script iteratively finds the best overlapping set from the
TILES sets that captures the remaining elements in a set from the SETS
classification.

TILES - Gold-standard classification

SETS - Test classification

OPTIONS are:

-q: Quiet mode (default is verbose)

-N NUM: Set the population size to NUM.  (default is the intersection between the
        union of the TILES and the union of the SETS).

-U UNIVERSE: Set the universe of elements to UNIVERSE.  UNIVERSE should be
             a file containing a list of members (1 for each line).

-I: Use the intersection between the union of the TILES and the union of the SETS
    for the population size (default uses the union of both).

-S SIZE: Set the maximum tile size used for the TILES.  Any
        tile set that is larger will be ignored.  If MAX is
        a value between 0 and 1 then it is interpreted as a
        fraction of the population size.

-M MAX_TILES: Set the maximum number of tiles to associate to
              members in SETS.  This is only relevant when
              the -mems flag is set.

-kt COL: Set the key column to COL (default is 1).

-ks COL: Same as -kt but for the SETS file.

-dt DELIM: Set the field delimiter to DELIM (default is tab).

-ds DELIM: Same as -dg but for the SETS file.

-ht HEADERS: Set the number of header lines to HEADERS (default is 0).

-hs HEADERS: Same as -hg but for the SETS file.

-mt: The TILES classification is in matrix format (default is list format)

-ms: Same as -mg but for the SETS file.

-it: The TILES file contains an inverted listing with members down the first
     column and sets across.

-is: Same as -it but for the SETS file.

-ignore FILE: Supply a list of sets to ignore in the TILING.

-list: The SETS file is actually a list of genes containing a single set.

-mems: By default, the script prints out the overlap statistics.
       If this is set it prints out which tile each member
       of the test set belongs to in the gold set in
       increasing order of overlap significance.

-p PVAL_CUT: P value cutoff. Overlaps with P values bigger than
             PVAL_CUT are ignored (default is 0.001).
