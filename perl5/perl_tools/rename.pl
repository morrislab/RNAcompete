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
  elsif(length($pattern)<1)
  {
    $pattern = $arg;
  }
  else
  {
    push(@files,$arg);
  }
}

my $cmd;
my $result;
foreach $oldFile (@files)
{
  $newFile = $oldFile;
  $result = eval("\$newFile =~ $pattern;");

  if(defined($result) and $newFile ne $oldFile)
  {
    $cmd = "mv $oldFile $newFile";

    if($verbose)
    {
      print STDERR "$oldFile -> $newFile ...";
    }

    $result = `$cmd`;

    if($verbose)
    {
      print STDERR " done.\n";
    }
  }
  elsif($verbose)
  {
    print STDERR "$oldFile unchanged\n";
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

