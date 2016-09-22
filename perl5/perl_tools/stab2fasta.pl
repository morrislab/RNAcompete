#!/usr/bin/perl

use strict;

my $arg;
while(@ARGV)
{
  $arg = shift @ARGV;

  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
} 

my $name;
my $seq;

while(<STDIN>)
{
  chop;
  if(/\S/)
  {
    ($name,$seq) = split("\t");
    print ">$name\n$seq\n";
  }
}

exit(0);

__DATA__

syntax: stab2fasta.pl [OPTIONS] < STAB

STAB is a STAB format file (tab-delimited sequence data) with <name> <seq> on
each line of the file.

