#!/usr/bin/perl

##############################################################################
##############################################################################
##
## restrict_pairs.pl
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
require "$ENV{MYPERLDIR}/lib/libset.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [   '-p1', 'scalar',     1, undef]
                , [   '-p2', 'scalar',     2, undef]
                , [    '-k', 'scalar',     1, undef]
                , [   '-dp', 'scalar',  "\t", undef]
                , [   '-dk', 'scalar',  "\t", undef]
                , [   '-hp', 'scalar',     0, undef]
                , [   '-hk', 'scalar',     0, undef]
                , ['--file',   'list',    [], undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose   = not($args{'-q'});
my $pair_col1 = $args{'-p1'};
my $pair_col2 = $args{'-p2'};
my $key_col   = $args{'-k'};
my $delim_p   = $args{'-dp'};
my $delim_k   = $args{'-dk'};
my $headers_p = $args{'-hp'};
my $headers_k = $args{'-hk'};
my @files     = @{$args{'--file'}};

$pair_col1--;
$pair_col2--;
$key_col--;

scalar(@files) == 2 or die("Please supply two files");

$verbose and print STDERR "Reading set of keys from '$files[1]'...";
my $key_set = &setRead($files[1], $delim_k, $key_col, $headers_k);
my $num = &setSize($key_set);
$verbose and print STDERR " done ($num keys read).\n";

open(PAIRS, $files[0]) or die("Could not open file '$files[0]' for reading");
my $line = 0;
while(<PAIRS>)
{
   $line++;
   if($line > $headers_p)
   {
      my @tuple = split($delim_p, $_);
      chomp($tuple[$#tuple]);
      my ($key1, $key2) = ($tuple[$pair_col1], $tuple[$pair_col2]);

      if(exists($$key_set{$key1}) and exists($$key_set{$key2}))
      {
         print;
      }
   }
   else
   {
      print;
   }
}
close(PAIRS);

exit(0);


__DATA__
syntax: restrict_pairs.pl [OPTIONS] PAIRS_FILE KEYS_FILE

PAIRS_FILE: File containing pairs of keys.

KEYS_FILE: File containing a key on each line.

OPTIONS are:

-q: Quiet mode (default is verbose)

-p1 COL: The the first key from column COL in the PAIRS_FILE

-p2 COL: The the second key from column COL in the PAIRS_FILE

-k COL: Read the keys from column COL in the KEYS_FILE

-dp DELIM: Set the field delimiter to DELIM in the PAIRS_FILE (default is tab).

-dk DELIM: Set the field delimiter to DELIM in the KEYS_FILE (default is tab).

-hp HEADERS: Set the number of header lines in the PAIRS_FILE to HEADERS (default is 1).

-hk HEADERS: Set the number of header lines in the KEYS_FILE to HEADERS (default is 1).



