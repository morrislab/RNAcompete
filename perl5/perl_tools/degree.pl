#!/usr/bin/perl

##############################################################################
##############################################################################
##
## degree.pl - Returns the degree of each node.
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

my $verbose       = not($args{'-q'});
my $field1        = $args{'-1'} - 1;
my $field2        = $args{'-2'} - 1;
my $delim         = $args{'-d'};
my $headers       = $args{'-h'};
my $file          = $args{'--file'};
my @extra         = @{$args{'--extra'}};

my %out;
my %in;
my @keys;
open(FILE, $file) or die("Could not open file '$file' for reading");
while(<FILE>)
{
   my @x = split($delim, $_);

   chomp($x[$#x]);

   my $key1 = $x[$field1];

   my $key2 = $x[$field2];

   my $seenin1  = exists($in{$key1});

   my $seenout1 = exists($out{$key1});

   my $seenin2  = exists($in{$key2});

   my $seenout2 = exists($out{$key2});

   if(not($seenin1) and not($seenout1))
   {
      push(@keys, $key1);
   }

   if(not($seenin2) and not($seenout2))
   {
      push(@keys, $key2);
   }

   $out{$key1}++;

   $in{$key2}++;

   if(not($seenin1))
   {
      $in{$key1} = 0;
   }

   if(not($seenout2))
   {
      $out{$key2} = 0;
   }
}
close(FILE);

foreach my $key (@keys)
{
   my $out_deg = $out{$key};

   my $in_deg  = $in{$key};

   my $deg     = $out_deg + $in_deg;

   print STDOUT $key, $delim, $deg, $delim, $out_deg, $delim, $in_deg, "\n";
}

exit(0);


__DATA__
syntax: degree.pl [OPTIONS] [FILE | < FILE]

OPTIONS are:

-q: Quiet mode (default is verbose)

-1 COL: Set the key column to COL (default is 1).

-2 COL: Set the key column to COL (default is 2).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 0).



