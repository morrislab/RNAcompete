#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/liblist.pl";

my $verbose = 1;
my $delim   = ' ';
my $min     = undef;
my $max     = undef;
my @entries;

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
   elsif($arg eq '-d')
   {
      $delim = shift @ARGV;
   }
   elsif($arg eq '-min')
   {
      $min = shift @ARGV;
   }
   elsif($arg eq '-max')
   {
      $max = shift @ARGV;
   }
   elsif($arg eq '-')
   {
      while(<STDIN>)
      {
        my @tuple = split;
	if($#tuple >= 0)
	{
	   chomp($tuple[$#tuple]);
	   foreach $arg (@tuple)
	   {
	      push(@entries, $arg);
	   }
	}
      }
   }
   else
   {
      push(@entries, $arg);
   }
}

$#entries >= 0 or die("No entries supplied/found.");

my $combinations = &listCombinations(\@entries, $min, $max, $delim);

foreach my $combination (@{$combinations})
{
   print "$combination\n";
}

exit(0);

__DATA__
syntax: all_combinations.pl [OPTIONS]

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Compare the values in column COL to the threshold in the file (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is space).




