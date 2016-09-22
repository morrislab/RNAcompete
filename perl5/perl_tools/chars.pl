#!/usr/bin/perl

##############################################################################
##############################################################################
##
## chars.pl - Prints out the characters contained in a file.
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

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @chars;
my %counts;
while(<>)
{
   my @x = split("");

   foreach my $char (@x)
   {
      if(not(exists($counts{$char})))
      {
         push(@chars, $char);
      }
      $counts{$char}++;
   }
}

foreach my $char (@chars)
{
   my $count = $counts{$char};

   print STDOUT "$char\t$count\n";
}

exit(0);


__DATA__
syntax: skeleton.pl [FILE | < FILE]

