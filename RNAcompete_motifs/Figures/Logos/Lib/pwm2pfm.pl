#!/usr/bin/perl

use strict;
use warnings;

$_ = <>;
print;

while(<>)
{
   chomp;
   my @tabs = split (/\t/);

   my $pos = shift (@tabs);

   my $sum = 0;
   foreach (@tabs) {
      $sum+=$_;
   }

   print "$pos";
   foreach (@tabs) {
      my $v = $_/$sum;
      print "\t$v";
   }
   print "\n";
}

exit(0);


