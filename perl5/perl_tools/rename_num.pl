#!/usr/bin/perl

require "libfile.pl";

use strict;

my $arg;
my @files=();
my $pattern = '';
my $oldFile;
my $newFile;
my $cmd;
my $verbose=1;

while(@ARGV)
{
  $arg = shift @ARGV;

  if($arg eq '--help')
  {
    &printSyntax();
    exit(0);
  }
  elsif($arg eq '-q')
  {
    $verbose = 0;
  }
  else
  {
    push(@files,$arg);
  }
}

my $cmd;
my $result;
my $i=0;
foreach $oldFile (@files)
{
  $i++;
  $newFile = "$i" . &getPathExt($oldFile);

  if($newFile ne $oldFile)
  {
    $cmd = "mv $oldFile $newFile";

    $verbose and print STDERR "$oldFile -> $newFile ...";
    $result = `$cmd`;
    $verbose and print STDERR " done.\n";
  }
  else
  {
    $verbose and print STDERR "$oldFile unchanged\n";
  }
}

exit(0);


sub printSyntax
{
  my $name = &getPathSuffix($0);
  print STDERR "Syntax: $name [OPTIONS] PATTERN FILE [FILE2, FILE3, ...]\n",
	"\n",
	"Applies the regular expression in PATTERN to each file name in the\n",
	"list and, if the pattern changes the name, renames the file\n",
	"\n",
	"PATTERN is a valid PERL regular expression\n",
	"\n",
	"FILE(s) any regular file\n",
  	"\n";
}

