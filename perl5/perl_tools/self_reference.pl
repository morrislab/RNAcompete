#!/usr/bin/perl

##############################################################################
##############################################################################
##
## self_reference.pl
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
                , [    '-h', 'scalar',     1, undef]
                , [    '-e', 'scalar',     0,     1]
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
my $headers    = $args{'-h'};
my $node_out   = $args{'-n'};
my $expand     = $args{'-e'};
my @extra      = @{$args{'--extra'}};

scalar(@extra) == 2 or die("Please supply a GRAPH and a NODES file");

$verbose and print STDERR "Reading in graph.\n";
my $graph       = &graphReadEdgeList($extra[0], $delim, $key_col1, $key_col2, not($undirected));
my $graph_r     = &graphReverse($graph);
my $num_sources = &setSize($graph);
my $total_edges = &setsSumSizes($graph) / ($undirected ? 2 : 1);
my $num_targets = &setSize($graph_r);
$verbose and print STDERR "Done reading in graph ($num_sources sources, $num_targets targets, $total_edges edges).\n";

$verbose and print STDERR "Reading in selections.\n";
my @set_lines = @{&readFileName($extra[1])};
my $num_selected_sets  = scalar(@set_lines);
$verbose and print STDERR "Done reading in selections ($num_selected_sets selection sets).\n";

my $node_fp = undef;
defined($node_out) and (open($node_fp, ">$node_out") or die("Could not open node output file '$node_out'"));

# &graphPrint($graph);
# &graphPrint($graph_r);
# exit(0);

my $nodes = &setUnion(&setMembers($graph), &setMembers($graph_r));

my $num_nodes = &setSize($nodes);

my $total_pairs = ($num_nodes * $num_nodes - $num_nodes) / ($undirected ? 2 : 1);

print STDOUT       "Set",
             "\t", "Group Size",
             "\t", "Group Pairs",
             "\t", "Group Edges",
             "\t", "Group Self Edges",
             "\t", "Rep Factor",
             "\t", "P-value",
             "\t", "Expected",
             "\t", "Total Edges",
             "\t", "Total Pairs",
             "\n";

defined($node_fp) and
   print $node_fp "Node\tSet\tInStartingSet\tNode Edges\tSelf Edges\tRep Factor\tP-value\tExpected\tTotal Edges\tTotal Pairs\n";

foreach my $set_line (@set_lines)
{

   my ($set_name, @selections) = split("\t", $set_line);

   $verbose and print STDERR "Processing set '$set_name'\n";

   my $selected_set   = &list2Set(\@selections);

   my $intersection   = &setIntersection($graph, $selected_set);

   my $intersection_r = &setIntersection($graph_r, $selected_set);

   my $total_selected = &setSize($intersection);

   my $total_into_selected  = &setsSumSizes($intersection_r);

   my $component      = $expand ? &setUnion($intersection, &graphConnectedComponent($graph, $selected_set)) :
                        $intersection;

   my $component_r    = $expand ? &setUnion($intersection_r, &graphConnectedComponent($graph_r, $selected_set)) :
                        $intersection_r;

   my $grp_edges      = $undirected ? (&setsSumSizes(&setsUnion($component, $component_r))/2)
                        : &setsSumSizes($component);

   my $subset         = &setSubset($graph, $component);

   my $N              = &setSize(&setUnion($component, $component_r));

   my $self_possible = int($N * $N - $N);

   my %node_self_edges;

   my %node_edges;

   my $total_degree   = 0;

   my $total_self     = 0;

   foreach my $u (keys(%{$subset}))
   {
      my $V                  = $$subset{$u};
      my $self               = &setIntersection($$subset{$u}, $selected_set);
      my $self_size          = &setSize($self);
      my $V_size             = &setSize($V);
      $node_self_edges{$u}  += $self_size;
      $node_edges{$u}       += $V_size;

      foreach my $v (keys(%{$V}))
      {
         $node_edges{$v} += 1;
      }

      foreach my $v (keys(%{$self}))
      {
         $node_self_edges{$v} += 1;
      }

      $total_degree += $V_size;

      $total_self   += $self_size;
   }

   foreach my $u (keys(%{$subset}))
   {
      my $was_selected  = exists($$selected_set{$u}) ? 'y' : 'n';

      my $draws         = $node_edges{$u} / ($undirected ? 2 : 1);

      my $successes     = $node_self_edges{$u} / ($undirected ? 2 : 1);

      my $hyper         = &ComputeLog10HyperPValue($successes, $total_edges, $draws, $total_pairs);

      my $expected      = $total_edges / $total_pairs * $draws;

      my $rep_factor    = $expected > 0 ? ($successes / $expected) : 0;

      $hyper            = defined($hyper) ? -$hyper : 0;
      $hyper            = sprintf("%.3f", $hyper);
      $expected         = sprintf("%.3f", $expected);
      $rep_factor       = sprintf("%.3f", $rep_factor);

      defined($node_fp) and print $node_fp       $u,
                                           "\t", $set_name,
                                           "\t", $was_selected,
                                           "\t", $draws,
                                           "\t", $successes,
                                           "\t", $rep_factor,
                                           "\t", $hyper,
                                           "\t", $expected,
                                           "\t", $total_edges,
                                           "\t", $total_pairs,
                                           "\n";
   }

   my $draws      = $self_possible / ($undirected ? 2 : 1);

   my $successes  = $total_self / ($undirected ? 2 : 1);

   # my $hyper      = &ComputeLog10HyperPValue($successes, $total_edges, $draws, $total_pairs);
   #
   my $hyper      = &ComputeLog10HyperPValue($successes, $draws, $total_edges, $total_pairs);

   my $expected   = $total_edges / $total_pairs * $draws;

   my $rep_factor = $expected > 0 ? ($successes / $expected) : 0;

   $hyper         = defined($hyper) ? -$hyper : 0;

   $hyper         = sprintf("%.3f", $hyper);

   $expected      = sprintf("%.3f", $expected);

   $rep_factor    = sprintf("%.3f", $rep_factor);

   print STDOUT       $set_name,
                "\t", $N,
                "\t", $draws,
                "\t", $grp_edges,
                "\t", $successes,
                "\t", $rep_factor,
                "\t", $hyper,
                "\t", $expected,
                "\t", $total_edges,
                "\t", $total_pairs,
                "\n";

}

exit(0);


__DATA__
syntax: self_reference.pl [OPTIONS] GRAPH NODES

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Set the key column to COL (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 1).

-n NODEFILE: Output results for each node to NODEFILE.

-e: EXPAND the given set to neighbors.

