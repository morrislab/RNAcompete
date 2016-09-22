#!/usr/bin/perl

use strict;

require "libfile.pl";

my $verbose=1;
my @files;
my $delim = "\t";
my $col = 1;
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
  elsif($arg eq '-k')
  {
    $col = int(shift @ARGV);
  }
  elsif($arg eq '-d')
  {
    $delim = shift @ARGV;
  }
  elsif(-f $arg)
  {
    push(@files,$arg);
  }
  else
  {
    die("Base argument '$arg' given.");
  }
}
$col--;

if($#files == -1)
{
  push(@files,'____STDIN____');
}

my %key2set;
foreach my $file (@files)
{
  my $fin;
  if($file eq '____STDIN____')
  {
    $fin = \*STDIN;
  }
  else
  {
    open($fin,$file) or die("Could not open file '$file'.");
  }
  my $line=0;
  while(<$fin>)
  {
    $line++;
    if(/\S/ and not(/^\s*#/))
    {
      chomp;
      my @tuple = split($delim);
      my $key = $tuple[$col];
      my $set = &getPrettyName($file);
      $key2set{$key} = $set;
    }
  }
  close($fin);
}

# Print out the vectorized list.
foreach my $key (sort(keys(%key2set)))
{
  my $set = $key2set{$key};
  print STDOUT "$key\t$set\n";
}

exit(0);

sub getPrettyName # ($file)
{
  my $file = shift;
  $file = &remPathExt(&getPathSuffix($file));
  return $file;
}

__DATA__

syntax: sets2list.pl [OPTIONS] SET1 [SET2 ...]

SETi is a list of items belonging to one set.

OPTIONS are:

-q: Quiet mode -- turn verbosity off (default verbose)


