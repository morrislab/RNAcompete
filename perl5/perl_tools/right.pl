#!/usr/bin/perl

use strict;

my $verbose = 1;
my @files;
my $col = 1;
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
   else
   {
      die("Invalid argument '$arg'");
   }
}

$col--;

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
      print $tuple[$#tuple], "\n";
   }
   close(FILE);
}

exit(0);


__DATA__
syntax: SCRIPT.pl [OPTIONS]

OPTIONS are:

-q: Quiet mode (default is verbose)

-d DELIM: Set the field delimiter to DELIM (default is tab).




