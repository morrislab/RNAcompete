#!/usr/bin/perl

##############################################################################
##############################################################################
##
## or_sets.pl
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

use strict;

require "$ENV{MYPERLDIR}/lib/libset.pl";

use strict;

my $verbose      = 1;
my @files;
my $in_val       = 1;
my $delim        = "\t";
my $key_col      = 1;
my $headers      = 1;
my $print_type   = 'matrix';

while(@ARGV)
{
   my $arg = shift @ARGV;

   if($arg eq '--help')
   {
      print STDOUT <DATA>;
      exit(0);
   }
   elsif($arg eq '-q')
   {
      $verbose = 0;
   }
   elsif($arg eq '-p')
   {
      $print_type = shift @ARGV;
   }
   else
   {
      push(@files, $arg);
   }
}

scalar(@files) >= 1 or die("At least 2 files must be supplied");

$key_col--;

my $union;
for(my $i = 0; $i < scalar(@files); $i++)
{
   $verbose and print STDERR "Reading file '$files[$i]'.\n";
   my $sets = &setsReadTable($files[$i], $in_val, $delim, $key_col, $headers);
   $verbose and print STDERR "Done reading file '$files[$i]'.\n";

   if($i > 0)
   {
      # my %u  = %{&setsUnion($union, $sets)};
      # $union = \%u;
      $union  = &setsUnion($union, $sets);
   }
   else
   {
      # $union = \%{$sets};
      $union = $sets;
   }
}

if($print_type eq 'matrix')
{
   &setsPrintMatrix($union);
}

exit(0);


__DATA__
syntax: or_sets.pl [OPTIONS] SETS1 SETS2

SETS1 and SETS2 are membership matrices with sets listed across the columns of the
file.  The script assumes the first line contains a header that provides a key for
each set.  The first column in each file should contain the key to an element.


