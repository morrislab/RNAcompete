#!/usr/bin/perl

##############################################################################
##############################################################################
##
## link_entropy.pl
##
##############################################################################
##############################################################################
##
## Written by Josh Stuart.
##
##  Email address: jstuart@ucsc.edu
##          Phone: (831) 459-1344
##
## Postal address: Department of Biomolecular Engineering
##                 Baskin Engineering 129
##                 University of California, Santa Cruz
##                 Santa Cruz, CA 95064
##
##############################################################################

require "libfile.pl";
require "$ENV{MYPERLDIR}/lib/libgraph.pl";
require "$ENV{MYPERLDIR}/lib/libstats.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [     '-q', 'scalar',     0,     1]
                , [     '-1', 'scalar',     1, undef]
                , [     '-2', 'scalar',     2, undef]
                , [   '-cut', 'scalar',     0, undef]
                , ['-filter', 'scalar',     0,     1]
                , [     '-d', 'scalar',  "\t", undef]
                , [   '-dir', 'scalar',     0,     1]
                , [     '-h', 'scalar',     0, undef]
                , [ '--file',   'list',    [], undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 0)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose  = not($args{'-q'});
my $key_col1 = $args{'-1'} - 1;
my $key_col2 = $args{'-2'} - 1;
my $cutoff   = $args{'-cut'};
my $filter   = $args{'-filter'};
my $delim    = $args{'-d'};
my $headers  = $args{'-h'};
my $directed = $args{'-dir'};
my @files    = @{$args{'--file'}};

scalar(@files) == 2 or die "Please supply both two files.";

$verbose and print STDERR "Reading in graph from file '$files[0]'...";
my $graph  = &graphReadEdgeList($files[0], $delim, $key_col1, $key_col2, $directed);
$verbose and print STDERR " done.\n";

$verbose and print STDERR "Reading in groups from file '$files[1]'...";
my $groups = &setsRead($files[1], $delim);
$verbose and print STDERR " done.\n";

my @group_names = keys(%{$groups});

my @group_sizes;
foreach my $group (@group_names)
{
   push(@group_sizes, [$group, &setSize($$groups{$group})]);
}
@group_sizes = sort { $$b[1] <=> $$a[1]; } @group_sizes;

# Count the number of connections each node has into each group.
my @nodes = keys(%{&graphNodes($graph)});

print "Node\tEntropy\tNum Groups\tNum Nbrs";
# for(my $i = 0; $i < @group_sizes; $i++)
# {
#    my $group = $group_sizes[$i][0];
# 
#    print "\t$group";
# }
print "\n";

foreach my $node (@nodes)
{
   my @printable;

   my @nbrs = keys(%{$$graph{$node}});

   my @group_counts;

   my $num_signif_groups = 0;

   for(my $i = 0; $i < scalar(@group_sizes); $i++)
   {
      $group_counts[$i] = 0;

      my $group_name = $group_sizes[$i][0];

      my $group = $$groups{$group_name};

      # Count how many of this node's neighbors are in group i.
      foreach my $nbr (@nbrs)
      {
         $group_counts[$i] += exists($$group{$nbr}) ? 1 : 0;
      }

      if($group_counts[$i] >= $cutoff)
      {
         $num_signif_groups++;
      }
      elsif($filter)
      {
         $group_counts[$i] = 0;
      }
   }

   my $entropy = &shannon_entropy(\@group_counts);

   print STDOUT $node
                , "\t", $entropy
                , "\t", $num_signif_groups
                , "\t", scalar(@nbrs)
#               , "\t", join($delim, @group_counts)
                , "\n";
}

exit(0);

__DATA__
syntax: link_entropy.pl [OPTIONS] LINKS_FILE GROUP_FILE

LINKS_FILE - contains a list of edges.  Each line has a single
pair of tab-delimited nodes.

GROUP_FILE - contains a list of groups to which the nodes belong.
Each line contains a key to a node and a group that it belongs
(these should be tab-delimited).

OPTIONS are:

-q: Quiet mode (default is verbose)

-1 COL: Set the column for the first node to column COL (default is 1).

-2 COL: Same as -1 but for the second node (default is 2).

-cut CUTOFF: Set the cutoff (default 0).  If a node has fewer
             than this number of connections to a group then
             its connectivity to the group is deemed
             insignificant.

-filter: If turned on, then the CUTOFF supplied by the -cut
         option is used to filter out connections to insignificant
         groups.  By default all groups are included in the 
         entropy calculation.

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 1).

-dir: Specify that the graph is directed (default is undirected).


