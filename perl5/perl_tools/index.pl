#!/usr/bin/perl

##############################################################################
##############################################################################
##
## index.pl
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

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-i', 'scalar',     1, undef]
                , [    '-a', 'scalar',     0,     1]
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
my $index   = $args{'-i'};
my $after   = $args{'-a'};
my $delim   = $args{'-d'};
my $file    = $args{'--file'};

my %seen;

my $filep;
open($filep, $file) or die("Could not open file '$file' for reading");
while(<$filep>)
{
   chomp;

   my $i = $index;

   if(exists($seen{$_}))
   {
      $i = $seen{$_};
   }
   else
   {
      $seen{$_} = $i;
      $index++;
   }

   if($after)
   {
      print STDOUT $_, $delim, $i, "\n";
   }
   else
   {
      print STDOUT $i, $delim, $_, "\n";
   }
}
close($filep);

exit(0);

__DATA__
syntax: index.pl [OPTIONS]

Numbers the unique lines.

OPTIONS are:

-q: Quiet mode (default is verbose)

-i INDEX: Start indexing from INDEX instead of 1.

-d DELIM: Set the output delimiter to DELIM instead of <tab>.

