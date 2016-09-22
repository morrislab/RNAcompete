#!/usr/bin/perl

##############################################################################
##############################################################################
##
## neighborhood_overlaps.pl
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
require "$ENV{MYPERLDIR}/lib/libset.pl";
require "$ENV{MYPERLDIR}/lib/libgraph.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-k', 'scalar',     1, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-h', 'scalar',     0, undef]
                , [    '-u', 'scalar',     0,     1]
                , ['--file',   'list', undef, undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose    = not($args{'-q'});
my $key_col    = $args{'-k'} - 1;
my $delim      = $args{'-d'};
my $headers    = $args{'-h'};
my $undirected = $args{'-u'};
my @files      = @{$args{'--file'}};

scalar(@files) >= 2 or die("Please supply two files");

# my $nhoods1 = &readNeighborhoods($files[0]);

print STDERR "Reading in first set of neighborhoods\n";
my $nhoods1 = &setsReadLists($files[0], $delim, $key_col, $headers);
$nhoods1    = $undirected ? &graphUndirected($nhoods1) : $nhoods1;
print STDERR "Done reading in first set of neighborhoods\n";

print STDERR "Reading in second set of neighborhoods\n";
my $nhoods2 = &setsReadLists($files[1], $delim, $key_col, $headers);
$nhoods2    = $undirected ? &graphUndirected($nhoods2) : $nhoods2;
print STDERR "Done reading in second set of neighborhoods\n";

foreach my $center (keys(%{$nhoods2}))
{
   my $score      = undef;

   my $inter_size = undef;

   my $union_size = undef;

   if(exists($$nhoods1{$center}))
   {
      my $nhood1       = $$nhoods1{$center};

      my $nhood2       = $$nhoods2{$center};

      my $union        = &setUnion($nhood1, $nhood2);

      $union_size      = &setSize($union);

      if($union_size > 0)
      {
         my $intersection = &setIntersection($nhood1, $nhood2);

         $inter_size      = &setSize($intersection);

         $score           = $inter_size / $union_size;
      }
   }

   my $print_score      = defined($score) ? "$score" : "NaN";

   my $print_inter_size = defined($inter_size) ? "$inter_size" : "NaN";

   my $print_union_size = defined($union_size) ? "$union_size" : "NaN";

   print STDERR "$center\t$print_score\t$print_inter_size\t$print_union_size\n";

   print STDOUT "$center\t$print_score\t$print_inter_size\t$print_union_size\n";
}

exit(0);

sub readNeighborhoods
{
   my ($file) = @_;
   my $filep = &openFile($file);
   my %nbrs;
   while(<$filep>)
   {
      my @x = split($delim);
      chomp($x[$#x]);
      my $center = $x[0];
      my $nbr    = $x[1];

      if(not(exists($nbrs{$center})))
      {

      }
   }
   close($filep);

   return \%nbrs;
}



__DATA__
syntax: neighborhood_overlaps.pl [OPTIONS] NBRHOODS1 NBRHOODS2

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Set the key column to COL (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 0).

-u: Make the input graphs undirected.


