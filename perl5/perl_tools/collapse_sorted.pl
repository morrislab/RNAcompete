#!/usr/bin/perl

use strict;
use warnings;

my $entries = "";
my $prev_id = "";
my $cur_id = "";
while(<>)
{
   chomp;
   my @tabs = split (/\t/);

   $cur_id = "$tabs[0]\t$tabs[1]";
   shift (@tabs);
   shift (@tabs);

   if ($cur_id eq $prev_id) {
      $entries .= "\t";
      $entries .= join ("\t", @tabs);
   } else {
      print "$prev_id\t$entries\n";
      $entries = join ("\t", @tabs);
      $prev_id = $cur_id;
   }
}

print "$prev_id\t$entries\n";

exit(0);


