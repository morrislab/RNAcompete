#!/usr/bin/perl

##############################################################################
##############################################################################
##
## sort.pl
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
                , [    '-r', 'scalar',     0,     1]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose       = not($args{'-q'});
my $fields        = defined($args{'-k'}) ? $args{'-k'} : $args{'-f'};
my $delim         = $args{'-d'};
my $headers       = $args{'-h'};
my $reverse       = $args{'-r'};
my $file          = $args{'--file'};
my @extra         = @{$args{'--extra'}};

my @data;

my @cols;

my $prev_cols = 0;

open(FILE, $file) or die("Could not open file '$file' for reading");
while(<FILE>)
{
   chomp;

   my @tuple = split($delim);

   my $num_cols = scalar(@tuple);

   if(defined($fields))
   {
      if($num_cols != $prev_cols)
      {
         @cols = &parseRanges($fields, $num_cols, -1);
      }
   }

   my @x;

   foreach my $i (@cols)
   {
      if($i <= $#tuple)
      {
         push(@x, $tuple[$i]);
      }
   }

   push(@data, [$_, \@x]);

   $prev_cols = $num_cols;
}

close(FILE);

if($reverse)
{
   @data = sort fancyCompareRev @data;
}
else
{
   @data = sort fancyCompare @data;
}

for(my $i = 0; $i < scalar(@data); $i++)
{
   print $data[$i][0], "\n";
}

exit(0);

sub fancyCompare
{
   my $x = $$a[1];

   my $y = $$b[1];

   my $n = scalar(@{$x});

   my $m = scalar(@{$y});

   return &fancyCompareRecursive($x, $y, 0, ($n > $m ? $m : $n), 0);
}

sub fancyCompareRev
{
   my $x = $$a[1];

   my $y = $$b[1];

   my $n = scalar(@{$x});

   my $m = scalar(@{$y});

   return &fancyCompareRecursive($x, $y, 0, ($n > $m ? $m : $n), 1);
}

sub fancyCompareRecursive
{
   my ($x, $y, $i, $n, $rev) = @_;

   my $result;

   if($i >= $n)
   {
      $result = 0;
   }
   elsif(&isEmpty($$x[$i]) and &isEmpty($$y[$i]))
   {
      $result = &fancyCompareRecursive($x, $y, $i+1, $n, $rev);
   }
   elsif(&isEmpty($$y[$i]))
   {
      $result = -1;
   }
   elsif(&isEmpty($$x[$i]))
   {
      $result = 1;
   }
   elsif($$x[$i] == $$y[$i])
   {
      $result = &fancyCompareRecursive($x, $y, $i+1, $n, $rev);
   }
   else
   {
      $result = ($rev ? -1 : 1) * ($$x[$i] > $$y[$i] ? 1 : -1);
   }
   return $result;
}

sub isEmpty
{
   my ($x) = @_;

   return (not(defined($x))
          or ($x =~ 'NaN')
          or ($x !~ /\S/))
          ;
}

__DATA__
syntax: sort.pl [OPTIONS] [FILE | < FILE]

OPTIONS are:

-q: Quiet mode (default is verbose)

-f COL: Set the key column to COL (default is 1).

-k COL: Same as -f.

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 1).



