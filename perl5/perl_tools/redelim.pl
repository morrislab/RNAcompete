#!/usr/bin/perl

use strict;

my $delim2 = undef;
my $delim1 = undef;

while(@ARGV)
{
  my $arg = shift @ARGV;

  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
  elsif(not(defined($delim1)))
  {
    $delim1 = $arg;
  }
  elsif(not(defined($delim2)))
  {
    $delim2 = $arg;
  }
  else
  {
    die("Bad argument '$arg' given.");
  }
}

defined($delim1) or die("Need to supply a delimiter.");

if(not(defined($delim2)))
{
  $delim2 = "\t";
}

while(<>)
{
  chomp;
  s/$delim1/$delim2/ge;
  print "$_\n";
}

exit(0);

__DATA__
syntax: redelim.pl DELIM1 [DELIM2] < FILE

Converts delimiters in the file from DELIM1 to DELIM2.  If only 1 delimiter is specified it
converts DELIM1 to tabs.

SEE ALSO: space2tab.pl tab2space.pl

