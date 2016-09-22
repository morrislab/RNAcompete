#!/usr/bin/perl

##############################################################################
##############################################################################
##
## empirical_zscore.pl
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
require "$ENV{MYPERLDIR}/lib/libstats.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;


my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , ['--file',   'list',    [], undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose = not($args{'-q'});
my @files   = @{$args{'--file'}};

scalar(@files) == 2 or die("Must supply two files");

open(X, $files[0]) or die("Could not open file '$files[0]'");

open(Y, $files[1]) or die("Could not open file '$files[1]'");

my @X = <X>;

my ($n, $mean, $std) = &vec_stats(\@X);

$verbose and print STDERR "n=$n, mean=$mean, stdev=$std\n";

while(my $y = <Y>)
{
   chomp($y);

   my $z = ($y - $mean) / $std;

   my $p = &norm_pdf($z);

   print STDOUT "$z\t$p\n";
}

exit(0);

__DATA__
syntax: empirical_zscore.pl X Y

X - contains a list of data points specifying the data from
    which the empirical distribution will be estimated.

Y - contains a list of data points each of which will get
    assigned a Z-score based on the X distribution.

OPTIONS are:

-q: Quiet mode (default is verbose)


