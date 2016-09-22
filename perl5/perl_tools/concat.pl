#!/usr/bin/perl

use strict;

# Flush output to STDOUT immediately.
$| = 1;

if($#ARGV == -1)
{
  print STDOUT <DATA>;
  exit(0);
}

my @suffixes;
my @prefixes;
my $rev = 0;
my $sep = '';
while(@ARGV)
{
  my $arg = shift @ARGV;
  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
  elsif($arg eq '-sep')
  {
    $sep = shift @ARGV;
    if($sep =~ /^\/([^\/]+)\/$/)
    {
      my $pattern = $1;
      $pattern =~ s/([^\\]*)\\t/$1\t/g;
      $sep = $pattern;
    }
  }
  elsif($arg eq '-rev')
  {
    $rev = 1;
  }
  elsif($arg eq '-p')
  {
     $arg = shift @ARGV;
     push(@prefixes, $arg);
  }
  elsif($arg eq '-s')
  {
     $arg = shift @ARGV;
     push(@suffixes, $arg);
  }
  elsif($arg eq '-pf')
  {
     $arg = shift @ARGV;
     open(FILE, $arg) or die("Could not open prefix file '$arg'");
     while(<FILE>)
     {
        chomp;
        push(@prefixes, $_);
     }
     close(FILE);
  }
  elsif($arg eq '-sf')
  {
     $arg = shift @ARGV;
     open(FILE, $arg) or die("Could not open suffix file '$arg'");
     while(<FILE>)
     {
        chomp;
        push(@suffixes, $_);
     }
     close(FILE);
  }
  elsif(scalar(@prefixes) == 0)
  {
     push(@prefixes, $arg);
  }
  elsif(scalar(@suffixes) == 0)
  {
     push(@suffixes, $arg);
  }
  else
  {
    push(@suffixes,$arg);
  }
}

if(scalar(@prefixes) == 0)
{
   push(@prefixes, '');
}

if(scalar(@suffixes) == 0)
{
   push(@suffixes, '');
}

if(1)
{
   foreach my $prefix (@prefixes)
   {
      foreach my $suffix (@suffixes)
      {
        my $text = not($rev) ? ($prefix . $sep . $suffix) :
                               ($suffix . $sep . $prefix);
        print STDOUT $text, "\n";
      }
   }
}
else
{
   my $prefix_i   = 0;
   my $prefix_len = scalar(@prefixes);
   foreach my $suffix (@suffixes)
   {
     my $prefix = $prefixes[ ($prefix_i % $prefix_len) ];
     my $path = not($rev) ? ($prefix . $sep . $suffix) :
                            ($suffix . $sep . $prefix);
     print "$path\n";

     $prefix_i++;
   }
}

__DATA__
syntax: concat.pl [OPTIONS] PREFIX SUFFIX1 [SUFFIX2 ...]

Tacks the prefix PREFIX onto each suffix (the SUFFIXi's) and prints
the resulting concatenation to standard output.  If SUFFIXi equals a dash
'-' then the script reads suffixes from standard input.

 Note: You can add a prefix to each line in a single FILE with:
    sed 's/^/YOUR_PREFIX/' FILE
 or append a new suffix to the end of each line in a FILE with:
    sed 's/$/YOUR_SUFFIX/' FILE

OPTIONS are:

-sep SEPERATOR: Seperate the prefix and suffixes with SEPERATOR (default is
                blank).  E.g. use '/' to seperate directories and files.
-rev: Reverse -- treat the PREFIX as a suffix instead of a prefix.

-p PREFIX: add an additional prefix.

-s SUFFIX: add an additional suffix.

-pf FILE: Read prefixes from a file.

-sf FILE: Read suffixes from a file.
