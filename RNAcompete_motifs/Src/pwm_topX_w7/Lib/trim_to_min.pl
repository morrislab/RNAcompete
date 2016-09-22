#!/usr/bin/perl

my $MIN_TRIM_PCT = 0.50;

use strict;
use warnings;

while(<>)
{
   chomp;
   my @tabs = split (/\t/);
   print "$tabs[0]\n" if (($tabs[1]/$tabs[2]) >= $MIN_TRIM_PCT);
}

exit(0);
