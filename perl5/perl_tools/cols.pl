#!/usr/bin/perl

##############################################################################
##############################################################################
##
## cols.pl
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
require "$ENV{MYPERLDIR}/lib/libset.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-k', 'scalar',     1, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [   '-hr', 'scalar',     1, undef]
                , [   '-hc', 'scalar',     0, undef]
                , ['--file',   'list', ['-'], undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose     = not($args{'-q'});
my $key_col     = $args{'-k'} - 1;
my $delim       = $args{'-d'};
my $header_rows = $args{'-hr'};
my $header_cols = $args{'-hc'};
my @files       = @{$args{'--file'}};

scalar(@files) >= 2 or die("Please supply at least 2 files");

my $filep  = undef;
my @row_header = @{&getHeader(shift(@files), $header_rows, $delim, \$filep)};
my %row_header = %{&list2Set(\@row_header)};

my $list   = &listRead(shift(@files));
my @cols;
my %cols;
my @selected_fields;

for(my $i = 0; $i < $header_cols; $i++)
{
   if($i < scalar(@row_header))
   {
      my $selected_field = $row_header[$i];

      push(@selected_fields, $selected_field);

      push(@cols, $i);

      $cols{$i} = 1;
   }
}

foreach my $selected_field (@{$list})
{
   if(exists($row_header{$selected_field}) and not(exists($cols{$row_header{$selected_field}})))
   {
      push(@selected_fields, $selected_field);

      push(@cols, $row_header{$selected_field});

      $cols{$row_header{$selected_field}} = 1;
   }
}

$verbose and print STDERR scalar(@cols), " matching columns found.\n";

print STDOUT join($delim, @selected_fields), "\n";

if(scalar(@cols) > 0)
{
   while(<$filep>)
   {
      my @x = split($delim);
      chomp($x[$#x]);

      my @tuple;
      foreach my $i (@cols)
      {
         if($i < scalar(@x))
         {
            push(@tuple, $x[$i]);
         }
      }

      if(scalar(@tuple) > 0)
      {
         print STDOUT join($delim, @tuple), "\n";
      }
   }
}

close($filep);

exit(0);


__DATA__
syntax: cols.pl [OPTIONS] [FILE | < FILE] LIST1 [LIST2 ...]

OPTIONS are:

-q: Quiet mode (default is verbose)

-k  COL: Set the key column to COL (default is 1).

-d  DELIM: Set the field delimiter to DELIM (default is tab).

-hr HEADERS: Set the number of header rows to HEADERS (default is 1).

-hc HEADERS: Set the number of header columns to HEADERS (default is 0).



