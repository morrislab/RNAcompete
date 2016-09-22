#!/usr/bin/perl

use strict;
use warnings;

warn "heyo!\n";
warn join("::",@ARGV),"\n";


my $add =shift;
$add = 1 if !$add;

$_ = <STDIN>;
print;
while(<STDIN>)
{
   chomp;
   my @tabs = split (/\t/);

   my $id = shift (@tabs);
   my $tot = $tabs[-1];
   $tot += ($add*4);

   print "$id";
   foreach (@tabs) {
      my $v = ($_+$add)/$tot;
      print "\t$v";
   }
   print "\n";
}

exit(0);


