#!/usr/bin/perl

require "libfile.pl";
require "$ENV{MYPERLDIR}/lib/libfunc.pl";

use strict;

my @cols;
my $delim      = "\t";
my $headers    = 1;
my $open_range = '0-';
my $verbose    = 1;
my @func_strings;
my @funcs;
my @args;
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
      $arg  = shift @ARGV;
      if($arg =~ /(\d+)-\s*$/)
      {
         my $beg = $1 - 1;
         $open_range = $arg;
         $open_range =~ s/\d+-\s*$/$beg-/;
      }
      else
      {
         @cols = &parseRanges(shift @ARGV);
      }
   }
   elsif($arg eq '-d')
   {
      $delim = shift @ARGV;
   }
   elsif($arg eq '-f')
   {
      my $function = shift @ARGV;
      my @func_args;
      if($function =~ /([^:]+):([^:]+)/)
      {
         $function  = $1;
         @func_args = split(',',$2);
      }
      push(@func_strings, "$function(" . join(",",@func_args) . ")");
      push(@funcs, $function);
      push(@args,  \@func_args);
   }
   elsif($arg eq '-h')
   {
      $headers = int(shift @ARGV);
   }
   else
   {
      die("Invalid argument '$arg'.");
   }
}

if(scalar(@funcs) == 0)
{
   @funcs = ('mean');
   @args  = ([]);
}

my $num_funcs = scalar(@funcs);

for(my $i = 0; $i <= $#cols; $i++)
   { $cols[$i]--; }

my $computed = 0;
my $passify  = 1000;
my $line_no  = 0;
$verbose and print STDERR "Computing function(s): ", join("; ",@func_strings), "\n";
while(<STDIN>)
{
   $line_no++;

   if($#cols == -1)
   {
      my $total = &getTupleLength($_, $delim);
      @cols = &parseRanges($open_range, $total);
      # print STDERR "[$total] ", join(',', @cols), "\n";
   }

   if($line_no > $headers)
   {
      my $x = &getSubTuple($_, \@cols, $delim);

      for(my $i = 0; $i < $num_funcs; $i++)
      {
         my $y = &evalFunction($funcs[$i], $x, $args[$i]);

         print STDOUT ($i == 0 ? "$y" : "\t$y");
      }
      print "\n";
      $computed++;
   }
   else
   {
      for(my $i = 0; $i < $num_funcs; $i++)
      {
         print STDOUT ($i == 0 ? "$func_strings[$i]" : "\t$func_strings[$i]");
      }
      print "\n";
   }

   if($verbose and $computed > 0 and ($computed % $passify) == 0)
   {
      print STDERR '.';
   }
}
$verbose and print STDERR " done.\n";

exit(0);

__DATA__
syntax: func.pl [OPTIONS] FUNCTION [TAB_FILE | < TAB_FILE]

Computes the function FUNCTION for each row of data in the tab-delimited file(s) TAB_FILE.

OPTIONS are:

-k COLUMNS: Supply the columns from which to extract the arguments to pass to the function.

-d DELIM: Set the delimiter to DELIM (default is tab).

-f FUNCTION: Set the function to evaluate to FUNCTION (default is mean).  Valid entries are:

                          mean
                          median
                          gte:VALUE - get the number >= to the value
                          fgte:VALUE - get fraction >= to the value

-h N: Set the number of headers in each file to N (default is 1).

