#!/usr/bin/perl

##############################################################################
##############################################################################
##
## cat.pl
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
                 ,[    '-n', 'scalar',     1,     0]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose       = $args{'-q'};
my $print_newline = $args{'-n'};
my $extra         = $args{'--extra'};
my $entries       = (defined($extra) and scalar(@{$extra}) > 0) ? $extra : ['-'];

foreach my $entry (@{$entries})
{
   if((-f $entry) or (-l $entry) or ($entry eq '-'))
   {
      my $file = &openFile($entry);
      while(<$file>)
      {
         print STDOUT $_;
      }
      close($file);
   }
   else
   {
      print STDOUT $entry;

      if($print_newline)
      {
         print STDOUT "\n";
      }
   }
}

exit(0);


__DATA__
syntax: cat.pl [OPTIONS] [ENTRY1 ENTRY2 ...]

Prints out files or strings.  If ENTRYi is a file it prints its output
to standard output.  Otherwise, if it is a string, it prints the string.

OPTIONS are:

-n: Don't print the newline character between each entry.


