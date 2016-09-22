#!/usr/bin/perl

##############################################################################
##############################################################################
##
## neighbor_connectivity.pl
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
                , [    '-1', 'scalar',     1, undef]
                , [    '-2', 'scalar',     2, undef]
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

my $verbose  = not($args{'-q'});
my $field1   = $args{'-1'} - 1;
my $field2   = $args{'-2'} - 1;
my $delim    = $args{'-d'};
my $headers  = $args{'-h'};
my $file     = $args{'--file'};
my @extra    = @{$args{'--extra'}};

my %edges;
my %nbrs;
my @nodes;

open(FILE, $file) or die("Could not open file '$file' for reading");
while(<FILE>)
{
   my @x = split($delim, $_);

   chomp($x[$#x]);

   my $u = $x[$field1];

   my $v = $x[$field2];

   if(not(exists($nbrs{$u})))
   {
      $nbrs{$u} = [];

      push(@nodes, $u);
   }

   if(not(exists($nbrs{$v})))
   {
      $nbrs{$v} = [];

      push(@nodes, $v);
   }

   if(not(exists($edges{$u,$v})))
   {
      push(@{$nbrs{$u}}, $v);
      $edges{$u,$v} = 1;
   }
   if(not(exists($edges{$v,$u})))
   {
      push(@{$nbrs{$v}}, $u);
      $edges{$v,$u} = 1;
   }
}

close(FILE);

my $num_nodes = scalar(@nodes);

foreach my $u (@nodes)
{
   my $nbrs_u      = $nbrs{$u};

   my $num_nbrs  = scalar(@{$nbrs_u});

   my $nbr2nbr_connections = 0;

   my $num_total_connections = 0;

   for(my $i = 0; $i < $num_nbrs; $i++)
   {
      my $v = $$nbrs_u[$i];

      $num_total_connections += scalar(@{$nbrs{$v}});

      for(my $j = 0; $j < $num_nbrs; $j++)
      {
         my $w = $$nbrs_u[$j];

         if(exists($edges{$v,$w}))
         {
            $nbr2nbr_connections++;
         }
      }
   }

   my $nbr2nbr_possible = $num_nbrs * ($num_nbrs - 1) * 0.5;

   if($num_nbrs > 1)
   {
      my $nbr2nbr_fraction = $nbr2nbr_connections / $nbr2nbr_possible;

      # my $hub_score        = ($nbr2nbr_possible+$num_nbrs) / ($nbr2nbr_connections + $num_nbrs);
      my $hub_score        = $num_nbrs * $num_nbrs / ($nbr2nbr_connections + $num_nbrs);

      my $expect           = $num_nbrs / $num_nodes * $num_total_connections;

      print STDOUT   $u
                   , $delim, $num_nbrs
                   , $delim, $hub_score
                   , $delim, $nbr2nbr_fraction
                   , $delim, $nbr2nbr_connections
                   , $delim, $num_total_connections
                   , $delim, $nbr2nbr_connections / $expect
                   , "\n";
   }
   else
   {
      print STDOUT   $u
                   , $delim, $num_nbrs
                   , $delim, 'NaN'
                   , $delim, 'NaN'
                   , $delim, $nbr2nbr_connections
                   , $delim, $num_total_connections
                   , $delim, 1
                   , "\n";
   }
}

exit(0);


__DATA__
syntax: neighbor_connectivity.pl [OPTIONS] [FILE | < FILE]

OPTIONS are:

-q: Quiet mode (default is verbose)

-1 COL: Set the source column to COL (default is 1).

-2 COL: Set the target column to COL (default is 2).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 1).



