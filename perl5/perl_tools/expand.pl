#!/usr/bin/perl

##############################################################################
##############################################################################
##
## expand.pl
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
                , [    '-k', 'scalar',     1, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-o', 'scalar',  "\t", undef]
                , [    '-n', 'scalar',     2, undef]
                , [    '-b', 'scalar',     1,     0]
                , [    '-w', 'scalar',     0,     1]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'})) {
   print STDOUT <DATA>;
   exit(0);
}

my $verbose = not($args{'-q'});
my $key_col = $args{'-k'};
my $delim   = $args{'-d'};
my $out_delim = $args{'-o'};
#my $num     = $args{'-n'}; # <-- variable was never actually used in the program
#my $blanks  = $args{'-b'}; # <-- variable was never actually used in the program
#my $white   = $args{'-w'}; # <-- variable was never actually used in the program
my $file    = $args{'--file'};

$key_col--;

my $filep;
open($filep, $file) or die("Could not open file '$file' for reading");
my $count = 0;
my @order;
my %tuples;
while(<$filep>) {
   my @tuple = split($delim, $_);
   chomp($tuple[$#tuple]);
   my $key  = splice(@tuple, $key_col, 1);
   if(not(exists($tuples{$key}))) {
      push(@order, $key);
   }
   $tuples{$key} .= $out_delim . join($out_delim, @tuple);
}
close($filep);

foreach my $key (@order) {
   my $data = $tuples{$key};
   print STDOUT $key,$data,"\n";
}

exit(0);


__DATA__
syntax: expand.pl [OPTIONS] < FILE

Turns a list of pairs into a first-item-major row.

For example:
   Alpha  Beta
   Alpha  Gamma
   Alpha  Delta
   Alpha  Beta

Would be processed by expand.pl into:
"Alpha   Beta   Gamma  Delta   Beta"

The items are printed in the same order that they are found,
and duplicates are printed.

The "opposite" of expand.pl is flatten.pl .

OPTIONS are:

-q: Quiet mode (default is verbose)

-n NUM: Collects NUM consecutive values in a single column and produces one
        tab-delimited tuple of size NUM (default is 2).
  NOTE: This option exists, but is never actually used in the program!
	Therefore, you cannot use it!

-k COL: Expand the values in column COL (default is 1).

-d DELIM: Set the input delimiter to DELIM (default is tab).

-o DELIM: Set the output delimiter to DELIM (default is tab).

-b: Do not include blank lines (default produces an empty entry in a tuple for
    each blank line found).
  NOTE: This option exists, but is never actually used in the program!

-w: Remove leading and trailing whitespace from lines.
  NOTE: This option exists, but is never actually used in the program!

Note: are you trying to turn a list like:
	Alpha  Beta   0.424
	Alpha  Gamma  0.191
	Gamma  Omega  4.244
into a matrix? If so, you want to use sets.pl instead of this program (check the help
section of sets.pl for an example of how to do this).
