#!/usr/bin/perl

##############################################################################
##############################################################################
##
## set_sizes.pl
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
                , [ '-sets', 'scalar', undef, undef]
                , [ '-mems', 'scalar', undef, undef]
                , ['-alias', 'scalar', undef, undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose      = not($args{'-q'});
my $key_col      = $args{'-k'};
my $delim        = $args{'-d'};
my $headers      = $args{'-h'};
my $member       = $args{'-m'};
my $subsets_file = $args{'-sets'};
my $members_file = $args{'-mems'};
my $alias_file   = $args{'-alias'};
my $file         = $args{'--file'};

$key_col--;

$verbose and defined($alias_file) and print STDERR "Reading in member aliases from '$alias_file'...";
my $aliases = defined($alias_file) ? &setRead($alias_file) : undef;
$verbose and print STDERR " done.\n";

$verbose and defined($subsets_file) and print STDERR "Reading in the set selection from '$subsets_file'...";
my $subsets = defined($subsets_file) ? &setRead($subsets_file) : undef;
$verbose and print STDERR " done.\n";

$verbose and defined($members_file) and print STDERR "Reading in the member selection from '$members_file'...";
my $members = defined($members_file) ? &setRead($members_file, undef, undef, undef, undef, $aliases) : undef;
$verbose and print STDERR " done.\n";

$verbose and print STDERR "Reading in the set of sets from '$file'...";
my $sets = &setsReadMatrix($file, $member, $delim, $key_col, $headers, undef, undef, $subsets);
$verbose and print STDERR " done.\n";

$verbose and print STDERR "Printing out the sizes of the sets...";
foreach my $set_key (keys(%{$sets}))
{
   my $set  = defined($members) ? &setIntersection($$sets{$set_key}, $members) : $$sets{$set_key};

   my $size = &setSize($set);

   print "$set_key\t$size\n";
}
$verbose and print STDERR " done.\n";

exit(0);


__DATA__
syntax: set_sizes.pl [OPTIONS] [SETS_MATRIX | < SETS_MATRIX]

Print the sizes of the sets in SETS_MATRIX.

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Compare the values in key_column COL to the threshold in the file (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 1).

-m MEMBER: Set the membership value to MEMBER (default is 1).

-mems FILE: Supply a file that contains a subset of members to include in the counting.

-sets FILE: Select a subset of the sets.  Set names are in FILE.

-alias FILE: Supply an alias file that maps member into a new name.  The aliases
             convert the names of the members in SETS_MATRIX before comparing to
             the names passed in by the -mems option.




