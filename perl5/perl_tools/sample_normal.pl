#!/usr/bin/perl

require "libfile.pl";
require "$ENV{MYPERLDIR}/lib/libstats.pl";

if ($ARGV[0] eq "--help") { print STDOUT <DATA>; }

my $delim = "\t";

my $sigs = 3;

my $rows = $#ARGV >= 0 ? shift(@ARGV) : 1;

my $cols = $#ARGV >= 0 ? shift(@ARGV) : 1;

my $mean = $#ARGV >= 0 ? shift(@ARGV) : 0;

my $stdev = $#ARGV >= 0 ? shift(@ARGV) : 1;

for (my $i = 0; $i < $rows; $i++) {
   my @x;
   for (my $j = 0; $j < $cols; $j++) {
      my $z = &sample_normal();
      push(@x, &format_number($z * $stdev + $mean, $sigs));
   }
   print STDOUT join($delim, @x), "\n";
}

__DATA__

sample_normal.pl [<rows> <cols> <mean> <stdev>]



