#!/usr/bin/perl

##############################################################################
##############################################################################
##
## quote.pl
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
                  [    '-s', 'scalar',     0,     1]
                , [    '-k', 'scalar',     0, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $single  = $args{'-s'};
my $key_col = $args{'-k'} - 1;
my $delim   = $args{'-d'};
my $file    = $args{'--file'};

print STDERR "[$key_col]\n";
open(FILE, $file) or die("Could not open file '$file' for reading");
while(<FILE>)
{
   if($key_col >= 0)
   {
      my @x = split($delim);

      if($key_col < scalar(@x))
      {
         chomp($x[$#x]);
         $x[$key_col] = $single ? "'$x[$key_col]'" : "\"$x[$key_col]\"";
      }
      else
      {
         $x[$key_col] = "''";
      }
      $_ = join($delim, @x) . "\n";
   }

   else
   {
      chomp;
      $_ = ($single ? "'$_'" : "\"$_\"") . "\n";
   }

   print;
}
close(FILE);

exit(0);


__DATA__
syntax: quote.pl [OPTIONS] [FILE | < FILE]

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Quote the values in column COL (default quotes entire string).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 1).

-s: Quote with single quotes (default is double).



