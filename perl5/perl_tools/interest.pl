#!/usr/local/bin/perl

##############################################################################
##############################################################################
##
## interest.pl
##
##############################################################################
##############################################################################
##
## Written by Josh Stuart.
##
##  Email address: jstuart@soe.ucsc.edu
##          Phone: (831) 459-1344
##
## Postal address: 1156 High Street, 308 Physical Sciences
##                 Mail Stop: SOE2
##                 Santa Cruz, CA 95064
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
                  [       '-q', 'scalar',     0,     1]
                , [     '-div', 'scalar',     1, undef]
                , [ '-monthly', 'scalar',     0,     1]
                , [   '-daily', 'scalar',     0,     1]
                , [ '-install', 'scalar',     0,     1]
                , [    '-decs', 'scalar',     2, undef]
                , [   '--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose = not($args{'-q'});
my $div     = $args{'-div'};
my $install = $args{'-install'};
my $decs    = $args{'-decs'};
my $file    = $args{'--file'};
my @extra   = @{$args{'--extra'}};
$div        = $args{'-monthly'} ? 12 : $div;
$div        = $args{'-daily'} ? 365 : $div;

my $X = 1000;
my $R = 1;
my $C = 1;

$X = scalar(@extra) > 0 ? $extra[0] : $X;
$R = scalar(@extra) > 1 ? $extra[1] : $R;
$C = scalar(@extra) > 2 ? $extra[2] : $C;

$R /= ($div*100);

my $total    = 0;
if($install) {
   my $amount = $X / $C;
   for(my $i = 1; $i <= $C; $i++) {
      $total += $amount * ((1 + $R)**$i);
   }
}
else {
   $total    = $X * ((1 + $R)**$C);
}

my $interest = $total - $X;

print STDOUT         &format_number($total,$decs)
             , "\t", &format_number($interest,$decs)
             , "\t", &format_number($X,$decs)
             , "\n";

exit(0);

__DATA__
syntax: interest.pl [OPTIONS] [X | X R | X R C]

Prints the total amount of money and the interest accumulated after a
specified number of cycles at a given interest rate.

X - The starting amount invested. Default is 1000 if no arguments given.

R - The percentage rate per cycle. E.g. 5.4 could mean 5.4% APR if the cycles
    are years. If no rate is given, default is 1%.

C - The number of cycles to calculate forward. If no cycles are given, default
    is 1.

OPTIONS are:

-q: Quiet mode (default is verbose)

-div NUM: Divide the provided rate by NUM before using. For example, if an APR
          is provided and you want to calculate yield after monthly compoundings,
          can use months for the cycles and divide the given APR by 12.
          
-monthly: Same as -div 12.

-daily: Same as -div 365.

-install: X is broken up into equal-sized installments to give a regular amount invested per cycle.
          I.e. X/C is invested each cycle.

-decs NUM: Set the number of decimal places to include in the output (default is 2).


