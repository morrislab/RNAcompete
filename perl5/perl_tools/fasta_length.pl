#!/usr/bin/perl

use strict;

my @files;
my $unzip = 0;
while(@ARGV)
{
  my $arg = shift @ARGV;
  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
  elsif($arg eq '-unzip')
  {
    $unzip = 1;
  }
  elsif(-f $arg or $arg eq '-')
  {
    if($arg eq '-')
    {
      push(@files,'');
    }
    else
    {
      push(@files,$arg);
    }
  }
  else
  {
    die("Bad argument '$arg' given.");
  }
}

if($#files==-1)
{
  push(@files,'');
}

foreach my $file (@files)
{
  my $fasta;
  if($unzip)
  {
    open($fasta,"zcat $file | fasta2stab.pl |");
  }
  else
  {
    open($fasta,"cat $file | fasta2stab.pl |");
  }
  while(<$fasta>)
  {
    if(/\S/)
    {
      chomp;
      my ($id,$seq) = split("\t");
      my $length = length($seq);
      print "$id\t$length\n";
    }
  }
  close($fasta);
}

exit(0);

__DATA__
syntax: fasta_length.pl [OPTIONS] FASTA1 [FASTA2 ...]

OPTIONS are:

-unzip: Unzip the input files before processing.

