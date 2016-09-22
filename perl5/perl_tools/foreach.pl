#!/usr/bin/perl

##############################################################################
##############################################################################
##
## foreach.pl
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
                , [    '-d', 'scalar', undef, undef]   # note that /\s+/ must NOT be in quotation marks!
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose = not($args{'-q'});
my $delim   = $args{'-d'};
my @extra   = @{$args{'--extra'}};

scalar(@extra) == 3 or die("Please supply 3 arguments: VAR VALS TEXT");

my ($var, $vals, $text) = @extra;

$var     = ((-f $var) or ($var eq '-')) ? &getFileText($var)    : $var;
$text    = ((-f $text) or ($text eq '-')) ? &getFileText($text) : $text;

my @vals;
if (!defined($delim)) {
    # Delim was undefined, so split on whitespace
    @vals = ((-f $vals) or ($vals eq '-')) ? split("\n", &getFileText($vals)) : split(/\s+/, $vals);
} else {
    # Delim was defined, so split on whatever it is.
    @vals = ((-f $vals) or ($vals eq '-')) ? split("\n", &getFileText($vals)) : split($delim, $vals);
    $verbose and print "Splitting up the foreach line based on the delimiter (in brackets): [$delim]\n";
}

my $num  = scalar(@vals);

for(my $i = 1; $i <= $num; $i++)
{
   my $val = $vals[$i - 1];

   my $exe = $text;

   $exe =~ s/$var/$val/ge;

   $verbose and print STDERR "$i. Executing '$exe'\n";

   system($exe);

   my $perc_done = int($i / $num * 100);

   $verbose and print STDERR "$i. Done executing '$exe' ($perc_done% done)\n";
}

exit(0);


__DATA__
syntax: foreach.pl [OPTIONS] VAR VALS [TEXT | < TEXT]

where:

VAR  - Is the variable to substitute.  The script will replace every occurrence of
       VAR inside TEXT with each value supplied in the value list VALS.

VALS - A list of values used to replace the variable VAR.  Each value given in VALS
       will produce a new execution string after every occurrence of VAR has been
       replaced by a single value in VALS.

OPTIONS are:

-q: Quiet mode (default is verbose)

-d DELIM: Set the VALS delimiter to DELIM (default is any white space).



