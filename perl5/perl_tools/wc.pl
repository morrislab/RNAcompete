#!/usr/bin/perl

##############################################################################
##############################################################################
##
## wc.pl
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
                , [    '-d', 'scalar',  "\t",  undef]
                , [    '-r', 'scalar',     0,     1]
                , ['--file',   'list',  ['-'], undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose = not($args{'-q'});
my $delim   = $args{'-d'};
my $rows    = $args{'-r'};
my $files   = $args{'--file'};

foreach my $file (@{$files})
{
   my $filep   = &openFile($file);

   if($rows)
   {
      while(<$filep>)
      {
         my @x = split($delim);
         print STDOUT scalar(@x), "\n";
      }
   }
   else
   {
      my $counts  = scalar(@{<$filep>});
      print STDOUT "$counts\t$file\n";
   }
   close($filep);
}

exit(0);


__DATA__
syntax: wc.pl [OPTIONS] [FILE | < FILE]

OPTIONS are:

-q: Quiet mode (default is verbose)

-d DELIM: Set the field delimiter to DELIM (default is tab).

-r: print out the number of words in each row.

