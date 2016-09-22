#!/usr/bin/perl

require "libfile.pl";

use strict;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',           0,     1]
                , [  '-max', 'scalar',           0,     1]
                , [  '-pre', 'scalar','component_', undef]
                , ['-fasta', 'scalar',           0,     1]
                , ['--file', 'scalar',         '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose   = not($args{'-q'});
my $print_max = $args{'-max'};
my $prefix    = $args{'-pre'};
my $fasta     = $args{'-fasta'};
my $file      = $args{'--file'};

my %nodes2ids;
my @ids2nodes;
my $num_nodes = 0;

my @edges;

open(FILE, "<$file");
while(<FILE>)
{
  chop;

  my @row = split(/\t/);

  my $node1 = &add_node($row[0]);
  my $node2 = &add_node($row[1]);

  $edges[$node1][$node2] = 1;
  $edges[$node2][$node1] = 1;
}

my %handled_nodes;
my @component_sizes;
my $n = 0;

for (my $i = 0; $i < $num_nodes; $i++)
{
  if (not(exists($handled_nodes{$i})))
  {
    $n++;

    if ($print_max == 0) {
       if($fasta) {
          print STDOUT '>', $prefix, "$n\n";
       }
       else {
          print STDOUT $prefix, "$n";
       }
    }
    &expand_node($i);
    if(not($fasta)) {
       print STDOUT "\n";
    }
  }
}

if ($print_max == 1)
{
   my $max = 0;
   for (my $i = 0; $i < @component_sizes; $i++)
   {
     if ($component_sizes[$i] > $max) { $max = $component_sizes[$i]; }
   }
   print STDOUT "$max\n";
}

sub expand_node
{
  my ($node_id) = @_;

  if (not(exists($handled_nodes{$node_id})))
  {
    $handled_nodes{$node_id} = "1";

    if ($print_max == 0) {
       if($fasta) {
          print STDOUT "$ids2nodes[$node_id]\n";
       }
       else {
          print STDOUT "\t$ids2nodes[$node_id]";
       }
    }

    $component_sizes[$n - 1]++;

    for (my $i = 0; $i < $num_nodes; $i++)
    {
      if ($edges[$node_id][$i] == 1)
      {
         &expand_node($i);
      }
    }
  }
}

sub add_node
{
  my ($node_name) = @_;

  my $node_id = $nodes2ids{$node_name};

  if (length($node_id) == 0)
  {
    $nodes2ids{$node_name} = $num_nodes;
    $ids2nodes[$num_nodes] = $node_name;
    $num_nodes++;
  }

  $node_id = $nodes2ids{$node_name};

  return $node_id;
}


__DATA__

connected_components.pl [OPTIONS] [FILE | < FILE]

   Computes the connected components of the data file.
   Each line in the data file corresponds to an edge 
   between the keys in the first two columns of the data file.

OPTIONS are:

  -max:        If specified, then just prints the size of the largest component.

  -pre PREFIX: Prepend each component name with PREFIX (default is "component_").

  -fasta:      Print FASTA formatted output. Otherwise print transposed lists.


