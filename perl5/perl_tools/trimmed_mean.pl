#!/usr/bin/perl

##############################################################################
##############################################################################
##
## trimmed_mean.pl
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

use strict;
use warnings;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-k', 'scalar',     1, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-h', 'scalar',     0, undef]
                , [    '-l', 'scalar',     0, undef]
                , [    '-p', 'scalar',    10, undef]
                , [  '-log', 'scalar',     0,     1]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose   = not($args{'-q'});
my $col       = int($args{'-k'}) - 1;
my $delim     = $args{'-d'};
my $headers   = $args{'-h'};
my $lowest    = $args{'-l'};
my $take_log  = $args{'-log'};
my $trim_perc = $args{'-p'};
my $file      = $args{'--file'};

my $lineno    = 0;

my $filep;
open($filep, $file) or die("Could not open file '$file' for reading");
while(<$filep>)
{
   $lineno++;

   if($lineno > $headers)
   {
      my @x = split($delim, $_);

      chomp($x[$#x]);

      my $key  = splice(@x, $col, 1);

      &setMissingIfLess(\@x, $lowest, '');

      my $ok   = &getNonMissing(\@x);

      my $mean = &getTrimmedMean($ok, $trim_perc);

      &normByTrimmedMean(\@x, $mean);

      if($take_log)
      {
         &takeLog2(\@x);
      }

      splice(@x, $col, 0, $key);

      print STDOUT join($delim, @x), "\n";
   }
   else
   {
      print;
   }
}
close($filep);

exit(0);

sub setMissingIfLess
{
   my ($x, $lowest, $missing_val) = @_;

   $missing_val = defined($missing_val) ? $missing_val : undef;

   my $n = scalar(@{$x});

   for(my $i = 0; $i < $n; $i++)
   {
      if(not(&isBlank($$x[$i])) and ($$x[$i] <= $lowest))
      {
         $$x[$i] = $missing_val;
      }
   }
}

sub takeLog2
{
   my ($x) = @_;

   my $n = scalar(@{$x});

   for(my $i = 0; $i < $n; $i++)
   {
      if(not(&isBlank($$x[$i])) and ($$x[$i] > 0))
      {
         $$x[$i] = log($$x[$i]) / log(2);
      }
   }
}

sub getTrimmedMean
{
   my ($x, $percent) = @_;

   my $trimmed = &trim($x, $percent);

   my $mean = &getMean($trimmed);

   return $mean;
}

sub getMean
{
   my ($x) = @_;

   my $n = scalar(@{$x});

   my $num = 0;

   my $sum = 0;

   for(my $i = 0; $i < $n; $i++)
   {
      if(not(&isBlank($$x[$i])))
      {
         $num += 1;

         $sum += $$x[$i];
      }
   }

   my $mean = $num > 0 ? ($sum / $num) : undef;

   return $mean;
}

sub normByTrimmedMean
{
   my ($x, $m) = @_;

   if(not(defined($m)))
   {
      return;
   }

   if($m == 0)
   {
      return;
   }

   my $n = scalar(@{$x});

   for(my $i = 0; $i < $n; $i++)
   {
      if(not(&isBlank($$x[$i])))
      {
         $$x[$i] /= $m;
      }
   }
}

sub getNonMissing
{
   my ($x) = @_;

   my $n = scalar(@{$x});

   my @y;

   for(my $i = 0; $i < $n; $i++)
   {
      if(not(&isBlank($$x[$i])))
      {
         push(@y, $$x[$i]);
      }
   }

   return \@y;
}

sub isBlank
{
   my ($v) = @_;

   if(not(defined($v)))
   {
      return 1;
   }

   if($v =~ /\S/)
   {
      return 0;
   }

   return 1;
}

sub trim
{
   my ($x, $percent) = @_;

   $percent = defined($percent) ? $percent : 10;

   my @trimmed;

   my $fraction = $percent / 100 / 2;

   my @sorted = sort { $a <=> $b; } @{$x};
   # my @sorted = sort byNumber @{$x};

   my $num    = scalar(@sorted);

   if($num > 0)
   {
      my $l  = int(($num - 1) * $fraction);

      my $h  = $num - $l - 1;

      my $lo = $sorted[$l];

      my $hi = $sorted[$h];

      for(my $i = 0; $i < $num; $i++)
      {
	 if(defined($sorted[$i]))
	 {
	    if($sorted[$i] >= $lo and $sorted[$i] <= $hi)
	    {
	       push(@trimmed, $sorted[$i]);
	    }
	 }
      }
   }

   return \@trimmed;
}

sub byNumber
{
   my $result = 1;

   if(defined($a) and defined($b))
   {
      $result = $a <=> $b;
   }

   elsif(defined($a))
   {
      $result = -1;
   }

   return $result;
}

__DATA__
syntax: trimmed_mean.pl [OPTIONS]

Finds the trimmed mean of each row and then divides each entry
by the trimmed mean.

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Compare the values in column COL to the threshold in the file (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Sets the number of header lines to HEADERS (default is 0).


