#!/usr/bin/perl

##############################################################################
##############################################################################
##
## lists2matrix.pl
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

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-k', 'scalar',     1, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-l', 'scalar',     0,     1]
                , ['--file',   'list', ['-'], undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose = not($args{'-q'});
my $key_col = $args{'-k'};
my $delim   = $args{'-d'};
my $long    = $args{'-l'};
my @files   = @{$args{'--file'}};

$key_col--;

my $union;
my %sets;
foreach my $file (@files)
{
   my $set = &setRead($file, $delim, $key_col);

   $union  = &setUnion($union, $set);

   my $set_key = $long ? $file : &getPathSuffix($file);

   $sets{$set_key} = $set;
}

print "Member";
foreach my $set_key (keys(%sets))
{
   print $delim, $set_key;
}
print "\n";

foreach my $member (sort(keys(%{$union})))
{
   print $member;
   foreach my $set_key (keys(%sets))
   {
      my $set = $sets{$set_key};

      my $in = exists($$set{$member}) ? 1 : 0;

      print $delim, $in;
   }
   print "\n";
}

exit(0);


__DATA__
syntax: lists2matrix.pl [OPTIONS] LIST1 [LIST2 LIST3 ...]

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Compare the values in key_column COL to the threshold in the file (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-l: Use long names for sets (full file path supplied).  Default uses the base name.


