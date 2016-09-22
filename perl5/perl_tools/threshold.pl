#!/usr/bin/perl

use strict;

my $verbose = 1;
my @files;
my $col = 1;
my $threshold = undef;
my $delim = "\t";

while(@ARGV)
{
   my $arg = shift @ARGV;
   if($arg eq '--help')
   {
      print STDOUT <DATA>;
      exit(0);
   }
   elsif(-f $arg)
   {
      push(@files, $arg);
   }
   elsif($arg eq '-q')
   {
      $verbose = 0;
   }
   elsif($arg eq '-k')
   {
      $col = int(shift @ARGV);
   }
   elsif($arg eq '-d')
   {
      $delim = shift @ARGV;
   }
   elsif(not(defined($threshold)))
   {
      if($arg eq '-')
      {
         $threshold = <STDIN>;
      }
      else
      {
	 $threshold = $arg;
      }
   }
   else
   {
      die("Invalid argument '$arg'");
   }
}

$col--;

defined($threshold) or die("No threshold defined");

if($#files == -1)
{
   push(@files,'-');
}

foreach my $file (@files)
{
   open(FILE, $file) or die("Could not open file '$file' for reading");
   while(<FILE>)
   {
      my @tuple = split($delim);
      chomp($tuple[$#tuple]);
      my $value = $tuple[$col];

      if($value >= $threshold)
      {
         print;
      }
   }
   close(FILE);
}

exit(0);


__DATA__
syntax: threshold.pl THRESHOLD [OPTIONS] < FILE

THRESHOLD is a numeric value.  Any value in the file that is equal to or
greater than this value is retained.  If THRESHOLD equals '-' then the value
is read from the first line of standard input.

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Compare the values in column COL to the threshold in the file (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).


