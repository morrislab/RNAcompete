#!/usr/bin/perl

##############################################################################
##############################################################################
##
## sets2list.pl
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
                , [    '-k', 'scalar',     1, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-h', 'scalar',     1, undef]
                , [    '-m', 'scalar',     1, undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose = not($args{'-q'});
my $key_col = $args{'-k'} - 1;
my $delim   = $args{'-d'};
my $headers = $args{'-h'};
my $mem_val = $args{'-m'};
my $file    = $args{'--file'};

$verbose and print STDERR "Reading in sets.\n";
my $sets     = &setsReadMatrix($file, $mem_val, $delim, $key_col, $headers);
my $num_sets = &setSize($sets);
$verbose and print STDERR "Done reading in sets ($num_sets read).\n";

$verbose and print STDERR "Computing the union.\n";
my $union       = &setsUnionSelf($sets);
my $num_members = &setSize($union);
$verbose and print STDERR "Done computing the union ($num_members total members).\n";

$verbose and print STDERR "Printing out which sets each member is in.\n";
my $passify = 100;
my $iter    = 0;
foreach my $member (keys(%{$union}))
{
   my $member_of = &setsMemberOf($sets, $member);

   print STDOUT $member;
   foreach my $set_key (@{$member_of})
   {
      print "\t$set_key";
   }
   print STDOUT "\n";

   $iter++;

   if($verbose and $iter % $passify == 0)
   {
      my $perc_done = int($iter / $num_members * 100.0);

      print STDERR "$iter members printed ($perc_done% done).\n";
   }
}
$verbose and print STDERR "Done.\n";

exit(0);


__DATA__
syntax: sets2list.pl [OPTIONS] [TAB_FILE | < TAB_FILE]

TAB_FILE: Sets in the form of a set matrix (set names in first row, element
          names in first column, and 0/1 entries).

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Set the key column to COL (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 1).



