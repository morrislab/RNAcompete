#!/usr/bin/perl

##############################################################################
##############################################################################
##
## delete_columns.pl
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
                , [    '-d', 'scalar',  "\t", undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose = not($args{'-q'});
my $delim   = $args{'-d'};
my $file    = $args{'--file'};
my @extra   = @{$args{'--extra'}};

scalar(@extra) > 0 or die("Need to supply a column range");

my $col_ranges    = $extra[0];
my $eaten         = undef;
my $total_columns = &numCols($file, $delim, \$eaten);

if(defined($eaten))
{
   my $edited = &deleteCols($eaten, $col_ranges, $delim);
   print STDOUT $edited;
}

my $passify = 10;
my $line    = 0;
my $filep;
open($filep, $file) or die("Could not open file '$file' for reading");
while(<$filep>)
{
   $line++;
   my $edited = &deleteCols($_, $col_ranges, $delim);
   print STDOUT $edited;

   if($verbose and $line % $passify == 0)
   {
      print STDERR "$line lines processed.\n";
   }
}
close($filep);

exit(0);

sub deleteCols
{
   my ($line, $col_ranges, $delim) = @_;
   my @tuple = split($delim, $line);
   chomp($tuple[$#tuple]);

   my @cols    = &parseRanges($col_ranges, $#tuple);
   my $col_set = &list2Set(\@cols);

   my @non_deleted;
   for(my $i = 0; $i < scalar(@tuple); $i++)
   {
      my $col = $i + 1;
      if(not(exists($$col_set{$col})))
      {
         push(@non_deleted, $tuple[$i]);
      }
   }
   my $new_line = join($delim, @non_deleted) . "\n";

   return $new_line;
}

__DATA__
syntax: delete_columns.pl [OPTIONS] [FILE | < FILE]

OPTIONS are:

-q: Quiet mode (default is verbose)

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 1).



