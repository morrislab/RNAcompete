#!/usr/bin/perl

##############################################################################
##############################################################################
##
## discretize.pl
##
##############################################################################
##############################################################################
##
## Written by Josh Stuart.
##
##  Email address: jstuart@ucsc.edu
##          Phone: (831) 459-1344
##
## Postal address: Department of Biomolecular Engineering
##                 Baskin Engineering 129
##                 University of California, Santa Cruz
##                 Santa Cruz, CA 95064
##
##############################################################################

require "libfile.pl";
require "$ENV{MYPERLDIR}/lib/vector_ops.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-f', 'scalar',   '1', undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-n', 'scalar',     2, undef]
                , [    '-h', 'scalar',     0, undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose       = not($args{'-q'});
my $fields        = $args{'-f'};
my $delim         = $args{'-d'};
my $headers       = $args{'-h'};
my $n             = $args{'-n'};
my $file          = $args{'--file'};
my @extra         = @{$args{'--extra'}};

open(FILE, $file) or die("Could not open file '$file' for reading");

my $header = $headers > 0 ? [] : undef;

for(my $i = 0; $i < $headers; $i++)
{
   if($_ = <FILE>)
   {
      push(@{$header}, $_);
   }
}

while(<FILE>)
{
   my @x = split($delim, $_);

   chomp($x[$#x]);

   my @fields = &parseRanges($fields, scalar(@x), -1);

   my $key = &multiSplice(\@x, \@fields, $delim);

   my @y   = &discretizeUniformly(\@x, $N);

   print join($delim, @x), "\n";
}
close(FILE);

exit(0);


__DATA__
syntax: discretize.pl [OPTIONS] [FILE | < FILE]

OPTIONS are:

-q: Quiet mode (default is verbose)

-f COL: Set the key column to COL (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 1).

-n SUBRANGES: The number of equal sub-ranges to break values 
              of the rows into (default is 2).



