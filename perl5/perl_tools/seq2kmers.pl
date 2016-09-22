#!/usr/bin/perl

use strict;
use warnings;

my $file = shift @ARGV;
my $len = shift @ARGV || 7;

open(INSTREAM, $file) or die "couldn't open\n";

while(<INSTREAM>)
{
   chomp;
   my @tabs = split (/\s+/);

   my $seq = shift (@tabs);
   my @seq = split (//, $seq);

   for (my $i=0; $i<scalar @seq-$len+1; $i++) {
      my $cur = substr ($seq, $i, $len);
      print "$cur\t";
   }
   print "\n";

}

exit(0);


