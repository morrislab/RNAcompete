#!/usr/bin/perl

require "libfile.pl";

use strict;

my $verbose    = 1;
my $delim      = "\t";
my $blanks     = 1;
my $count_rows = 0;
my @files;

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
   elsif($arg eq '-r')
   {
      $count_rows = 1;
   }
   elsif($arg eq '-c')
   {
      $count_rows = 0;
   }
   elsif(-f $arg or ($arg eq '-')) {
      push(@files, $arg);
   }
   else {
      die("Invalid argument '$arg'");
   }
}

if($#files == -1) {
   push(@files,'-');
}

foreach my $file (@files) {
   if(not($count_rows)) {
      my $num_tokens = &numTokensPerLine($file, $delim, $blanks);
      foreach my $num (@{$num_tokens}) {
         print STDOUT $num, "\n";
      }
   }
   else {
      my $num = &numLines($file, $blanks);
      print STDOUT $num, "\n";
   }
}

exit(0);


__DATA__
syntax: count.pl [OPTIONS] [< FILE1 | FILE1] [FILE2 ...]

Count the number of rows (or columns) in the files.

OPTIONS are:

-q: Quiet mode (default is verbose)

-d DELIM: Set delimiter to DELIM (default is tab).

-b: Skip blanks (default counts blanks rows).

-r: Count the number of rows instead of the number of columns in each row.

