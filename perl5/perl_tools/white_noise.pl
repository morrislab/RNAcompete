#!/usr/bin/perl

##############################################################################
##############################################################################
##
## white_noise.pl
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

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-k', 'scalar',     1, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-h', 'scalar',     0, undef]
                , [    '-s', 'scalar',     1, undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose = not($args{'-q'});
my $key_col = $args{'-k'} - 1;
my $delim   = $args{'-d'};
my $headers = $args{'-h'};
my $stdev   = $args{'-s'};
my $file    = $args{'--file'};

my $line_no = 0;
my $filep = &openFile($file);
while(<$filep>)
{
   $line_no++;
   if($line_no > $headers)
   {
      my @x = split($delim);
      chomp($x[$#x]);

      for(my $i = 0; $i <= $#x; $i++)
      {
         if($i != $key_col and $x[$i] =~ /\d/)
         {
            $x[$i] += &sample_normal() * $stdev;
         }
      }
      print STDOUT join($delim, @x), "\n";
   }
   else
   {
      print STDOUT $_;
   }
}
close($filep);

exit(0);


__DATA__
syntax: white_noise.pl [OPTIONS] [FILE | < FILE]

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Set the key column to COL (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 0).

-s STDEV: Set the standard deviation of the noise to STDEV (default is 1).


