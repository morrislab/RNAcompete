#!/usr/bin/perl

##############################################################################
##############################################################################
##
## join_fast.pl
##
##############################################################################
##############################################################################
##
## Written by Josh Stuart in the lab of Stuart Kim, Stanford University.
##
##  Email address: jstuart@stanford.edu
##          Phone: (650) 725-7612
##
## Postal address: Department of Developmental Biology
##                 Beckman Center Room B314
##                 279 Campus Dr.
##                 Stanford, CA 94305
##
##       Web site: http://www.smi.stanford.edu/people/stuart
##
##############################################################################
##############################################################################
##
## Written: 00/00/02
## Updated: 00/00/02
##
##############################################################################
##############################################################################

require "libfile.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-1', 'scalar',     1, undef]
                , [    '-2', 'scalar',     1, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , ['--file',   'list',    [], undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose  = not($args{'-q'});
my $key_col1 = $args{'-1'} - 1;
my $key_col2 = $args{'-2'} - 1;
my $delim    = $args{'-d'};
my @files    = @{$args{'--file'}};

scalar(@files) == 2 or die("Please supply two files");

my %key2lines;
my %line2key;
my $line = 0;
my @lines_chosen;
my $passify = 100000;
my $iter = 0;
open(TWO, $files[1]) or die("Could not open the second file '$files[1]'\n");
while(<TWO>)
{
   my @x = split($delim);
   chomp($x[$#x]);
   my $key  = $x[$key_col2];

   if(not(exists($key2lines{$key})))
   {
      $key2lines{$key} = [];
   }

   push(@{$key2lines{$key}}, $line);

   $lines_chosen[$line] = -1;

   $line++;

   if($verbose and $line % $passify == 0)
   {
      print STDERR "Read $line lines.\n";
   }
}
close(TWO);

my @rows;
my $num_rows = 0;
open(ONE, $files[0]) or die("Could not open the first file '$files[0]'\n");
while(<ONE>)
{
   my @x = split($delim);

   chomp($x[$#x]);

   my $key  = splice(@x, $key_col1, 1);

   print $key, "\n";

   if(exists($key2lines{$key}))
   {
      push(@rows, [$key, \@x, []]);

      foreach my $l (@{$key2lines{$key}})
      {
         $lines_chosen[$l] = $num_rows;
      }

      $num_rows++;
   }

}
close(ONE);

$line = 0;
open(TWO, $files[1]) or die("Could not open the second file '$files[1]'\n");
while(<TWO>)
{
   my $row = $lines_chosen[$line];
   if($row >= 0)
   {
      my @x = split($delim);
      chomp($x[$#x]);
      my $key  = splice(@x, $key_col2, 1);
      push(@{$rows[$row][2]}, \@x);
   }
   $line++;
}
close(TWO);

$num_rows = scalar(@rows);
for(my $i = 0; $i < $num_rows; $i++)
{
   my $key = $rows[$i][0];
   my $x   = $rows[$i][1];
   my $ys  = $rows[$i][2];

   foreach my $y (@{$ys})
   {
      print STDOUT $key, $delim, join($delim, @{$x}), $delim, join($delim, @{$y}), "\n";
   }
}

exit(0);


__DATA__
syntax: join_fast.pl [OPTIONS] FILE1 FILE2

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Set the key column to COL (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).

