#!/usr/bin/perl

##############################################################################
##############################################################################
##
## intersect_sets.pl
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

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',        0,     1]
                , [    '-k', 'scalar',        1, undef]
                , [    '-d', 'scalar',     "\t", undef]
                , [    '-h', 'scalar',        1, undef]
                , [    '-m', 'scalar',        1, undef]
                , [    '-p', 'scalar', 'matrix', undef]
                , ['--file',   'list',    ['-'], undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose    = not($args{'-q'});
my $key_col    = $args{'-k'};
my $delim      = $args{'-d'};
my $headers    = $args{'-h'};
my $mem_val    = $args{'-m'};
my $print_type = $args{'-p'};
my @files      = @{$args{'--file'}};

my %sizes;

$key_col--;

scalar(@files) > 1 or die("Please supply at least 2 files");

$verbose and print STDERR "Reading sets from file '$files[0]'.\n";
my $intersection = &setsReadMatrix($files[0], $mem_val, $delim, $key_col, $headers);
$sizes{$files[0]} = &setSize($intersection);
$verbose and print STDERR "Done ($sizes{$files[0]} members read).\n";
for(my $i = 1; $i < scalar(@files); $i++)
{
   $verbose and print STDERR "$i. Reading sets from file '$files[$i]'.\n";
   my $sets = &setsReadMatrix($files[$i], $mem_val, $delim, $key_col, $headers);
   $verbose and print STDERR "$i. Done reading file '$files[$i]'.\n";

   $sizes{$files[$i]} = &setSize($sets);

   $verbose and print STDERR "$i. Taking the intersection between the sets.\n";
   $intersection  = &setsIntersection($intersection, $sets);
   my $inter_size = &setSize($intersection);
   $verbose and print STDERR "Done ($sizes{$files[$i]} members read, intersection=$inter_size).\n";
}

if($print_type eq 'matrix')
{
   &setsPrintMatrix($intersection);
}

elsif($print_type eq 'counts')
{
   foreach my $set_key (keys(%{$intersection}))
   {
      my $intersection_size = &setSize($$intersection{$set_key});
      print STDOUT $set_key, "\t", $intersection_size;
      for(my $i = 0; $i < scalar(@files); $i++)
      {
         my $size = $sizes{$files[$i]};
         print STDOUT "\t$size";
      }
      print STDOUT "\n";
   }
}

exit(0);


__DATA__
syntax: intersect_sets.pl [OPTIONS] SETS1 SETS2 [SETS3...]

SETS1 and SETS2 are membership matrices with sets listed across the columns of the
file.  The script assumes the first line contains a header that provides a key for
each set.  The first column in each file should contain the key to an element.


