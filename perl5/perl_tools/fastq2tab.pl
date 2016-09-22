#!/usr/bin/perl

use strict;

# Flush output to STDOUT immediately.
$| = 1;

my $arg;

my $fin   = \*STDIN;
my $delim = "\t";
while(@ARGV)
{
  $arg = shift @ARGV;

  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
  elsif($arg eq '-d')
  {
    $delim = shift @ARGV;
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
my $qual="";
while(<$fin>)
{
  chomp;
  if(/\S/) # if there is a non-whitespace character
  {
    if(/^\s*@/) # if it starts with @
    {
      s/^\s*@\s*//; # strip @
      if(length($name)>0)
      {
        print $name . $delim . $seq . $delim . $qual ."\n";
      }
      $name = $_;
      $seq = "";
      $qual = "";
    }
    else # is either seq, qual, or duplicate ID line (starting with +)
    {
    	unless(/^\s*\+/){ # if it doesn't start with +, so either seq or qual
    		if (length($seq)==0){
    			$seq = $_;
    		} else {
    			$qual = $_;
    		}
		}
    }
  }
}

if(length($seq)>0)
{
  print $name . $delim . $seq . $delim . $qual ."\n";
}

exit(0);

__DATA__

syntax: fasta2tab.pl [OPTIONS] < FASTA

OPTIONS are:

-d DELIM: change the delimiter from tab to DELIM



