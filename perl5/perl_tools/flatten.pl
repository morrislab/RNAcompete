#!/usr/bin/perl

use strict;

my @files;
my @cols     = ();
my $rev      = 0;
my $delim    = "\t";
my $inc      = 1;
my $blanks   = 1;
my $all_cols = 0;
while(@ARGV)
{
   my $arg = shift @ARGV;

   if($arg eq '--help')
   {
      print STDOUT <DATA>;
      exit(0);
   }
   elsif($arg eq '-k')
   {
      $arg = shift @ARGV;

      if($arg eq 'all')
      {
         $all_cols = 1;
      }
      else
      {
         push(@cols, int(shift(@ARGV))-1);
      }
   }
   elsif($arg eq '-all')
   {
      $all_cols = 1;
   }
   elsif($arg eq '-rev')
   {
      $rev = 1;
   }
   elsif($arg eq '-d')
   {
      $delim = shift @ARGV;
   }
   elsif($arg eq '-i')
   {
      $inc = shift @ARGV;
   }
   elsif($arg eq '-blanks' or $arg eq '-b')
   {
      $blanks = 0;
   }
   elsif((-f $arg) or (-l $arg) or ($arg eq '-'))
   {
      push(@files, $arg);
   }
   else
   {
      die("Bad argument '$arg' given.");
   }
}

if(scalar(@cols) == 0)
{
   push(@cols, 0);
}

if(scalar(@files) == 0) { push(@files, '-'); }

foreach my $file (@files)
{
   my $fin;

   open($fin, $file) or die("Could not open file '$file'");

   while(<$fin>)
   {
      if(/\S/)
      {
         my @tuple = split($delim);

         chomp($tuple[$#tuple]);

         for(my $i = 0; $i < ($all_cols ? scalar(@tuple) : scalar(@cols)); $i++)
         {
            my $col = $all_cols ? $i : $cols[$i];

            my $key   = splice(@tuple, $col, 1);

            for(my $i = 0; $i < scalar(@tuple); $i += $inc)
            {
               my $flat = $key;
               for(my $j = 0; $j < $inc; $j++)
               {
                  my $data = $tuple[$i + $j];
                  if($blanks or $data =~ /\S/)
                  {
                     if(not($rev))
                     {
                        $flat .= $delim . $data;
                     }
                     else
                     {
                        $flat = $data . $delim . $flat;
                     }
                  }
               }
               print $flat, "\n";
            }
         }
      }
   }
   close($fin);
}

exit(0);

__DATA__
syntax: flatten.pl [OPTIONS] [FILE1 | < FILE1] [FILE2...]

Prints each tab-delimited data item in each row with its key seperately.
The first text field of data is assumed to be the key.

In other words, for each row like this:
"Alpha   Beta   Gamma  Delta  Beta"
It prints out:
   Alpha  Beta
   Alpha  Gamma
   Alpha  Delta
   Alpha  Beta

The "opposite" of flatten.pl is expand.pl .

OPTIONS are:

-k COL: Set the key column to COL (default is 1).  If COL equals 'all' then
        every column is treated as the key so that all pairwise combinations
        are printed.

-d DELIM: Set the delimiter to DELIM (default is <tab>)

-i INC: increment through the members by INC (default is 1).

-rev: Print

-b: Do *not* print blanks (default prints them).

-all: Same as '-k all'


