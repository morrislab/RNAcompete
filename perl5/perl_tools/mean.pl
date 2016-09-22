#!/usr/bin/perl

##############################################################################
##############################################################################
##
## mean.pl
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
require "$ENV{MYPERLDIR}/lib/liblist.pl";

use strict;

my $verbose = 1;
my @cols    = (1);
my $delim   = "\t";
my @files;
my $max_col = undef;
my $ranges  = undef;

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
      push(@files, $arg);
   }
   elsif($arg eq '-q')
   {
      $verbose = 0;
   }
   elsif($arg eq '-k')
   {
      $ranges = shift @ARGV;
   }
   elsif($arg eq '-d')
   {
      $delim = shift @ARGV;
   }
   else
   {
      die("Invalid argument '$arg'");
   }
}

for(my $i = 0; $i < scalar(@cols); $i++)
{
   $cols[$i]--;
}

if($#files == -1)
{
   push(@files,'-');
}

my $printed_header = 0;
foreach my $file (@files)
{
   if(defined($ranges))
   {
      my $num_cols = &getNumCols($file);
      @cols = &parseRanges($ranges, $num_cols);
   }


   print STDERR "Computing means for file '$file' ($#cols columns)...";

   open(FILE, $file) or die("Could not open file '$file'");
   my @means;
   my @nums;
   my @header;
   while(<FILE>)
   {
      my @tuple = split($delim, $_);
      chomp($tuple[$#tuple]);

      if(scalar(@header) == 0)
      {
         foreach my $col (@cols)
         {
	    push(@header, $tuple[$col]);
         }
	 if(not($printed_header))
	 {
            print STDOUT "UNIQID\tNAME\t", join("\t", @header), "\n";
	    $printed_header = 1;
	 }
      }
      else
      {
         for(my $i = 0; $i < scalar(@cols); $i++)
         {
	    my $value = $tuple[$cols[$i]];
	    if($value =~ /\S/)
	    {
	       $means[$i] += $value;
	       $nums[$i]  += 1;
            }
         }
      }
   }
   close(FILE);

   for(my $i = 0; $i < scalar(@cols); $i++)
   {
      if($nums[$i] > 0)
      {
	 $means[$i] /= $nums[$i];
      }
      else
      {
	 $means[$i] = 'NaN';
      }
   }
   print STDOUT "$file\t$file\t", join("\t", @means), "\n";
   print STDERR "Done computing means for file '$file'.\n";
}

exit(0);


__DATA__
syntax: mean.pl [OPTIONS] FILE

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Compare the values in column COL to the threshold in the file (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).


