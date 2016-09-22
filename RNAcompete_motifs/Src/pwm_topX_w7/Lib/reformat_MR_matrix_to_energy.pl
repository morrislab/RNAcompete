#!/usr/bin/perl

use strict;
use warnings;

while(<>)
{
   chomp;
   my @tabs = split (/\t/);

   my $id=shift (@tabs); 
   print "$id"; 
   my $d=$tabs[4]; 
   
   foreach (@tabs) {
      my $x=-log($_)-(-log($d)); 
#      my $x=-log($_);
      $x = 0 if ($x =~/e/);
      print "\t$x"; 
   } 
   
   print "\n"
}

exit(0);


