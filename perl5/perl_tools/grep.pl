#!/usr/bin/perl

##############################################################################
##############################################################################
##
## grep.pl
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
                , [    '-k', 'scalar',     1, undef]
                , ['--file',   'list', ['-'], undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose  = not($args{'-q'});
my $k        = $args{'-k'};
my @files    = @{$args{'--file'}};
my @patterns = @{$args{'--extra'}};

scalar(@patterns) >= 1 or die("No patterns supplied");

for(my $i = 0; $i < @patterns; $i++)
{
   $patterns[$i] =~ s/\|/\\|/g;
}

foreach my $file (@files)
{
   my $line_no = 0;
   my $filep = &openFile($file);
   while(my $line = <$filep>)
   {
      $line_no++;

      my $num_matched = 0;
      foreach my $pattern (@patterns)
      {
	 if($line =~ /$pattern/)
	 {
	    $num_matched++;
	 }
      }

      if($num_matched >= $k)
      {
	 print STDOUT "$file\t$line";
      }
   }
   close($filep);
}

exit(0);


__DATA__
syntax: grep.pl [OPTIONS] PATTERN1 [PATTERN2 ...] [FILE1 | < FILE1] [FILE2 ...]

OPTIONS are:

-q: Quiet mode (default is verbose)

-k K: A line has to match at least K of the patterns supplied to be included (default is 1).



