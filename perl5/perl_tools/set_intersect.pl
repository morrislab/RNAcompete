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

require "$ENV{MYPERLDIR}/lib/libset.pl";
require "libfile.pl";

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
my @files      = @{$args{'--file'}};

my %sizes;

$key_col--;

scalar(@files) > 1 or die("Please supply at least 2 files");

$verbose and print STDERR "Reading set from file '$files[0]'.\n";
my $intersection = &setRead($files[0], $delim, $key_col);
$sizes{$files[0]} = &setSize($intersection);
$verbose and print STDERR "Done ($sizes{$files[0]} members read).\n";
for(my $i = 1; $i < scalar(@files); $i++)
{
   $verbose and print STDERR "$i. Reading sets from file '$files[$i]'.\n";
   my $set = &setRead($files[$i], $delim, $key_col);
   $sizes{$files[$i]} = &setSize($set);
   $verbose and print STDERR "Done ($sizes{$files[$i]} members read).\n";

   $verbose and print STDERR "$i. Taking the intersection between the sets.\n";
   $intersection = &setIntersection($intersection, $set);
   my $isize = &setSize($intersection);
   $verbose and print STDERR "Done ($isize members in intersection).\n";

}

&setPrint($intersection);

exit(0);


__DATA__
syntax: set_intersect.pl [OPTIONS] SET1 SET2 [SET3...]

SET1 and SET2 are files containing set members in a single column.

-d DELIM: Set the delimiter to DELIM (default is tab)

-k COL: Set the member key to COL (default is 1)

