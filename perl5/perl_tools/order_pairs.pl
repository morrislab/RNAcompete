#!/usr/bin/perl

##############################################################################
##############################################################################
##
## order_pairs.pl
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
                , [    '-s', 'scalar',     3, undef]
                , [    '-k', 'scalar', undef, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-h', 'scalar',     0, undef]
                , [ '-pair', 'scalar',     0,     1]
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
my $fieldsim      = $args{'-s'} - 1;
my $delim         = $args{'-d'};
my $headers       = $args{'-h'};
my $printPair     = $args{'-pair'};
my $file          = $args{'--file'};
my @extra         = @{$args{'--extra'}};

my %keys;
my @data;

open(FILE, $file) or die("Could not open file '$file' for reading");
while(<FILE>)
{
   my @x = split($delim, $_);

   chomp($x[$#x]);

   my $key1 = $x[$field1];

   my $key2 = $x[$field2];

   my $sim  = $x[$fieldsim];

   push(@data, [$key1, $key2, $sim]);

   $keys{$key1} = 1;

   $keys{$key2} = 1;

}

@data = sort { $$b[2] <=> $$a[2]; } @data;

print STDERR   "The most similar pair is"
             , " ($data[0][0],$data[0][1])"
             , " with similarity $data[0][2]."
             , "\n"
             , "The most dissimilar pair is"
             , " ($data[-1][0],$data[-1][1])"
             , " with similarity $data[-1][2]."
             , "\n";

my $pivot = 0;
my $side  = 0;
my $key   = $data[$pivot][$side];

&printItOut(\@data, $pivot, $side, $printPair);

delete($keys{$data[$pivot][$side]});

while(scalar(keys(%keys)) > 0)
{
   ($pivot,$side) = &findMostSimilar(\@data, $key, \%keys);

   $pivot = defined($pivot) ? $pivot : 0;

   $side  = defined($side) ? $side : 0;

   $key   = $data[$pivot][$side];

   &printItOut(\@data, $pivot, $side, $printPair);

   delete($keys{$key});

   splice(@data, $pivot, 1);
}

exit(0);

sub findMostSimilar
{
   my ($data, $key, $keys) = @_;

   for(my $i = 0; $i < scalar(@{$data}); $i++)
   {
      if(($$data[$i][0] eq $key) and
         exists($keys{$$data[$i][1]}))
      {
         return ($i,1);
      }
      if(($$data[$i][1] eq $key) and
         exists($keys{$$data[$i][0]}))
      {
         return ($i,0);
      }
   }
   return (undef, undef);
}

sub printItOut
{
   my ($data, $pivot, $side, $full) = @_;

   print STDOUT $$data[$pivot][$side];
   if($full)
   {
      print STDOUT   "\t$$data[$pivot][0]"
                   , "\t$$data[$pivot][1]"
                   , "\t$$data[$pivot][2]"
                   , "\t$pivot"
                   , "\t$side"
                   ;
   }
   print STDOUT "\n";
}


__DATA__
syntax: order_pairs.pl [OPTIONS] [FILE | < FILE]

OPTIONS are:

-q: Quiet mode (default is verbose)

-f COL: Set the key column to COL (default is 1).

-k COL: Same as -f.

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 1).

-pair: Print out the pairs with the keys.

