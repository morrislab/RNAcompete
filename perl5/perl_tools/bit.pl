#!/usr/local/bin/perl

##############################################################################
##############################################################################
##
## bit.pl
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
                  [    '-q', 'scalar',     0,     1]
                , [    '-k', 'scalar',     0, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-h', 'scalar',     0, undef]
                , [   '-eq', 'scalar', undef, undef]
                , [   '-gt', 'scalar', undef, undef]
                , [  '-gte', 'scalar', undef, undef]
                , [   '-lt', 'scalar', undef, undef]
                , [  '-lte', 'scalar', undef, undef]
                , [  '-not', 'scalar',     0,     1]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'})) {
   print STDOUT <DATA>;
   exit(0);
}

my $verbose = not($args{'-q'});
my $col     = int($args{'-k'}) - 1;
my $delim   = &interpMetaChars($args{'-d'});
my $headers = $args{'-h'};
my $eq      = $args{'-eq'};
my $gt      = $args{'-gt'};
my $gte     = $args{'-gte'};
my $lt      = $args{'-lt'};
my $lte     = $args{'-lte'};
my $not     = $args{'-not'};
my $file    = $args{'--file'};
my @extra   = @{$args{'--extra'}};

my $rhs    = undef;
my $op     = undef;
my $hardop = undef;
my $negate = undef;

if(defined($eq)) {
   $rhs    = $eq;
   $hardop = '==';
}
elsif(defined($gt)) {
   $rhs    = $gt;
   $hardop = '>';
}
elsif(defined($gte)) {
   $rhs    = $gte;
   $hardop = '>=';
}
elsif(defined($lt)) {
   $rhs    = $lt;
   $hardop = '<';
}
elsif(defined($lte)) {
   $rhs    = $lte;
   $hardop = '<=';
}
if(defined($not)) {
   $negate = 1;
}

my $filep = &openFile($file);
my $line = 0;
while(<$filep>) {
   $line++;
   if($line > $headers) {
      my @x = split($delim, $_);
      chomp($x[$#x]);
      for(my $i = 0; $i < @x; $i++) {
         if($i != $col) {
            $x[$i] = &evalRegex($x[$i],$rhs,$op,$hardop,$negate) ? 1 : 0;
         }
      }
      print join($delim,@x), "\n";
   }
   else {
      print;
   }
}
close($filep);

exit(0);

__DATA__
syntax: bit.pl [OPTIONS]

Convert entries in a matrix to either 1 or 0 depending on if the value in 
the entry satisfies or does not satisfy a condition respectively. The
condition is specified with an operator. The default is to test if the
entry is not-missing.

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Set the key column to COL (default is no key column).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Skip HEADERS number of rows (default is 0 headers).

Following are the test options that are allowed:

-eq  VAL: Test matrix entries for equality to VAL.
-gt  VAL: Test for greater than VAL
-lt  VAL: Test for less than VAL
-gte VAL: Test for greater than or equal to VAL
-lte VAL: Test for less than or equal to VAL




