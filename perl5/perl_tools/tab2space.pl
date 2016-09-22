#!/usr/bin/perl

use strict;

my $delim_out = undef;
my $delim_in  = undef;

while(@ARGV)
{
   my $arg = shift @ARGV;
   if($arg eq '--help')
   {
      print STDOUT <DATA>;
      exit(0);
   }
   elsif($arg eq '-do')
   {
      $delim_out = shift @ARGV;
   }
   elsif($arg eq '-di')
   {
      $delim_in = shift @ARGV;
   }
}


while(<>)
{
   if(not(defined($delim_in)) and not(defined($delim_out)))
   {
      s/[\t]+/ /g;
   }
   elsif(defined($delim_in) and defined($delim_out))
   {
      s/$delim_in/$delim_out/g;
   }
   elsif(defined($delim_in))
   {
      s/$delim_in/ /g;
   }
   elsif(defined($delim_out))
   {
      s/[\t]+/$delim_out/g;
   }
   print;
}

__DATA__
syntax: tab2space.pl < FILE

