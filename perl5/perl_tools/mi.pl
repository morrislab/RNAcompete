#!/usr/local/bin/perl

require "$ENV{MYPERLDIR}/lib/vector_ops.pl";

use strict;

$| = 1;

my @keys;

my @data;

my $header = <>;

while(<>)
{
   my @x = split("\t");

   chomp($x[$#x]);

   my $key = shift(@x);

   push(@keys, $key);

   push(@data, \@x);
}

my $n = scalar(@data);

my $total_pairs = $n * ($n - 1) * 0.5;

my $k = 0;

my $passify = 100;

for(my $i = 0; $i < $n - 1; $i++)
{
   for(my $j = $i + 1; $j < $n; $j++)
   {
      my $mi = &mutual_information($data[$i], $data[$j]);

      my $mi_str = sprintf("%.3f", $mi);

      print STDOUT "$keys[$i]\t$keys[$j]\t$mi_str\n";

      $k++;

      if($k % $passify == 0)
      {
         my $perc_done = int($k / $total_pairs * 100);

         print STDERR "$k pairs calculated ($perc_done% done).\n";
      }
   }
}

exit(0);


