#!/usr/bin/perl

##############################################################################
##############################################################################
##
## stretch.pl
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

require "libfile.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-k', 'scalar', undef, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-h', 'scalar',     0, undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose   = not($args{'-q'});
my $key_col   = $args{'-k'} - 1;
my $delim     = $args{'-d'};
my $headers   = $args{'-h'};
my $file      = $args{'--file'};
my @extra     = @{$args{'--extra'}};
my $dimension = scalar(@extra) > 0 ? $extra[0] : 1;
my $shift     = scalar(@extra) > 1 ? $extra[1] : $dimension;

$verbose and print STDERR "dimension = $dimension, shift = $shift\n";

my $line_no = 0;
my $filep = &openFile($file);
my $num_groups = 0;
while(<$filep>)
{
   $line_no++;
   if($line_no > $headers)
   {
      my @x = split($delim);
      chomp($x[$#x]);

      my $key = defined($key_col) ? (splice(@x, $key_col, 1) . "\t") : "";

      my $len = scalar(@x);

      for(my $i = 0; $i < $len; $i += $shift)
      {
	 print STDOUT $key;
	 my $j = 0;
	 for($j = 0; $j < $dimension and (($i + $j) < $len); $j++)
	 {
            print STDOUT ($j > 0 ? $delim : ""), $x[$i + $j];
	 }
	 for($j = $j; $j < $dimension; $j++)
	 {
            print STDOUT $delim;
	 }
	 print STDOUT "\n";
      }
   }
}
close($filep);

exit(0);


__DATA__
syntax: stretch.pl [OPTIONS] [FILE | < FILE] [DIM] [SHIFT]

Combines all the values of a given key into one tuple.

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Key column.  If supplied, joins the extracted vectors with this key.

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 0).

-r: Reverse the sorting order (only applies when -i or -I in use).

-fill MISSING: Fill any missing entries with the value MISSING (default is blank).


