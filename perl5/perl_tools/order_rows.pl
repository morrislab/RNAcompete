#!/usr/bin/perl

##############################################################################
##############################################################################
##
## order_rows.pl
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
require "$ENV{MYPERLDIR}/lib/libstats.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',         0,     1]
                , [    '-f', 'scalar',         1, undef]
                , [    '-k', 'scalar',     undef, undef]
                , [    '-d', 'scalar',      "\t", undef]
                , [    '-h', 'scalar',         0, undef]
                , [    '-m', 'scalar', 'pearson', undef]
                , ['--file', 'scalar',       '-', undef]
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
my $metric        = $args{'-m'};
my $file          = $args{'--file'};
my @extra         = @{$args{'--extra'}};

my $line_no = 0;
my $header = '';
my @data;
my @keys;
my $rows = 0;
open(FILE, $file) or die("Could not open file '$file' for reading");
while(<FILE>)
{
   $line_no++;

   if($line_no > $headers)
   {
      my @x = split($delim, $_);

      chomp($x[$#x]);

      my $key  = splice(@x, $field, 1);

      $data[$rows] = \@x;

      $keys[$rows] = $key;

      $rows++;
   }
   else
   {
      $header = $_;
   }
}
close(FILE);

my $current = 0;
my $next    = 0;

my @ordered;
my @ordered_keys;
while(@data)
{
   push(@ordered, splice(@data, $current, 1));
   push(@ordered_keys, splice(@keys, $current, 1));

   # Set next
   my $best = undef;
   for(my $i = 0; $i < @data; $i++)
   {
      my $measure = &getMetric($ordered[$#ordered], $data[$i], $metric);
      if(not(defined($best)) or &isBetter($measure, $best, $metric))
      {
         $best = $measure;
         $next = $i;
      }
   }

   $current = $next;
}

print $header;

for(my $i = 0; $i < @ordered; $i++)
{
   my $key = $ordered_keys[$i];

   my @x   = @{$ordered[$i]};

   splice(@x, $field, 0, $key);

   print join($delim, @x), "\n";
}

exit(0);

sub getMetric
{
   my ($x, $y, $metric) = @_;

   my $measure = undef;

   if($metric =~ /pearson/i)
   {
      $measure = &vec_pearson($x, $y);
   }
   elsif($metric =~ /dot/i)
   {
      $measure = &dot_product($x, $y);
   }
   return $measure;
}

sub isBetter
{
   my ($x, $y, $metric) = @_;

   my $result = 0;

   if(not(defined($x)))
   {
      return 0;
   }

   if(not(defined($y)))
   {
      return 1;
   }

   if($metric =~ /(pearson)|(dot)/i)
   {
      $result = $x > $y ? 1 : 0;
   }

   return $result;
}


__DATA__
syntax: order_rows.pl [OPTIONS] [FILE | < FILE]

OPTIONS are:

-q: Quiet mode (default is verbose)

-f COL: Set the key column to COL (default is 1).

-k COL: Same as -f.

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 1).



