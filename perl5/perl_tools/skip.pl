#!/usr/local/bin/perl

##############################################################################
##############################################################################
##
## skip.pl
##
##############################################################################
##############################################################################
##
## Written by Josh Stuart.
##
##  Email address: jstuart@ucsc.edu
##          Phone: (650) 725-7612
##
## Postal address: Department of Bioengineering, UCSC
##                 1156 High Street
##                 Santa Cruz, CA 95060
##
##       Web site: http://www.soe.ucsc.edu/~jstuart/
##
##############################################################################
##############################################################################

require "libfile.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;


my @flags   = (
                  [    '-n', 'scalar',     1, undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $num_skip = $args{'-n'};
my $file     = $args{'--file'};

my $filep;
open($filep, $file) or die("Could not open file '$file' for reading");
my $line_no = 0;
my $modulus = $num_skip + 1;
while(<$filep>)
{
   if(($line_no % $modulus) == 0)
   {
      print;
   }
   $line_no++;
}
close($filep);

exit(0);

__DATA__
syntax: skip.pl [OPTIONS]

Skips over lines in a file and prints the non-skipped lines.
By default it skips every other line.  Use the -n flag to
specify how many lines to skip.

OPTIONS are:

-n NUM_LINES: Skip NUM_LINES lines before outputting a line
              (default is 1).

