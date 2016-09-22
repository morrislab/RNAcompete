#!/usr/bin/perl

use strict;
use warnings;

my %rev = ();
$rev{"A"} = "T";
$rev{"C"} = "G";
$rev{"G"} = "C";
$rev{"T"} = "A";
$rev{"N"} = "N";

while(<>)
{
   chomp;
   my @tabs = split (/\t/);
   $_ = shift (@tabs);
   my @seq = reverse (split (//));

   my @rev_seq = ();
   foreach (@seq) {
      push (@rev_seq, $rev{$_});
   }
   
   print @rev_seq;
   print "\t";
   print (join ("\t", @tabs));
   print "\n";
}

exit(0);

