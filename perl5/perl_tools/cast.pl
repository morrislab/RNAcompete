#!/usr/bin/perl

##############################################################################
##############################################################################
##
## cast.pl - The CAST algorithm of A. Ben-Dor and R. Shamir
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
require "$ENV{MYPERLDIR}/lib/libgraph.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;


my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-1', 'scalar',     1, undef]
                , [    '-2', 'scalar',     2, undef]
                , [    '-t', 'scalar',     1, undef]
                , [    '-w', 'scalar', undef, undef]
                , [  '-dir', 'scalar',     0,     1]
                , [    '-d', 'scalar',  "\t", undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose    = not($args{'-q'});
my $key_col1   = int($args{'-1'}) - 1;
my $key_col2   = int($args{'-2'}) - 1;
my $delim      = $args{'-d'};
my $thresh     = $args{'-t'};
my $dir        = $args{'-dir'};
my $weight_col = defined($args{'-w'}) ? $args{'-w'} : undef;
my $file       = $args{'--file'};

$verbose and print STDERR "Reading in graph from '$file'...";
my $graph = &graphReadEdgeList($file, $delim, $key_col1, $key_col2, $dir, "$weight_col");
$verbose and print STDERR " done.\n";

# my $v  = &graphMaxDegreeNode($graph);

# print STDOUT "$v\n";

# &graphPrint($graph, undef, undef, 1);

my %clusters = %{&graphCast($graph, $thresh, 1)};

foreach my $u (keys(%clusters))
{
   my $cluster = $clusters{$u};

   print STDOUT $u, $delim, $cluster, "\n";
}

exit(0);

__DATA__
syntax: cast.pl [OPTIONS]

OPTIONS are:

-q: Quiet mode (default is verbose)

-1 COL: The source node is in column COL (default is 1).

-2 COL: The target node is in column COL (default is 2).

-w COL: Set the weight column to COL.  The default is undef in
        which case the graph is considered to be unweighted.
        All connections in an unweighted graph are considered
        to equal 1 while unconnected nodes have weight 0.

-t THRESH: Set the similarity threshold.  Any link with weight
           equal to or greather than THRESH is considered to be
           connected.  Default is 1.

-dir: Treat the graph as directed (default is undirected).

-d DELIM: Set the field delimiter to DELIM (default is tab).


