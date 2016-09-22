#!/usr/bin/perl

use strict;

my $last_key = "";
my $counter = 1;

while(<STDIN>)
{
  chop;

  my @row = split(/\t/);

  if ($row[0] eq $last_key)
  {
    print "$row[0]_$counter\t";
    $counter++;
    for (my $i = 1; $i < @row; $i++)
    {
      print "$row[$i]\t";
    }
    print "\n";
  }
  else
  {
    $counter = 1;
    $last_key = $row[0];
    print "$_\n";
  }
}
