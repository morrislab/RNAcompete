#!/usr/bin/perl

use strict;

my $arg;
my $file = \*STDIN;

while(@ARGV)
{
  $arg = shift @ARGV;

  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
  else
  {
    die("Bad argument '$arg' given to cut.\n");
  }
}

my @rows;
while(<$file>)
{
  push(@rows, $_);
}

for (my $i = @rows - 1; $i >= 0; $i--)
{
  print "$rows[$i]";
}

__DATA__

syntax: reverse.pl [OPTIONS] TAB_FILE

   Reverses a file (first line printed last, last printed first)

OPTIONS are:
