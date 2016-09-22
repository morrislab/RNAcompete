#!/usr/bin/perl

use strict;

my $delim = undef;
while(@ARGV)
{
   my $arg = shift @ARGV;
   if($arg eq '--help')
   {
      print STDOUT <DATA>;
      exit(0);
   }
   elsif($arg eq '-d')
   {
      $delim = shift @ARGV;
   }
}

while(<>)
{
  chop;
  if(not(defined($delim)))
  {
     s/\s+/\t/g;
  }
  else
  {
     s/$delim/\t/g;
  }
  print "$_\n";
}


__DATA__
syntax: space2tab.pl [OPTIONS] < FILE

Converts multiple spaces in the file to tabs.

-d DELIM: convert from DELIM to tab instead of multiple spaces.

