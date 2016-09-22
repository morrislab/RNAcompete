#!/usr/bin/perl

##############################################################################
##############################################################################
##
## limit_graph.pl
##
##############################################################################
##############################################################################
##
## Written by Josh Stuart.
##
##  Email address: jstuart@ucsc.edu
##          Phone: (650) 725-7612
##
## Postal address: Department of Bioengineering, UCSC
##                 1156 High Street
##                 Santa Cruz, CA 95060
##
##       Web site: http://www.soe.ucsc.edu/~jstuart/
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
                , [    '-f', 'scalar', undef, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-u', 'scalar',     0,     1]
                , [    '-n', 'scalar', undef, undef]
                , [    '-e', 'scalar', undef, undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose    = not($args{'-q'});
my $max_nodes  = $args{'-n'};
my $max_edges  = $args{'-e'};
my $fields     = $args{'-f'};
my $delim      = $args{'-d'};
my $undirected = $args{'-u'};
my $file       = $args{'--file'};

my @cols;
my $prev_cols = 0;
my %nodes;
my %edges;
my $num_nodes = 0;
my $num_edges = 0;

my @check_cols = &parseRanges($fields, 10000, -1);

if(scalar(@check_cols) != 2)
{
   die("You must supply 2 columns");
}

my $filep;
open($filep, $file) or die("Could not open file '$file' for reading");
while(<$filep>)
{
   my @tuple_all = split($delim);

   my $num_cols = scalar(@tuple_all);

   if(defined($fields))
   {
      if($num_cols != $prev_cols)
      {
         @cols = &parseRanges($fields, $num_cols, -1);
      }
   }
   if($#tuple_all >= 0)
     { chomp($tuple_all[$#tuple_all]); }

   my $u    = $tuple_all[$cols[0]];
   my $v    = $tuple_all[$cols[1]];
   my $e_uv = $u . $delim . $v;
   my $e_vu = $v . $delim . $u;

   my $newn = not(exists($nodes{$u})) + not(exists($nodes{$v}));

   if(not(defined($max_nodes)) or ($num_nodes+$newn <= $max_nodes))
   {
      my $newe = 0;

      if(not(exists($edges{$e_uv})) or 
         ($undirected and not(exists($edges{$e_vu}))))
      {
         $newe = 1;
      }

      if(not(defined($max_edges)) or ($num_edges+$newe <= $max_edges))
      {
         print;

         $edges{$e_uv} = 1;

         if($undirected)
         {
            $edges{$e_vu} = 1;
         }

         $nodes{$u} = 1;

         $nodes{$v} = 1;
      }
      else
      {
         exit(0);
      }

      $num_edges += $newe;

      $num_nodes += $newn;
   }

   $prev_cols = $num_cols;
}
close($filep);

exit(0);

__DATA__
syntax: limit_graph.pl [OPTIONS]

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Compare the values in column COL to the threshold in the file (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-n MAX: Set the maximum number of nodes to MAX (default is inf).

-e MAX: Set the maximum number of edges to MAX (default is inf).

-u: The graph is undirected (count u->v and v->u as the same edge).
    Default assumes the graph is directed.



