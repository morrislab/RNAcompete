#!/usr/bin/perl

use strict;
use warnings;

$_ = <>;
print;
while(<>)
{
   chomp;
   my @tabs = split (/\t/);

   my $id = shift (@tabs);
   my $tot = $tabs[-1];

   print "$id";
   foreach (@tabs) {
      my $v = ($_)/$tot;
      print "\t$v";
   }
   print "\n";
}

exit(0);


