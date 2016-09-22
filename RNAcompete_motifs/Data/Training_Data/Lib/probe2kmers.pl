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

   my $id  = shift (@tabs);
   my $seq = shift (@tabs);
   my @seq = split (//, $seq);
   my $score = shift (@tabs);

#	print $id,$seq,$score,"\n";

   my %ids = ();
   for (my $i=0; $i<scalar @seq-$len+1; $i++) {
      my $cur = substr ($seq, $i, $len);
      print "$id\t$cur\t$score\n";
   }

}

exit(0);


