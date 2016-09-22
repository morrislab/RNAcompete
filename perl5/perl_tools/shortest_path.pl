#!/usr/bin/perl

##############################################################################
##############################################################################
##
## shortest_path.pl
##
##############################################################################
##############################################################################
##
## Written by Josh Stuart.
##
##  Email address: jstuart@ucsc.edu
##          Phone: (650) 725-7612
##
## Postal address: Department of Bioengineering, VCSC
##                 1156 High Street
##                 Santa Cruz, CA 95060
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
                , [   '-f1', 'scalar',     1, undef]
                , [   '-f2', 'scalar',     2, undef]
                , [    '-w', 'scalar', undef, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [  '-do1', 'scalar',  "\t", undef]
                , [  '-do2', 'scalar',   ",", undef]
                , [    '-n', 'scalar',     0,     1]
                , ['--file',   'list', undef, undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose      = not($args{'-q'});
my $field1       = int($args{'-f1'}) - 1;
my $field2       = int($args{'-f2'}) - 1;
my $weight_field = defined($args{'-w'}) ? int($args{'-w'}) - 1 : undef;
my $delim        = $args{'-d'};
my $delim_out1   = $args{'-do1'};
my $delim_out2   = $args{'-do2'};
my $node_print   = $args{'-n'};
my $files        = $args{'--file'};

(defined($files) and scalar(@{$files})) == 2 or die("Please supply 2 files");

my %V; # all nodes
my %E; # all edges
open(LINKS, $$files[0]) or die("Could not open links file '$$files[0]' for reading");
while(<LINKS>)
{
   my @x = split($delim, $_);
   chomp($x[$#x]);
   my $u = $x[$field1];
   my $v = $x[$field2];
   my $w = (defined($weight_field) and defined($x[$weight_field])) ?
              $x[$weight_field] : 1;
   $E{"$u\t$v"}  = $w;
   $V{$u}        = 1;
   $V{$v}        = 1;
}
close(LINKS);

my %set; 
open(SET, $$files[1]) or die("Could not open set file '$$files[1]' for reading"); 
while(<SET>) { 
   my @x = split($delim, $_); 
   chomp($x[$#x]); 
   my $D = &computeAllPairs(\@x,\%V,\%E); 
   my @print_line; 
   for(my $i = 0; $i < scalar(@{$D}); $i++) { 
      my ($u,$v,$d) = @{$$D[$i]}; 
      push(@print_line, $node_print ? join($delim_out2,($u,$v,$d)) : $d); 
   }
   print STDOUT join($delim_out1,@print_line), "\n";
} 
close(SET); 


exit(0);

sub computeAllPairs {
   my ($list, $nodeSet, $edgeSet) = @_;
   my @D;
   for(my $i = 0; $i < scalar(@{$list}) - 1; $i++) {
      my $u = $$list[$i];

      if(exists($$nodeSet{$u})) {
         for(my $j = $i + 1; $j < scalar(@{$list}); $j++) {
            my $v  = $$list[$j];

            if(exists($$nodeSet{$v})) {
               my $V_ = &setRemove($nodeSet, [$u, $v]);

               my $d  = &shortestDistance($V_, $edgeSet, $u, $v);

               $d = defined($d) ? $d : '-Inf';

               push(@D, [$u,$v,$d]);
            }
         }
      }
   }
   return \@D;
}

sub shortestDistance
{
   my ($V, $E, $u, $v, $depth) = @_;

   $depth = defined($depth) ? $depth : 0;

   my $size = &setSize($V);

   print STDERR "Depth=$depth, Size=$size, $u -> $v\n";

   # Initialize the shortest path to the weight of the
   # edge connecting u and v.  If none exists then set
   # the distance to infinite (undef).

   my $min = exists($$E{"$u\t$v"}) ? $$E{"$u\t$v"} : undef;

   foreach my $w (keys(%{$V}))
   {
      my $V_   = &setRemove($V, [$w]);

      my $duw = &shortestDistance($V_, $E, $u, $w, $depth + 1);

      my $dwv = &shortestDistance($V_, $E, $w, $v, $depth + 1);

      my $duv = (defined($duw) and defined($dwv)) ? $duw + $dwv : undef;

      if(not(defined($min)) or
           (defined($duv) and ($duv < $min)))
      {
         $min = $duv;
      }
   }

   return $min;
}

__DATA__
syntax: shortest_path.pl [OPTIONS] LINKS SET

LINKS - has NODE1 <tab> NODE2 on each line indicating edges

SET - has a list of nodes on each line.  The shortest path will be computed
      between every pair of nodes in the set on each line.

OPTIONS are:

-q: Quiet mode (default is verbose)

-f1 COL: Read the first node from the LINKS file from column COL (default is 1)

-f2 COL: Read the second node from the LINKS file from column COL (default is 2)

-w  COL: Specify that column COL contains the weight of the edge.

-d DELIM: Set the field delimiter to DELIM (default is tab).

-n: Output the identifiers of the nodes in addition to the distances (default only
    outputs the distances of the pairs).

Dijkstra's Algorithm with Heaps:

    make a heap of values (vertex,edge,distance)
    initially (v,-,infinity) for each vertex
    let tree T be empty
    while (T has fewer than n vertices)
       let (v,e,d(v)) have the smallest weight in the heap
       remove (v,e,d(v)) from the heap
       add v and e to T
       set distance(s,v) to d(v)
       for each edge f=(v,u)
           if u is not already in T
              find value (u,g,d(u)) in heap
           if d(v)+length(f) < d(g)
              replace (u,g,d(g)) with (u,f,d(v)+length(f))

