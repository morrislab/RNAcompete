#!/usr/bin/perl

##############################################################################
##############################################################################
##
## symmuni.pl
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
                , [    '-k', 'scalar', undef, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , ['--file', 'scalar', undef, undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};
if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}
my $keycol   = $args{'-k'};
my $delim    = $args{'-d'};
my $file     = $args{'--file'};
my @extra    = @{$args{'--extra'}};

$keycol = defined($keycol) ? $keycol - 1 : undef;

if(defined($file))
{
   my $fp = &openFile($file);
   while(<$fp>)
   {
      my @x    = split($delim);
      my $key  = defined($keycol) ? splice(@x, $keycol, 1) : undef;
      my $prob = &ComputeSymmetricUniformCdf(\@x);
      print STDOUT (defined($key) ? "$key\t" : ""), $prob, "\n";
   }
   close($fp);
}
else
{
   my $prob = &ComputeSymmetricUniformCdf(\@extra);
   print STDOUT $prob, "\n";
}

exit(0);


__DATA__
syntax: symmuni.pl FRACTION1 [FRACTION2, FRACTION3 ...]

