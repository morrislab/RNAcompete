#!/usr/bin/perl

##############################################################################
##############################################################################
##
## scrub.pl
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
                , [    '-f', 'scalar',   [1], undef]
                , [    '-k', 'scalar', undef, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-h', 'scalar',     0, undef]
                , [    '-t', 'scalar',     0,     1]
                , [    '-i', 'scalar',     1, undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose    = not($args{'-q'});
my $ranges     = defined($args{'-k'}) ? $args{'-k'} : $args{'-f'};
my $delim      = $args{'-d'};
my $headers    = $args{'-h'};
my $tight      = $args{'-t'};
my $id         = $args{'-i'};
my $file       = $args{'--file'};
my @fields     = (0);

my %ids;

my $line_no   = 0;

my $max_fields = 0;

open(FILE, $file) or die("Could not open file '$file' for reading");

while(<FILE>)
{
   $line_no++;

   if(defined($ranges))
   {
      my $num_fields = &numTokens($delim);

      if($num_fields > $max_fields or ($tight and $num_fields != $max_fields))
      {
         $max_fields = $num_fields;

         @fields     = &parseRanges($ranges, $max_fields);

         for(my $i = 0; $i < scalar(@fields); $i++)
         {
           $fields[$i]--;
         }
      }
      if(not($tight))
      {
         $ranges = undef;
      }
   }


   if($line_no > $headers)
   {
      my @x = split($delim, $_);

      chomp($x[$#x]);


      foreach my $field (@fields)
      {
         my $name = $x[$field];

         if(not(exists($ids{$name})))
         {
            $ids{$name} = $id;

            $id++;
         }

         $x[$field] = $ids{$name};
      }

      print STDOUT join($delim, @x), "\n";
   }
   else
   {
      print;
   }
}
close(FILE);

exit(0);


__DATA__
syntax: scrub.pl [OPTIONS] [FILE | < FILE]

OPTIONS are:

-q: Quiet mode (default is verbose)

-f COL: Set the key fieldumn to COL (default is 1).
-k COL:

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 1).



