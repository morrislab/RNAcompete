#!/usr/bin/perl

use strict;

my $verbose=1;

while(@ARGV)
{
   my $arg = shift @ARGV;
   if($arg eq '--help')
   {
      print STDOUT <DATA>;
      exit(0);
   }
   elsif($arg eq '-q')
   {
      $verbose = 0;
   }
}

my $iter=0;
my $passify=1000;
$verbose and print STDERR "Converting blanks to NaNs";
while(<>)
{
   while(/\t\t/ or /^\t/ or /\t$/)
   {
      s/\t\t/\tNaN\t/g;
      s/^\t/NaN\t/g;
      s/\t$/\tNaN/g;
   }
   print;

   $iter++;
   if($iter % $passify == 0)
   {
      $verbose and print STDERR ".";
   }
}
$verbose and print STDERR " done.\n";

__DATA__
syntax: fill-nan.pl < FILE

Replaces empty cells with the string NaN (useful for Matlab data files).
