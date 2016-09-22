#!/usr/bin/perl

##############################################################################
##############################################################################
##
## interleave.pl
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
                , [    '-f', 'scalar',     1, undef]
                , [    '-k', 'scalar', undef, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-h', 'scalar',     0, undef]
                , ['--file',   'list', ['-'], undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose       = not($args{'-q'});
my $field         = (defined($args{'-k'}) ? $args{'-k'} : $args{'-f'}) - 1;
my $delim         = $args{'-d'};
my $headers       = $args{'-h'};
my $files         = $args{'--file'};
my @extra         = @{$args{'--extra'}};

scalar(@{$files}) == 2 or die("Please supply two files");

open(FILE1, $$files[0]) or die("Could not open file '$$files[0]' for reading");
open(FILE2, $$files[1]) or die("Could not open file '$$files[1]' for reading");
my $more_in_both_files = 1;

my @lines1 = <FILE1>;

my @lines2 = <FILE2>;

close( FILE1 );

close( FILE2 );

my $n1 = scalar(@lines1);

my $n2 = scalar(@lines2);

my $n  = $n1 > $n2 ? $n1 : $n2;

for(my $i = 0; $i < $n; $i++)
{
   my @x = $i < $n1 ? split($delim, $lines1[$i]) : ();

   chomp($x[$#x]);

   my @y = $i < $n2 ? split($delim, $lines2[$i]) : ();

   chomp($y[$#y]);

   my $nx = scalar(@x);

   my $ny = scalar(@y);

   my $m  = $nx > $ny ? $nx : $ny;

   my @z;

   for(my $j = 0; $j < $m; $j++)
   {
      push(@z, $j < $nx ? $x[$j] : '');

      push(@z, $j < $ny ? $y[$j] : '');
   }

   print STDOUT join($delim, @z), "\n";
}

exit(0);


__DATA__
syntax: interleave.pl [OPTIONS] FILE1 FILE2

OPTIONS are:

-q: Quiet mode (default is verbose)

-f COL: Set the key column to COL (default is 1).

-k COL: Same as -f.

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 1).



