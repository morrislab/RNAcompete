#!/usr/bin/perl

use strict;

if($#ARGV==-1)
{
  print STDERR <DATA>;
  exit(1);
}

my $file = \*STDIN;
my $header = '';
my @header;
while(@ARGV)
{
  my $arg = shift @ARGV;
  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
  elsif($arg eq '-f')
  {
    $arg = shift @ARGV;
    (-f $arg) or die("Could not open header file '$arg'.");
    $header = `cat $arg`;
    chomp($header);
    @header = split("\t",$header);
  }
  elsif(-f $arg)
  {
    open($file,$arg) or die("Could not open file '$arg' for reading.");
  }
  else
  {
    $header .= (length($header)>0 ? " " : "") . $arg;
    @header = split(',',$header);
  }
}

# Parse the list
print join("\t", @header), "\n";

while(<$file>)
{
  print;
}

__DATA__
cap.pl [OPTIONS] COMMA-SEPERATED-LIST FILE

TAB_FILE - a tab-delimited file (can also be passed into standard input.

Sticks a header line onto the file.  The comma-seperated list gives
a field name for the first columns in FILE.

OPTIONS are:

-f FILE: read the header from FILE.  In this case, no comma-seperated list is expected.

