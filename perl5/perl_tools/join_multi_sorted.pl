#!/usr/bin/perl

use strict;

my @files;
my $uniq = 0;
while(@ARGV)
{
  my $arg = shift @ARGV;

  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
  elsif(($arg eq '-u') or ($arg eq '-uniq'))
  {
    $uniq = 1;
  }
  elsif(-f $arg)
  {
    push(@files,$arg);
  }
}

$#files>=0 or die("Must supply at least 2 files.");

my $file = shift @files;
my $command = "cat $file";
foreach $file (@files)
{
  if($uniq)
  {
    $command .= "| join_sorted_uniq.pl - $file";
  }
  else
  {
    $command .= "| join_sorted.pl - $file";
  }
}

print `$command`;

exit(0);

__DATA__
syntax: join_multiple_sorted.pl [OPTIONS] FILE1 FILE2 [FILE3 ...]

OPTIONS are:

-uniq: Assume the sorted keys are also unique (faster)

