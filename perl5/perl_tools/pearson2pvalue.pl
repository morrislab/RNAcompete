#!/usr/bin/perl

##############################################################################
##############################################################################
##
## pearson2pvalue.pl
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
require "$ENV{MYPERLDIR}/lib/libstats.pl";

use strict;
use warnings;

my $epsilon = '1.0e-307';

my $default_table = "$ENV{HOME}/Map/Stats/Conversions/Zscore2NormalPvalue/data.tab";

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',              0,     1]
                , [    '-f', 'scalar',              1, undef]
                , [    '-d', 'scalar',           "\t", undef]
                , [    '-h', 'scalar',              1, undef]
                , [    '-t', 'scalar', $default_table, undef]
                , [    '-2', 'scalar',              0,     1]
                , [  '-dim', 'scalar',          undef, undef]
                , ['--file', 'scalar',            '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose    = not($args{'-q'});
my $col        = $args{'-f'};
my $delim      = $args{'-d'};
my $headers    = $args{'-h'};
my $two_sided  = $args{'-2'};
my $table_file = $args{'-t'};
my $dim_col    = $args{'-dim'};
my @extra      = @{$args{'--extra'}};
my $file       = $args{'--file'};

$col--;

my $dimensions = undef;
my $stderr     = undef;
if(not(defined($dim_col)))
{
   (scalar(@extra) == 1 and ($extra[0] =~ /^\d+$/)) or die("No dimension supplied");
   $dimensions = $extra[0];
   $stderr     = sqrt($dimensions - 3);
}
else
{
   $dim_col--;
}

# Read in the p-values for the normal z-scores:
$verbose and print STDERR "Reading in table of Normal Z-scores to p-values from '$table_file'...";
my @z2p;
open(TABLE, $table_file) or die("Table of Z-scores to p-values '$table_file' does not exist");
while(<TABLE>)
{
   if(not(/[a-zA-Z][a-zA-Z]/))
   {
      chomp;
      my ($z_score, $p_value) = split("\t");
      if($p_value =~ /([\d.]+)[Ee](\S+)/)
      {
         $p_value = $1 * 10**$2;
      }
      push(@z2p, [$z_score, $p_value]);
   }
}
close(TABLE);
my $M = scalar(@z2p);
$verbose and print STDERR " done ($M lines read).\n";

# Sort by increasing Z-score:
$verbose and print STDERR "Sorting Z-scores of the Normal table...";
my @z2p_sorted = sort {$$a[0] <=> $$b[0];} @z2p;
$M = scalar(@z2p_sorted);
$verbose and print STDERR " done ($M Z-score -> P-value entries).\n";

$verbose and print STDERR "Reading in Pearson correlations...";
my @Zs;
my @pvals;
my $filep;
open($filep, $file) or die("Could not open file '$file' for reading");
my $line = 0;
my $passify = 100000;
while(<$filep>)
{
   chomp;

   my @tuple    = split($delim);
   my $pearson  = $tuple[$col];
   my $fisher_z = undef;
   my $Z        = undef;

   if($two_sided and $pearson < 0)
   {
      $pearson = -$pearson;
   }

   if($pearson =~ /[a-zA-Z][a-zA-Z]/)
   {
      $pvals[$line] = $pearson;
   }
   elsif($pearson eq 'NaN' or $pearson eq '-1.79769e+308')
   {
      $pvals[$line] = 'NaN';
   }
   else
   {
      if(defined($dim_col))
      {
         $dimensions = $tuple[$dim_col];
         $stderr     = $dimensions > 3 ? sqrt($dimensions - 3) : undef;
      }

      $fisher_z = &Pearson2FisherZ($pearson);
      $Z        = defined($stderr) ? $fisher_z * $stderr : 0;
      # $Z        = $Z < 0 ? -$Z : $Z;
      push(@Zs, [$Z, $line]);
      # print STDERR "Read [$_] -> [$Z, $line]\n";
   }

   $line++;

   if($verbose and $line % $passify == 0)
   {
      print STDERR "$line lines read (last: r=$pearson, dim=$dimensions, z=$fisher_z, Z=$Z)\n";
   }
}
close($filep);
my $n = $line;

$verbose and print STDERR " done ($n lines read).\n";

# Sort by increasing Z-score:
$verbose and print STDERR "Sorting Pearson by their corresponding Z-scores...";
my @Zs_sorted = sort {abs($$a[0]) <=> abs($$b[0]);} @Zs;
$verbose and print STDERR " done.\n";

$verbose and print STDERR "Looking up p-values for the Pearson measures...";
my $k = 0;
for(my $i = 0; $i < scalar(@Zs_sorted); $i++)
{
   my $Z_line      = $Zs_sorted[$i];
   my ($Z, $line)  = ($$Z_line[0], $$Z_line[1]);
   my $negative    = not(defined($Z)) ? 0 : ($Z < 0);
   $Z              = defined($Z) ? ($Z < 0 ? -$Z : $Z) : undef;
   my $z2p         = $z2p_sorted[$k];
   my $z2p_        = $z2p_sorted[$k + 1];
   my ($Zk, $Pk)   = ($$z2p[0], $$z2p[1]);
   my ($Zk_, $Pk_) = defined($z2p_) ? ($$z2p_[0], $$z2p_[1]) : (undef, undef);

   if(not(defined($Z)) or not(defined($Zk)))
   {
      # print STDERR ">> Not defined at i = $i, k = $k, Z = $Z, Zk = $Zk.\n";
   }

   if($Z < $Zk and $k == 0)
   {
      $pvals[$line] = 0.5;
      # print STDERR ">> Setting to 0.5 since $Z < $Zk (k = $k)\n";
   }

   else
   {
      # print STDERR "k = $k, $Z < $Zk and $Z >= $Zk_\n";
      for($k = $k; ($k < $M - 2) and ($Z < $Zk or ($Z >= $Zk and $Z >= $Zk_)); $k++)
      {
         # print STDERR "$k>> Zk = $Zk, Z = $Z, Zk_ = $Zk_\n";
         $z2p         = $z2p_sorted[$k + 1];
         $z2p_        = $z2p_sorted[$k + 2];
         ($Zk, $Pk)   = ($$z2p[0], $$z2p[1]);
         ($Zk_, $Pk_) = ($$z2p_[0], $$z2p_[1]);
      }
      # $k = $k == 0 ? 0 : ($k - 1);

      if($k == $M - 2)
      {
         $pvals[$line] = 0.0;
      }

      else
      {
         $z2p         = $z2p_sorted[$k];
         $z2p_        = $z2p_sorted[$k + 1];
         ($Zk, $Pk)   = ($$z2p[0], $$z2p[1]);
         ($Zk_, $Pk_) = ($$z2p_[0], $$z2p_[1]);

         # Linearly weight the p-value according to how close this Z-score is
         # to those in the table.
         my $w    = ($Z - $Zk) / ($Zk_ - $Zk);
         my $pval = (1 - $w) * $Pk + $w * $Pk_;

         $pvals[$line] = $negative ? (1 - $pval) : $pval;

         # print STDERR "<<$k>> Zk = $Zk, Z = $Z, Zk_ = $Zk_, pval = $pval\n";
      }
   }
}
$verbose and print STDERR " done.\n";


for($line = 0; $line < $n; $line++)
{
   my $pval =  $pvals[$line];

   if($pval =~ /[a-zA-Z][a-zA-Z]/ or $pval != 0)
   {
      $pval = $two_sided ? 2 * $pval : $pval;

      print STDOUT $pval, "\n";
   }
   elsif($pval == 0)
   {
      print STDOUT $epsilon, "\n";
   }
}

exit(0);

__DATA__
syntax: pearson2pvalue.pl [OPTIONS] [FILE | < FILE] [DIM | -dim COL]

FILE: File containing Pearson correlations in a single column.

DIM:  The number of dimensions used to compute the pearson correlations.

OPTIONS are:

-q: Quiet mode (default is verbose)

-f COL: Compare the values in column COL to the threshold in the file (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 1).

-t TABLE: Table containing mapping from Normal(0,1) Z-scores to their p-values (default
          is ~/Map/Stats/Conversions/Zscore2NormalPvalue/data.tab).

-dim COL: Specify that the dimension for each pearson should be read from column
          COL (default uses the same dimension supplied in the DIM argument).  This
          replaces that argument.

-2: Make the P-value two-sided (default is 1 sided).  Pearson
    correlations with large absolute values will be given good
    pearson correlation.
