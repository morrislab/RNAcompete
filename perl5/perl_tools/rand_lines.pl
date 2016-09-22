#!/usr/bin/perl

require "liblist.pl";

use strict;

my $arg;
my $num           = undef;
my $replace       = 0;
my $headers       = 0;
my $print_header  = 0;
my $blanks        = 1;
my $verbose       = 1;
my $file          = \*STDIN;

my $nums = [];

while(@ARGV)
{
  $arg = shift @ARGV;
  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
  elsif($arg eq '-q')
  {
     $verbose = 0;
  }
  elsif($arg eq '-n')
  {
     $arg = shift @ARGV;
     if((-f $arg) or (-l $arg) or ($arg eq '-'))
     {
        open(FILE, $arg) or die("Could not open file '$arg'");
        while(<FILE>)
        {
           if(/(\d+)/)
           {
              push(@{$nums}, int($1));
           }
        }
        close(FILE);
     }
     else
     {
        push(@{$nums}, int($arg));
     }
  }
  elsif($arg eq '-wr')
  {
    $replace = 1;
  }
  elsif($arg eq '-wor')
  {
    $replace = 0;
  }
  elsif($arg eq '-hnp')
  {
    $headers = 1;
    $print_header = 0;
  }
  elsif($arg eq '-hp')
  {
    $headers = 1;
    $print_header = 1;
  }
  elsif($arg eq '-nb')
  {
    $blanks = 0;
  }
  elsif((-f $arg) or ($arg eq '-'))
  {
    open($file, $arg) or die("Could not open file '$arg' for reading.");
  }
  else
  {
    die("Invalid argument '$arg'.");
    exit(1);
  }
}

my @lines=();
my $item = '';
my $lineNum = 0;

while(<$file>)
{
  $lineNum++;
  if($lineNum > $headers and ($blanks or /\S/))
  {
     my $line = $_;
     chomp($line);
     push(@lines, \$line);
  }

  if ($lineNum == $headers && $print_header) {
      my $line = $_;
      print STDOUT $line;
  }
}
close($file);

# $num = defined($num) ? $num : scalar(@lines);
if (scalar(@{$nums}) <= 0) {
    $nums = [scalar(@lines)];
    #replaces this code: $nums = scalar(@{$nums}) > 0 ? $nums : [scalar(@lines)];
}


for(my $i = 0; $i < scalar(@{$nums}); $i++)
{
   my $num = $$nums[$i];

   $num = defined($num) ? $num : scalar(@lines);

   if(not($replace))
   {
      $num = $num < scalar(@lines) ? $num : scalar(@lines);
   }

   $verbose and print STDERR "Selecting $num random lines from the ",
                             scalar(@lines),
                             " read in ",
                             ($replace ? "with" : "without"),
                             " replacement.\n";
   
   $verbose and print STDERR "Permuting the lines.\n";
   my $permuted = &listPermute(\@lines, $num, $replace);
   $verbose and print STDERR "Done permuting the lines.\n";
   
   foreach my $item (@{$permuted})
   {
      if(defined($item))
      {
         print STDOUT $$item, (defined($nums) and scalar(@{$nums}) > 1) ? "\t" : "\n";
      }
      else
      {
         print STDOUT "NaN\n";
      }
   }

   if($i < scalar(@{$nums}) - 1)
   {
      print STDOUT "\n";
   }
}

exit(0);

__DATA__
syntax: rand_lines.pl [OPTIONS] < INFILE

DESCRIPTION: Chooses random lines from a newline-delimited file.

BUG FIXED: The program can now choose random lines without replacement correctly.

USAGE EXAMPLE:
    rand_lines.pl -n 50 -wor -nb myfile.txt
       This would choose 50 lines at random from myfile.txt,
       omitting blank lines (-nb). 
       No line would be chosen more than once (-wor).

OPTIONS are:

-n N: Choose N lines from the file (default: choose ALL lines from file; i.e. either
      bootstraps if -wr supplied, or returns a permutation if -wor is supplied).
      If N is a file, reads the first line and extracts a number from it.

-wor: Choose lines without replacement (DEFAULT)
-wr:  Choose lines with replacement (lines may by chosen more than once)

-hp:  "Header, print"
      The file contains a header line and the header should be printed to STDOUT.

-hnp: "Header, no printing"
      The file contains a header line, but it should *not* be printed to STDOUT.

-nb:  "No blanks" (NOT the default)
      Skip blanks (otherwise we *include* blank lines in the file).

