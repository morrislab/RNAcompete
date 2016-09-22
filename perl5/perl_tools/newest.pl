#!/usr/bin/perl

use strict;

if($#ARGV == -1)
{
  print STDOUT <DATA>;
  exit(0);
}

my $N = 1;
my @files;
while(@ARGV)
{
  my $arg = shift;

  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
  elsif($arg eq '-n')
  {
    $N = int(shift @ARGV);
  }
  elsif((-f $arg) or (-d $arg) or (-l $arg))
  {
    push(@files,$arg);
  }
}

@files = sort by_age @files;
for(my $i = 0; $i<$N and $i<=$#files; $i++)
{
  print STDOUT "$files[$i]\n";
}

exit(0);

sub by_age
{
  my $age_a = (-M $a);
  my $age_b = (-M $b);
  return $age_a <=> $age_b;
}

__DATA__
syntax: newest.pl [OPTIONS] FILE1 FILE2 [FILE3 ...]

Prints the name of the file from the list of given files that has the newest
timestamp.

OPTIONS are:

-n N: Print the N most recent files from the list, not just the newest
