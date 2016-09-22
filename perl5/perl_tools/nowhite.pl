#!/usr/bin/perl

##############################################################################
##############################################################################
##
## nowhite.pl
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
                , [    '-n', 'scalar',     0,     1]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose = not($args{'-q'});
my $returns = $args{'-n'};
my $file    = $args{'--file'};

my $filep = &openFile($file);
while(<$filep>)
{
   s/\s//g;
   print STDOUT $_, ($returns ? "\n" : "");
}
close($filep);

exit(0);


__DATA__
syntax: nowhite.pl [OPTIONS] [FILE | < FILE]

Remove all white-space from a file.

OPTIONS are:

-q: Quiet mode (default is verbose)

-n: Keep carraige returns.


