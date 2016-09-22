#!/usr/bin/perl

##############################################################################
##############################################################################
##
## dijkstra.pl
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
use lib "$ENV{SYSBIOPERLLIB}";
use     strict;
use     warnings;
use     Heap::Priority;

# Flush output to STDOUT immediately.
$| = 1;


my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [   '-f1', 'scalar',     1, undef]
                , [   '-f2', 'scalar',     2, undef]
                , [    '-w', 'scalar', undef, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-u', 'scalar',     0,     1]
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
my $undirected   = $args{'-u'};
my $files        = $args{'--file'};

(defined($files) and scalar(@{$files})) == 2 or die("Please supply 2 files");

my %V; # all nodes
my %E; # all edges
my %Adj;
open(LINKS, $$files[0]) or die("Could not open links file '$$files[0]' for reading");
my $min_weight = undef;
my $max_weight = undef;
my $num_links  = 0;
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

   if($undirected) {
      $E{"$v\t$u"} = $w;
   }

   if(not(defined($Adj{$u}))) {
      my %nbrs;
      $Adj{$u} = \%nbrs;
   }
   my $adj_u = $Adj{$u};
   $$adj_u{$v} = 1;

   if(not(defined($Adj{$v}))) {
      my %nbrs;
      $Adj{$v} = \%nbrs;
   }
   my $adj_v = $Adj{$v};
   $$adj_v{$u} = 1;


   if(not(defined($min_weight)) or $w < $min_weight) {
      $min_weight = $w;
   }
   if(not(defined($max_weight)) or $w > $max_weight) {
      $max_weight = $w;
   }
   $num_links++;
}
close(LINKS);

# Make sure there are no negative weights.
if($min_weight < 0) {
   foreach my $edge (keys(%E)) {
      $E{$edge} -= $min_weight - 1;
   }
   $max_weight -= $min_weight - 1;
}

my $infinity = $max_weight * $num_links + 1;

my $passify = 10;
my $iter = 0;

my %set; 
open(SET, $$files[1]) or die("Could not open set file '$$files[1]' for reading"); 
while(<SET>) { 
   $iter++;
   print STDERR "$iter.\n";
   my @x = split($delim, $_); 
   chomp($x[$#x]); 
   my $D = &computeAllPairs(\@x,\%V,\%E); 
   my @print_line; 
   for(my $i = 0; $i < scalar(@{$D}); $i++) { 
      my ($u,$v,$d) = @{$$D[$i]}; 
      my $dist = $d == $infinity ? "Inf" : "$d";
      push(@print_line, $node_print ? join($delim_out2,($u,$v,$dist)) : $dist); 
   }
   print STDOUT join($delim_out1,@print_line), "\n";

   if($iter % $passify == 0) {
      print STDERR "$iter.\n";
   }
} 
close(SET); 

exit(0);

sub computeAllPairs {

   my ($list, $nodeSet, $edgeSet) = @_;

   my @D;

   for(my $i = 0; $i < scalar(@{$list}) - 1; $i++) {

      my $u = $$list[$i];

      if(exists($$nodeSet{$u})) {
   
         print STDERR "$u\n";

         my ($d,$p) = &Dijkstra($nodeSet,$edgeSet,$u);

         for(my $j = $i + 1; $j < scalar(@{$list}); $j++) {

            my $v  = $$list[$j];

            if(exists($$nodeSet{$v})) {

               my $dist = defined($$d{$v}) ? $$d{$v} : 'Inf';

               push(@D, [$u,$v,$dist]);
            }
         }
      }
   }
   return \@D;
}

# Dijkstra's Algorithm with Heaps, from Coreman:

# Dijkstra(G,w,s)
#    InitializeSingleSource(G,s)
#    S <- 0
#    Q <- V[G]
#    while Q != {}
#       do u <- ExtractMin(Q)
#       S <- Union(S, {u})
#       for each vertex v in Adj[u]
#          do Relax(u,v,w)
#
sub Dijkstra {
   my ($V,$E,$s) = @_;

   my ($Q,$d,$p) = &InitializeSingleSource($V,$s);
   my $i = 0;
   while(defined(my $u = $Q->pop())) {
      my $adj_u = $Adj{$u};
      foreach my $v (keys(%{$adj_u})) {
         &Relax($E,$Q,$d,$p,$u,$v);
      }
      $i++;
      print STDERR "C::$i\n";
   }
   return ($d,$p);
}

# InitializeSingleSource(G,s)
#    for each vertex v in V[G]
#       do d[v] <- Infinity
#          p[v] <- NULL
#    d[s] <- 0
sub InitializeSingleSource {
   my ($V,$s) = @_;
   my $Q = Heap::Priority->new();
   $Q->lowest_first(); # set in low to high priority so small distances pop first.
   my (%d,%p);
   foreach my $v (keys(%{$V})) {
      if($v ne $s) {
         $Q->add($v,$infinity); 
         $d{$v} = $infinity;
         $p{$v} = undef;
      }
   }
   $Q->add($s,0);
   $d{$s} = 0;
   $p{$s} = undef;

   return ($Q,\%d,\%p);
}

# Relax(u,v,w)
#    if d[v] > d[u] + w(u,v)
#       then d[v] <- d[u] + w(u,v)
#          p[v] <- u
sub Relax {
   my ($E,$Q,$d,$p,$u,$v) = @_;
   my $fwd = "$u\t$v";
   my $rev = "$v\t$u";
   my $w1  = exists($$E{$fwd}) ? $$E{$fwd} : $infinity;
   my $w2  = exists($$E{$rev}) ? $$E{$rev} : $infinity;
   my $w   = not($undirected) ? $w1 : ($w1 < $w2 ? $w1 : $w2);
   if($$d{$v} > $$d{$u} + $w) {
      $$d{$v} = $$d{$u} + $w;
      $$p{$v} = $u;
      # $Q->modify_priority($v, $$d{$v});
      $Q->delete_item($v);
      $Q->add($v, $$d{$v});
   }
}


__DATA__
syntax: dijkstra.pl [OPTIONS] LINKS SET

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

-u: Treat the graph as an undirected graph.


