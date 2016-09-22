#!/usr/bin/perl

##############################################################################
##############################################################################
##
## connectivity.pl
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
                  [    '-q', 'scalar',     0,     1]
                , [   '-k1', 'scalar',     1, undef]
                , [   '-k2', 'scalar',     2, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-u', 'scalar',     0,     1]
                , [    '-U', 'scalar', undef, undef]
                , [    '-h', 'scalar',     1, undef]
                , [    '-n', 'scalar', undef, undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose    = not($args{'-q'});
my $key_col1   = $args{'-k1'} - 1;
my $key_col2   = $args{'-k2'} - 1;
my $delim      = $args{'-d'};
my $undirected = $args{'-u'};
my $univ_file  = $args{'-U'};
my $headers    = $args{'-h'};
my $node_out   = $args{'-n'};
my @extra      = @{$args{'--extra'}};

scalar(@extra) == 2 or die("Please supply a GRAPH and a NODES file");

$verbose and print STDERR "Reading in graph.\n";
my $graph       = &graphReadEdgeList($extra[0], $delim, $key_col1, $key_col2, not($undirected));
$graph          = $undirected ? &graphUndirected($graph) : $graph;
my $num_sources = &setSize(&graphSources($graph));
my $num_targets = &setSize(&graphTargets($graph));
my $total_edges = &setsSumSizes($graph);
$verbose and print STDERR "Done reading in graph ($num_sources sources, $num_targets targets, $total_edges edges).\n";

$verbose and print STDERR "Reading in members.\n";
my @set_lines = @{&readFileName($extra[1])};
my $num_selected_sets  = scalar(@set_lines);
$verbose and print STDERR "Done reading in members ($num_selected_sets selection sets).\n";

my $node_file = undef;
defined($node_out) and (open($node_file, ">$node_out") or die("Could not open node output file '$node_out'"));

my $nodes = &graphNodes($graph);

my $num_nodes = &setSize($nodes);

my $total_pairs = ($num_nodes * $num_nodes - $num_nodes) / ($undirected ? 2 : 1);

print STDOUT       "Set",
             "\t", "PredictivePower",
             "\t", "Coverage",
             "\t", "Set Size",
             "\t", "Self Nodes",
             "\t", "Non-member Nodes",
             "\t", "Self Edges",
             "\t", "Non-member Edges",
             "\n";

defined($node_file) and
   print $node_file "Node\tSet\tInSet\tEdges In\tTotal Edges\tFraction In\n";

my $universe = undef;
if(defined($univ_file) and (-f $univ_file))
{
   $verbose and print STDERR "Reading in universe file.";
   $universe = &list2Set(&listRead($univ_file));
   $verbose and print STDERR "Done reading in universe file.";
}

foreach my $set_line (@set_lines)
{
   my ($set_name, @members) = split("\t", $set_line);

   my $set           = &list2Set(\@members);

   $set              = defined($universe) ? &setIntersection($universe, $set) : $set;

   my $set_size      = &setSize($set);

   my $subgraph      = &setIntersection($graph, $set);

   my $member_edges    = 0;

   my $nonmember_edges = 0;

   my %member_nodes;

   my %nonmember_nodes;

   my %reachable;

   foreach my $node (keys(%{$subgraph}))
   {
      my $nbrs = $$graph{$node};

      my $edges_in = 0;

      my $edges_out = 0;

      $reachable{$node} = 1;

      foreach my $nbr (keys(%{$nbrs}))
      {
         $reachable{$nbr} = 1;

         if(exists($$set{$nbr}))
         {
            $member_nodes{$nbr} = 1;
            $edges_in++;
         }
         else
         {
            $nonmember_nodes{$nbr} = 1;
            $edges_out++;
         }
      }

      $member_edges += $edges_in;

      $nonmember_edges += $edges_out;
   }

   if(defined($node_file))
   {
      foreach my $node (keys(%reachable))
      {
         my $nbrs = $$graph{$node};

         my $edges_in = 0;

         my $edges_out = 0;

         foreach my $nbr (keys(%{$nbrs}))
         {
            if(exists($$set{$nbr}))
            {
               $edges_in++;
            }
            else
            {
               $edges_out++;
            }
         }

         my $is_member = exists($$set{$node}) ? 'y' : 'n';

         my $total     = $edges_out + $edges_in;

         my $fract_in = $edges_in / $total;

         print $node_file "$node\t$set_name\t$is_member\t$edges_in\t$total\t$fract_in\n";
      }
   }

   my $member_num       = scalar(keys(%member_nodes));

   my $nonmember_num    = scalar(keys(%nonmember_nodes));

   my $total_edges      = $member_edges + $nonmember_edges;

   my $predictive_power = $total_edges > 0 ? sprintf("%.2f", $member_edges / $total_edges * 100.0) : '100';

   my $coverage         = $set_size > 0 ? sprintf("%.2f", $member_num / $set_size * 100.0) : '0';

   $verbose and print STDERR "$set_name\t$predictive_power\t$coverage\t$set_size\t$member_num\t$nonmember_num\t$member_edges\t$nonmember_edges\n";

   print STDOUT "$set_name\t$predictive_power\t$coverage\t$set_size\t$member_num\t$nonmember_num\t$member_edges\t$nonmember_edges\n";
}

defined($node_file) and close($node_file);

exit(0);


__DATA__
syntax: connectivity.pl [OPTIONS] GRAPH NODES

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Set the key column to COL (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 1).

-n NODEFILE: Output results for each node to NODEFILE.

-u: Treat the graph as undirected (default is directed).

-U UNIVERSE: Specify that the items in the file UNIVERSE constitute the entire
             set of node IDs possible (default assumes the union of all nodes
             in the graph and the supplied sets constitutes the universe).


