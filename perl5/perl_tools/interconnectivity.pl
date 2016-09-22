#!/usr/bin/perl

##############################################################################
##############################################################################
##
## interconnectivity.pl
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
require "$ENV{MYPERLDIR}/lib/libgraph.pl";
require "$ENV{MYPERLDIR}/lib/libset.pl";
require "$ENV{MYPERLDIR}/lib/libstats.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [     '-q', 'scalar',     0,     1]
                , [    '-k1', 'scalar',     1, undef]
                , [    '-k2', 'scalar',     2, undef]
                , [     '-d', 'scalar',  "\t", undef]
                , [     '-u', 'scalar',     0,     1]
                , [     '-U', 'scalar', undef, undef]
                , [     '-h', 'scalar',     1, undef]
                , [     '-s', 'scalar',     0,     1]
                , ['-strict', 'scalar',     0,     1]
                , [   '-max', 'scalar', undef, undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose        = not($args{'-q'});
my $key_col1       = $args{'-k1'} - 1;
my $key_col2       = $args{'-k2'} - 1;
my $delim          = $args{'-d'};
my $undirected     = $args{'-u'};
my $univ_file      = $args{'-U'};
my $headers        = $args{'-h'};
my $strict         = $args{'-strict'};
my $max_file       = $args{'-max'};
my $suppress_nodes = $args{'-s'};
my @extra          = @{$args{'--extra'}};

my $max_fp;

defined($max_file) and (open($max_fp, ">$max_file") or die("Could not open max file '$max_file'"));

scalar(@extra) == 3 or die("Please supply a GRAPH and two NODES files");

$verbose and print STDERR "Reading in graph from '$extra[0]'.\n";
my $graph_f     = &graphReadEdgeList($extra[0], $delim, $key_col1, $key_col2, not($undirected));
my $graph_r     = &graphReverse($graph_f);
my $graph_u     = &setsUnion($graph_f, $graph_r);
$graph_f        = $undirected ? $graph_u : $graph_f;
$graph_r        = $undirected ? $graph_u : $graph_r;
my $num_sources = &setSize($graph_f);
my $num_targets = &setSize($graph_r);
my $total_edges = &setsSumSizes($graph_u);
$verbose and print STDERR "Done reading in graph ($num_sources sources, $num_targets targets, $total_edges edges).\n";

$verbose and print STDERR "Reading in NODES1 members from '$extra[1]'.\n";
my @set_lines1 = @{&readFileName($extra[1])};
my $num_selected_sets  = scalar(@set_lines1);
$verbose and print STDERR "Done reading in NODES1 members ($num_selected_sets selection sets).\n";

$verbose and print STDERR "Reading in NODES2 members from '$extra[2]'.\n";
my @set_lines2 = @{&readFileName($extra[2])};
$num_selected_sets  = scalar(@set_lines2);
$verbose and print STDERR "Done reading in NODES2 members ($num_selected_sets selection sets).\n";

my $universe = undef;
if(defined($univ_file) and (-f $univ_file))
{
   $verbose and print STDERR "Reading in universe file.\n";
   $universe = &list2Set(&listRead($univ_file));
   $verbose and print STDERR "Done reading in universe file.\n";
}

my $nodes       = &setUnion(&setMembers($graph_f), &setMembers($graph_r));
my $num_nodes   = &setSize($nodes);
my $total_pairs = scalar(@set_lines1) * scalar(@set_lines2);

print STDOUT       "Set 1\tSet 2",
             "\t", "Score",
             "\t", "Interconnections",
             "\t", "Common Members",
             "\t", "Out Edges 1",
             "\t", "In Edges 2",
             "\t", "Size 1",
             "\t", "Size 2",
             "\n";

my $exclude = undef;

if($strict)
{
   my %sets1;
   my %sets2;
   foreach my $set_line (@set_lines1)
   {
      my ($set_name, @members) = split("\t", $set_line);
      my $set = &list2Set(\@members);
      $sets1{$set_name} = $set;
   }

   foreach my $set_line (@set_lines2)
   {
      my ($set_name, @members) = split("\t", $set_line);
      my $set = &list2Set(\@members);
      $sets2{$set_name} = $set;
   }
   $exclude = &setsUnion(\%sets1, \%sets2);
}

foreach my $set_line1 (@set_lines1)
{
   my $max        = 0;
   my $max_common = 0;
   my $max_in     = 0;
   my $max_out    = 0;
   my $max_score  = 0;
   my $max_set    = undef;
   my $max_nbrs   = undef;

   my ($set_name1, @members1) = split("\t", $set_line1);

   my $set1         = &list2Set(\@members1);
   $set1            = defined($universe) ? &setIntersection($universe, $set1) : $set1;

   foreach my $set_line2 (@set_lines2)
   {
      my ($set_name2, @members2) = split("\t", $set_line2);

      if($set_name1 ne $set_name2)
      {
         my $set2      = &list2Set(\@members2);
         $set2         = defined($universe) ? &setIntersection($universe, $set2) : $set2;
         my $intersect = &setIntersection($set1, $set2);
         my $common    = &setSize($intersect);

         my $diff1     = &setDifference($set1, $set2);
         my $diff2     = &setDifference($set2, $set1);

         my $size1     = &setSize($diff1);
         my $size2     = &setSize($diff2);

         # my $union         = &setUnion($set1, $set2);
         # my $subgraph      = &setIntersection($graph_f, $union);

         my ($interconnections1, $out_edges1, $connectors1) = &graphConnections($graph_f, $diff1, $diff2, $exclude);
         my ($interconnections2, $in_edges2, $connectors2)  = &graphConnections($graph_r, $diff2, $diff1, $exclude);

         my $edges = $out_edges1 + $in_edges2;
         my $score = $edges > 0 ? $interconnections1 / $edges * 100.0 * 0.50 : 0;

         print STDOUT "$set_name1\t$set_name2\t$score\t$interconnections1\t$common\t$out_edges1\t$in_edges2\t$size1\t$size2",
                      ($suppress_nodes ? "" : ("\t" . join("\t", keys(%{$connectors1})))), "\n";

         if($score >= $max_score)
         {
            $max        = $interconnections1;
            $max_common = $common;
            $max_out    = $out_edges1;
            $max_in     = $in_edges2;
            $max_score  = $score;
            $max_set    = $set_name2;
            $max_nbrs   = $connectors1;
         }
      }
   }

   $verbose and print STDERR "[$max_score,$max,$max_common,$max_out,$max_in]\t$set_name1 -> $max_set\n";

   if($set_name1 ne $max_set)
   {
      defined($max_fp) and $max > 0 and print $max_fp "$set_name1\t$max_set\t$max_score\t$max\t$max_common\t$max_out\t$max_in\t", join("\t", keys(%{$max_nbrs})), "\n";
   }
}

defined($max_fp) and close($max_fp);

exit(0);


__DATA__
syntax: interconnectivity.pl [OPTIONS] GRAPH NODE_SETS1 NODE_SETS2

Reports how the nodes from NODE_SETS1 connect to the nodes in each
of the sets in NODE_SETS2.

For each pair of sets, it prints out:

SET1, SET2, INTERCONNECTIONS, COMMON, OUT_EDGES1, IN_EDGES2, SIZE1, SIZE2

SET1, SET2       - The name of the sets being compared.
SCORE            - An interconnectivity score =
                   INTERCONNECTIONS / (OUT_EDGES1 + IN_EDGES2) * 100 / 2
INTERCONNECTIONS - The number of edges that originate from some node in
                   SET1 and terminate on some node in SET2.
COMMON           - How many members the two sets have in common.  Note that
                   these members are actually removed before counting the
                   interconnectivity.
OUT_EDGES1       - The total number of edges out of nodes belonging to
                   SET1.
IN_EDGES2        - The total number of edges terminating on nodes
                   belonging to SET2.
SIZE1, SIZE2     - The number of nodes in SET1 and SET2 respectively.

Note there is directionality associated with the output.  To treat
edges as undirected use the -u option.

GRAPH      - tab-delimited list of edges
NODE_SETSi - each line has a different set of nodes (the first entry is
             the name of the set).

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Set the key column to COL (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 1).

-u: Treat the graph as undirected (default is directed).

-U UNIVERSE: Specify that the items in the file UNIVERSE constitute the entire
             set of node IDs possible (default assumes the union of all nodes
             in the graph and the supplied sets constitutes the universe).

-max FILE: For each set in NODE_SETS1 prints out which nodes connected to the
           maximum connecting set in NODE_SETS2.

-s: Suppress printing out the nodes that connect one set to the other.

-strict: Only count connections between members that do not occur in any set together.
         NOTE: the script is slower when running with this option.


