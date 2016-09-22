#!/usr/bin/perl

##############################################################################
##############################################################################
##
## group.pl
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
                  [    '-q', 'scalar',     0,     1]
                , [    '-f', 'scalar',     1, undef]
                , [    '-g', 'scalar',     2, undef]
                , [    '-n', 'scalar',     0,     1]
                , [    '-w', 'scalar',     0, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose = not($args{'-q'});
my $val_col = int($args{'-f'}) - 1;
my $grp_col = int($args{'-g'}) - 1;
my $window  = $args{'-w'};
my $numeric = $args{'-n'} or ($window > 0);
my $delim   = $args{'-d'};
my $file    = $args{'--file'};

$window = ($window == 0 and $numeric) ? 1 : $window;

my @data;

my $filep;
open($filep, $file) or die("Could not open file '$file' for reading");
while(<$filep>)
{
   my @x = split($delim, $_);
   chomp($x[$#x]);
   my $val  = $x[$val_col];
   my $grp  = $x[$grp_col];

   push(@data, [$grp, $val]);
}
close($filep);

if($numeric)
{
   @data = sort { $$a[0] <=> $$b[0]; } @data;
}
else
{
   @data = sort { $$a[0] cmp $$b[0]; } @data;
}

exit(0);

__DATA__
syntax: group.pl [OPTIONS]

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Compare the values in column COL to the threshold in the file (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).



