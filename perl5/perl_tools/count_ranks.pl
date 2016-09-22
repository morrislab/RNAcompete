#!/usr/local/bin/perl

##############################################################################
##############################################################################
##
## count_ranks.pl
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
                , [    '-d', 'scalar',  "\t", undef]
                , [ '-perc', 'scalar', undef, undef]
                , [  '-max', 'scalar', undef, undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose       = not($args{'-q'});
my $field         = $args{'-f'} - 1;
my $delim         = $args{'-d'};
my $perc_inc      = $args{'-perc'};
my $max_supplied  = $args{'-max'};
my $file          = $args{'--file'};
my @extra         = @{$args{'--extra'}};

my $max_rank = undef;

open(FILE, $file) or die("Could not open file '$file' for reading");
my @ranks;
while(<FILE>)
{
   my @x = split($delim, $_);

   chomp($x[$#x]);

   my $rank = $x[$field];

   if(not(&isMissing($rank)))
   {
      if(defined($max_supplied))
      {
         if($rank <= $max_supplied)
         {
            push(@ranks, $rank);
         }
      }
      else
      {
         if(not(defined($max_rank)) or ($rank > $max_rank))
         {
            $max_rank = $rank;
         }
         push(@ranks, $rank);
      }
   }
}
close(FILE);

$max_rank = defined($max_supplied) ? $max_supplied : $max_rank;

@ranks = sort {$a <=> $b;} @ranks;

if(defined($perc_inc))
{
   &convert2Percentiles(\@ranks, $max_rank);
}

# print join("\n", @ranks);

my ($beg, $end, $inc) = defined($perc_inc) ? (0,100,$perc_inc) : (1,$max_rank,1);

my $num = scalar(@ranks);

my $total = $num;

for(my $i = $beg; $i <= $end; $i += $inc)
{
   my $cutoff = $end - $i + $beg;

   for(; $ranks[$num-1] > $cutoff and $num > 0; $num--) {}

   my $cut = defined($perc_inc) ? &formatPercent($i) : "$cutoff";

   my $perc = &formatPercent($num / $total * 100);

   # my @x = splice(@ranks, 0, $num);

   print STDOUT $cut, $delim, $perc, $delim, $num, "\n";

   # splice(@ranks, 0, 0, @x);
}

exit(0);

sub formatPercent
{
   my ($perc) = @_;

   my $str = sprintf("%.5f", $perc);

   $str =~ s/(\.[1-9]*)[0]+$/$1/;

   $str =~ s/\.$//;

   return $str;
}

sub convert2Percentiles
{
   my ($ranks, $max) = @_;

   for(my $i = 0; $i < scalar(@{$ranks}); $i++)
   {
      $$ranks[$i] = ($$ranks[$i] - 1) / ($max - 1) * 100;
   }
}

sub isMissing
{
   my ($val) = @_;

   my $result = 0;

   if($val eq 'NA' or $val eq 'NaN' or $val !~ /\S/)
   {
      $result = 1;
   }

   return $result;
}

__DATA__
syntax: count_ranks.pl [OPTIONS] [FILE | < FILE]

This program counts how many items of a certain rank there are,
and prints out the rank and percentile. It handles tiebreaks.

Try running it on a column of data, hopefully with a few values
that are the same, so you can see how ties are handled.

************************************************************
**
** NOTE: If you are just trying to rank a bunch of items,
** or to get the percentiles for various items,
** you probably want to use "rank_items.pl" instead of this file.
**
************************************************************

OPTIONS are:

-q: Quiet mode (default is verbose)

-f COL: Set the key column to COL (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-perc INC: Instead of trying all rank cutoffs, try percentile cutoffs
           ranging from 0% to 100% and use an increment step of INC.

-max RANK: Set the maximum rank to RANK (default uses the max seen in the file).

