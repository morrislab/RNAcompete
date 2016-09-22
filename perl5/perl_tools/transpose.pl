#!/usr/bin/perl

##############################################################################
##############################################################################
##
## transpose.pl
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
my $delim   = $args{'-d'};
my $file    = $args{'--file'};
my $r       = 0;
my $c       = 0;
my $ncols   = -1;
my @x;

$verbose and print STDERR "Reading in table from '$file'...";
my $filep = &openFile($file);
while(<$filep>)
{
  my @row = split($delim);
  chomp($row[$#row]);
  for($c = 0; scalar(@row) > 0; $c++)
  {
    $x[$r][$c] = shift @row;
  }
  if($c > $ncols)
  {
    $ncols = $c;
  }
  $r++;
}
close($filep);

my $nrows = $r;

$verbose and print STDERR " done ($nrows by $ncols).\n";

$verbose and print STDERR "Transposing to $ncols by $nrows...";
for($c = 0; $c < $ncols; $c++)
{
  for($r = 0; $r < $nrows; $r++)
  {
    my $x = defined($x[$r][$c]) ? $x[$r][$c] : '';
    print "$x";
    if($r < $nrows - 1)
      { print $delim; }
  }
  print "\n";
}
$verbose and print STDERR " done.\n";

exit(0);

__DATA__
syntax: transpose.pl [OPTIONS] [FILE | < FILE]

Transposes a table -- flips the rows and columns so that what
were columns in the original table become the rows and what
were rows in the original table become the columns.  The original
file is assumed to have rows delimited by newlines and columns
delimited by tabs (the column delimiter can actually be set with
the -d flag; see below).

FILE: a file containing a table with each row containing a tuple
  and each field in the tuple seperated by a delimiter.  By
  default, the delimiter is assumed to be tab.

OPTIONS are:
-d DELIM: set the delimiter for the columns to DELIM (default is
          tab).



