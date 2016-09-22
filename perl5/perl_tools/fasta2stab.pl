#!/usr/bin/perl

use strict;
my $arg;

my $fin = \*STDIN;
while(@ARGV)
{
  $arg = shift @ARGV;

  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }

  elsif(-f $arg)
  {
    open($fin,$arg) or die("Can't open file '$arg' for reading.");
  }
  
  else
  {
    die("Bad argument '$arg' given.");
  }
}

my $name="";
my $seq="";
while(<$fin>)
{
  chomp;
  if(/\S/)
  {
    if(/^\s*>/)
    {
      s/^\s*>\s*//;
      if(length($name)>0)
      {
        print "$name\t$seq\n";
      }
      $name = $_;
      $seq = "";
    }
    else
    {
      s/\s//g;
      $seq .= $_;
    }
  }
}

if(length($seq)>0)
{
  print "$name\t$seq\n";
}

exit(0);

__DATA__

syntax: fasta2stab.pl [OPTIONS] < FASTA


