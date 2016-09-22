#!/usr/bin/perl

##############################################################################
##############################################################################
##
## scramble_links.pl
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

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [   '-f1', 'scalar',     1, undef]
                , [   '-f2', 'scalar',     2, undef]
                , [    '-k', 'scalar', undef, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-h', 'scalar',     0, undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose       = not($args{'-q'});
my $field1        = $args{'-f1'} - 1;
my $field2        = $args{'-f2'} - 1;
my $delim         = $args{'-d'};
my $headers       = $args{'-h'};
my $file          = $args{'--file'};
my @extra         = @{$args{'--extra'}};

my $num_links = 0;
my %nodes;
open(FILE, $file) or die("Could not open file '$file' for reading");
while(<FILE>)
{
   my @x = split($delim, $_);

   chomp($x[$#x]);

   my $key1 = $x[$field1];

   my $key2 = $x[$field2];

   $nodes{$key1} = 1;

   $nodes{$key2} = 1;

   $num_links++;
}
close(FILE);

# Add 1 link for each node to get minimum.

my @nodes = keys(%nodes);

my $num_nodes = scalar(@nodes);

my @degree;

for(my $i = 0; $i < $num_nodes; $i++)
{
   $degree[$i] = 0;
}

my %edges;

for(my $i = 0; $i < $num_nodes; $i++)
{
   if($degree[$i] == 0)
   {
      my $u = $nodes[$i];
      my $j = 1 + int(rand($num_nodes-1));
      $j    = $j == $i ? 0 : $j;
      my $v = $nodes[$j];

      print STDOUT $u, $delim, $v, "\n";

      $edges{$i,$j} = 1;
      $degree[$i]++;
      $degree[$j]++;
      $num_links--;
   }
}

for(my $e = 0; $e < $num_links; $e++)
{
   my $i = int(rand($num_nodes));
   my $j = 1 + int(rand($num_nodes-1));
   $j    = $j == $i ? 0 : $j;

   if(not(exists($edges{$i,$j})))
   {
      my $u = $nodes[$i];
      my $v = $nodes[$j];
      print STDOUT $u, $delim, $v, "\n";
   }
   else
   {
      $e--;
   }
}

exit(0);


__DATA__
syntax: skeleton.pl [OPTIONS] [FILE | < FILE]

OPTIONS are:

-q: Quiet mode (default is verbose)

-f COL: Set the key column to COL (default is 1).

-k COL: Same as -f.

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 1).



