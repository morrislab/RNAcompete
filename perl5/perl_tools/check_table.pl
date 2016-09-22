#!/usr/bin/perl

##############################################################################
##############################################################################
##
## check_table.pl
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

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-k', 'scalar',     1, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-h', 'scalar',     1, undef]
                , [    '-c', 'scalar',     1, undef]
                , [    '-m',   'list', undef, undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose     = not($args{'-q'});
my $col         = int($args{'-k'}) - 1;
my $row_headers = $args{'-h'};
my $col_headers = $args{'-h'};
my $delim       = $args{'-d'};
my $miss        = $args{'-m'};
my $file        = $args{'--file'};

if(not(defined($miss)))
{
   $miss = ['NaN', '-1.79769e+308'];
}

my $num_rows  = 0;
my $num_cols  = undef;
my $max       = undef;
my $min       = undef;
my $num_vals  = 0;
my $num_miss  = 0;
my $min_dim   = undef;
my $max_dim   = undef;
my @col_min   = ();
my @col_max   = ();
my @col_miss  = ();

my $filep;
open($filep, $file) or die("Could not open file '$file' for reading");

for(my $h = 0; $h < $row_headers; $h++)
{
   my $header = <$filep>;

   my @x = split($delim, $header);

   $num_cols = scalar(@x) - $col_headers;
}

while(<$filep>)
{
   my @x = split($delim, $_);

   chomp($x[$#x]);

   my $n   = scalar(@x);

   my $dim = $n - $col_headers;

   if(defined($num_cols) and ($dim < $num_cols))
   {
      $miss += $num_cols - $dim;

      for(my $i = $dim; $i < $num_cols; $i++)
      {
         $col_miss[$i] += 1;
      }
   }

   if(not(defined($max_dim)) or ($max_dim < $dim))
   {
      $max_dim = $dim;
   }
   if(not(defined($min_dim)) or ($min_dim > $dim))
   {
      $min_dim = $dim;
   }

   for(my $i = $col_headers; $i < $n; $i++)
   {
      my $j = $i - $col_headers;

      if(&isOK($x[$i], $miss))
      {
         if(not(defined($max)) or ($max < $x[$i]))
         {
            $max = $x[$i];
         }
         if(not(defined($min)) or ($min > $x[$i]))
         {
            $min = $x[$i];
         }
         if(not(defined($col_max[$j])) or ($col_max[$j] < $x[$i]))
         {
            $col_max[$j] = $x[$i];
         }
         if(not(defined($col_min[$j])) or ($col_min[$j] > $x[$i]))
         {
            $col_min[$j] = $x[$i];
         }
      }
      else
      {
         $col_miss[$j] += 1;

         $num_miss += 1;
      }
   }

   $num_vals += $dim;

   $num_rows += 1;
}
close($filep);

for(my $i = 0; $i < $max_dim; $i++)
{
   $col_miss[$i] = defined($col_miss[$i]) ? $col_miss[$i] : 0;
}

$num_cols = defined($num_cols) ? $num_cols : $max_dim;

my $perc_miss = int(100 * $num_miss / $num_vals);

print STDOUT "",
             "min        = ", join(",",@col_min), "\n",
             "max        = ", join(",",@col_max), "\n",
             "missing    = ", join(",",@col_miss), "\n",
             "dimensions = $num_rows * $num_cols\n",
             "dim range  = [$min_dim, $max_dim]\n",
             "values     = $num_vals, $num_miss ($perc_miss%) missing\n",
             "val range  = [$min, $max]\n",
             "";

exit(0);

sub isOK
{
   my ($x, $missings) = @_;

   my $ok = 1;

   if(defined($x) and ($x =~ /\S/))
   {
      foreach my $missing (@{$missings})
      {
         if($x eq $missing)
         {
            $ok = 0;
            next;
         }
      }
   }
   else
   {
      $ok = 0;
   }

   return $ok;
}

__DATA__
syntax: check_table.pl [OPTIONS]

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Compare the values in column COL to the threshold in the file (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h NUM: Set the number of row headers to NUM (default 1).

-c NUM: Set the number of column headers to NUM (default 1).

-m MISS: Missing value (default is -1.79769e+308 and NaN).



