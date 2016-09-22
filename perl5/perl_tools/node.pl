#!/usr/bin/perl

##############################################################################
##############################################################################
##
## node.pl
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
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose  = not($args{'-q'});
my $key_col1 = $args{'-k1'} - 1;
my $key_col2 = $args{'-k2'} - 1;
my $delim    = $args{'-d'};
my $headers  = $args{'-h'};
my @extra    = @{$args{'--extra'}};

scalar(@extra) == 0 and die("Please supply a node.\n");

my $node = shift @extra;

if(((-f $node) or (-l $node) or ($node eq '-')) and open(NODE, $node))
{
   $node = <NODE>;

   chomp($node);

   close(NODE);
}

if(scalar(@extra) == 0)
{
   push(@extra, '-');
}

foreach my $file (@extra)
{
   my $line_no = 0;
   my $filep = &openFile($file);
   while(<$filep>)
   {
      $line_no++;
      if($line_no > $headers)
      {
         my @x = split($delim);
         chomp($x[$#x]);
         my $key1  = $x[$key_col1];
         my $key2  = $x[$key_col2];

         if(($key1 eq $node) or ($key2 eq $node))
         {
            print;
         }
      }
      else
      {
         print;
      }
   }
   close($filep);
}

exit(0);


__DATA__
syntax: node.pl [OPTIONS] NODE [FILE | < FILE]

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Set the key column to COL (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 0).



