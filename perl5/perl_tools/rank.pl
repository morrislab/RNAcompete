#!/usr/bin/perl

##############################################################################
##############################################################################
##
## rank.pl
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
                , [    '-k', 'scalar',     1, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-h', 'scalar',     1, undef]
	        , [    '-r', 'scalar',     0,     1]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose = not($args{'-q'});
my $col     = int($args{'-k'}) - 1;
my $delim   = $args{'-d'};
my $headers = $args{'-h'};
my $reverse = $args{'-r'};
my $file    = $args{'--file'};

sub compare {
    return ($$a[0] <=> $$b[0]);
}

sub compareRev {
    return -($$a[0] <=> $$b[0]);
}

my $sortfun = \&compare;
if ($reverse) {
    $sortfun = \&compareRev;
}
    

my $filep;
open($filep, $file) or die("Could not open file '$file' for reading");

for(my $i = 0; $i < $headers; $i++)
{
   my $line = <$filep>;
   print $line;
}

while(<$filep>)
{
   my @x = split($delim, $_);

   chomp($x[$#x]);

   my $key = splice(@x, $col, 1);

   my @pairs;

   for(my $i = 0; $i < scalar(@x); $i++)
   {
      push(@pairs, [$x[$i], $i]);
   }

   my @sorted = sort $sortfun @pairs;

   for(my $rank = 0; $rank < scalar(@x); $rank++)
   {
      my $i = $sorted[$rank][1];

      $x[$i] = $rank + 1;
   }
   splice(@x, $col, 0, $key);

   print join($delim, @x), "\n";
}
close($filep);

exit(0);

__DATA__
syntax: rank.pl [OPTIONS]

** NOTE: There is another script called rank_items.pl that is similar,
   but has different options and more verbose documentation.
   You should look at it if you don''t find what you''re looking for here **

OPTIONS are:

-q: Quiet mode (default is verbose)

-r: reverse the ranking order

-k COL: Compare the values in column COL to the threshold in the file (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).



