#!/usr/bin/perl

##############################################################################
##############################################################################
##
## non_empty.pl
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

require "libfile.pl";


use strict;

my $verbose = 1;
my $delim   = "\t";
my $file    = '-';
my $nows    = 0;
my $nolead  = 0;
my $notrail = 0;
my $key_col = 0;
my $regex   = '';
my $print   = 'counts';
my $header  = 0;
my @header;
my $num_fields = 0;

while(@ARGV)
{
   my $arg = shift @ARGV;
   if($arg eq '--help')
   {
      print STDOUT <DATA>;
      exit(0);
   }
   elsif(-f $arg)
   {
      $file = $arg;
   }
   elsif($arg eq '-q')
   {
      $verbose = 0;
   }
   elsif($arg eq '-d')
   {
      $delim = shift @ARGV;
   }
   elsif($arg eq '-k')
   {
      $key_col = shift @ARGV;
   }
   elsif($arg eq '-h')
   {
      $header = 1;
   }
   elsif($arg eq '-nows')
   {
      $nows = 1;
   }
   elsif($arg eq '-nolead')
   {
      $nolead  = 1;
   }
   elsif($arg eq '-notrail')
   {
      $notrail = 1;
   }
   elsif($arg eq '-noltws')
   {
      $nolead  = 1;
      $notrail = 1;
   }
   elsif($arg eq '-regex')
   {
      $regex = shift @ARGV;
   }
   elsif($arg eq '-matrix' or $arg eq '-m')
   {
      $print = 'matrix';
   }
   else
   {
      die("Invalid argument '$arg'");
   }
}

$key_col--;

my $fp;
open($fp, $file) or die("Could not open file '$file'");
while(<$fp>)
{
   my @tuple = split($delim);

   chomp($tuple[$#tuple]);

   my $key = undef;
   if($key_col >= 0)
   {
      $key = splice(@tuple, $key_col, 1);
   }

   if($header and $num_fields == 0)
   {
      @header     = @tuple;
      $num_fields = scalar(@header);

      if($print eq 'counts')
      {
         print STDOUT (defined($key) ? "$key\t" : ""), "Counts\n";
      }
      elsif($print eq 'matrix')
      {
         print STDOUT (defined($key) ? "$key\t" : ""), join($delim, @header), "\n";
      }
   }
   else
   {
      my $num_non_empty = 0;
      my @row;
      foreach my $entry (@tuple)
      {
         if($nows)
         {
            $entry =~ s/\s+//g;
         }

         if($nolead)
         {
            $entry =~ s/^\s+//;
         }

         if($notrail)
         {
            $entry =~ s/\s+$//;
         }

         if((length($regex) == 0 and length($entry) > 0) or
            (length($regex) > 0 and $entry =~ /$regex/))
         {
            $num_non_empty++;
            push(@row, 1);
         }
         else
         {
            push(@row, 0);
         }
      }

      my $num = scalar(@row);
      for(my $i = $num; $i < $num_fields; $i++)
      {
         push(@row, 0);
      }

      if($print eq 'counts')
      {
         print STDOUT (defined($key) ? "$key\t" : ""), $num_non_empty, "\n";
      }
      elsif($print eq 'matrix')
      {
         print STDOUT (defined($key) ? "$key\t" : ""), join($delim, @row), "\n";
      }
   }
}

exit(0);


__DATA__
syntax: non_empty.pl [OPTIONS] < TAB_FILE

OPTIONS are:

-q: Quiet mode (default is verbose)

-d DELIM: Set the field delimiter to DELIM (default is tab).

-k COL: Specify that a key exists in column COL (default assumes no key).  This
        column will not be included when counting non-empty entries.  Also, the
        keys will be printed along with the counts.

-h: If supplied the first line is treated as a header.

-nows: Remove extra white space in each entry of the TAB_FILE matrix before checking
       for empty entries.

-nolead: Same as -nows except only removes leading white space.

-notrail: Same as -nows except only removes trailing white space.

-noltws: Same as supplying both -nolead and -notrail options.

-regex REGEX: Instead of counting non-empty entries, count those that match the
              regular expression REGEX.

-matrix Print out a 0/1 matrix where 1 indicates a non-empty entry (default is to
-m       print the counts).


