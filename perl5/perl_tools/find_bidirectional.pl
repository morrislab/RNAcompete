#!/usr/bin/perl

##############################################################################
##############################################################################
##
## find_bidirectional.pl
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
                , [   '-k1', 'scalar',     1, undef]
                , [   '-k2', 'scalar',     2, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-h', 'scalar',     0, undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose  = not($args{'-q'});
my $key_col1 = $args{'-k1'};
my $key_col2 = $args{'-k2'};
my $delim    = $args{'-d'};
my $headers  = $args{'-h'};
my $file     = $args{'--file'};

$key_col1--;
$key_col2--;

my $line = 0;
my $filep = &openFile($file);
my %edges;
while(<$filep>)
{
   $line++;
   if($line > $headers)
   {
      my @tuple = split($delim, $_);
      chomp($tuple[$#tuple]);
      my ($item1, $item2) = ($tuple[$key_col1], $tuple[$key_col2]);

      if(not(exists($edges{$item1, $item2})))
      {
         splice(@tuple, $key_col2 > $key_col1 ? $key_col2 : $key_col1, 1);
         splice(@tuple, $key_col2 > $key_col1 ? $key_col1 : $key_col2, 1);

         my $string = scalar(@tuple) > 0 ? $delim . join($delim, @tuple) : '';

         $edges{$item1, $item2} = $string;

         if(exists($edges{$item2, $item1}))
         {
            if($item1 lt $item2)
            {
               $string = $item1 . $delim . $item2 . $string . $edges{$item2, $item1};
            }
            else
            {
               $string = $item2 . $delim . $item1 . $edges{$item2, $item1} . $string;
            }
            print $string, "\n";
         }
      }
   }
}
close($filep);

exit(0);


__DATA__
syntax: find_bidirectional.pl [OPTIONS] [FILE | < FILE]

OPTIONS are:

-q: Quiet mode (default is verbose)

-k1 COL: Key 1 is in column COL (default is 1)

-k2 COL: Key 2 is in column COL (default is 2)

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 0).


