#!/usr/bin/perl

##############################################################################
##############################################################################
##
## join_col.pl
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
                , [    '-d', 'scalar',  "\t", undef]
                , [   '-d2', 'scalar',   ",", undef]
                , [    '-h', 'scalar',     1, undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose = not($args{'-q'});
my $delim   = $args{'-d'};
my $delim2  = $args{'-d2'};
my $headers = $args{'-h'};
my $file    = $args{'--file'};
my $filep;
my $header  = &getHeader($file, $headers, $delim, \$filep);

my %fields;
my @map;
my $num_fields = 0;
for(my $i = 0; $i < scalar(@{$header}); $i++)
{
   my $column;
   if(not(exists($fields{$$header[$i]})))
   {
      $fields{$$header[$i]} = $num_fields;
      $column = $num_fields;
      $num_fields++;
   }
   else
   {
      $column = $fields{$$header[$i]};
   }

   if(not(defined($map[$column])))
   {
      my @list;
      $map[$column] = \@list;
   }
   push(@{$map[$column]}, $i);
}

while(<$filep>)
{
   my @x = split($delim);
   chomp($x[$#x]);

   for(my $i = 0; $i < scalar(@map); $i++)
   {
      print STDOUT ($i > 0 ? $delim : "");
      for(my $j = 0; $j < scalar(@{$map[$i]}); $j++)
      {
         my $col = $map[$i][$j];

         print STDOUT ($j > 0 ? $delim2 : ""), $x[$col];
      }
   }
   print STDOUT "\n";
}
close($filep);

exit(0);


__DATA__
syntax: join_col.pl [OPTIONS] [FILE | < FILE]

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Set the key column to COL (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-d2 DELIM: Change the minor delimiter to DELIM.

-h HEADERS: Set the number of header lines to HEADERS (default is 1).



