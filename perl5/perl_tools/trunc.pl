#!/usr/bin/perl

##############################################################################
##############################################################################
##
## trunc.pl
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
                , [    '-f', 'scalar', undef, undef]
                , [    '-k', 'scalar', undef, undef]  # <-- not used! but sometimes people use "-k" to mean "-f". So we throw an error in that case.
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-h', 'scalar',     0, undef]
                , [    '-n', 'scalar',     1, undef]
                , [    '-s', 'scalar',     0,     1]
                , [   '-nt', 'scalar',     0, undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if ($args{'-k'}) {
  die "**** ERROR: Error in your arguments to trunc.pl: trunc.pl accepts a -f argument for columns, NOT a -k argument! Most likely you should change \"-k\" to \"-f\".\n****\n**** Run trunc.pl --help in order to see the options.\n";
}

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose       = not($args{'-q'});
my $fields        = $args{'-f'};
my $delim         = $args{'-d'};
my $headers       = $args{'-h'};
my $tight         = not($args{'-nt'});
my $n             = $args{'-n'};
my $strings       = $args{'-s'};
my $file          = $args{'--file'};
my @extra         = @{$args{'--extra'}};

# If the fields were supplied in a file, then read it.
if(defined($fields) and -f $fields) {
   my $filep = &openFile($fields);
   my @fields;
   while(<$filep>) {
      my @tuple = split(/\s*/);
      push(@fields, @tuple);
   }
   $fields = join(',',@fields);
}

my $line_no = 0;
my $filep = &openFile($file);
my $passify = 1000;
while(my $line = <$filep>)
{
   my @cols;
   my $prev_cols = 0;
   $line_no++;

   if($line_no > $headers) {
      my @x;
      if(not(defined($fields))) {
         chomp($line);
         $x[0] = $line;
         @cols = (0);
      }
      elsif(defined($fields)) {
         @x = split($delim,$line);
         chomp($x[$#x]);
         my $num_cols = scalar(@x);
         if($num_cols != $prev_cols) {
            @cols = &parseRanges($fields, $num_cols, -1);
         }
         if(not($tight)) {
            $fields = undef;
         }
         $prev_cols = $num_cols;
      }

      foreach my $c (@cols) {
         if($c <= $#x) {
            my $text = $x[$c];
            if(not($strings)) {
               while($text =~ /([-]{0,1})(\d*)\.(\d{$n})(\d+)/) {
                  my ($sign,$i,$j,$k) = ($1,$2,$3,$4);
                  if(int(substr($k,0,1)) >= 5) {
                     if($j =~ /[9]{$n}/)
                        { $j = 0; $i++; }
                     else
                        { $j++; }
                  }
                  my $sub  = ($sign eq "-" ? "-" : "") . "$i.$j";
                  $text =~ s/[-]{0,1}\d*\.\d{$n}\d+/$sub/;
               }
            }
            else {
               $text = substr($text, 0, $n);
            }
            $x[$c] = $text;
         }
      }
      $line = join($delim, @x) . "\n";
   }
   print STDOUT $line;

   if($verbose) {
      if($line_no % $passify == 0) {
         print STDERR "$line_no lines truncated.\n";
      }
   }
}
close($filep);

exit(0);

__DATA__
syntax: trunc.pl [OPTIONS] < FILE

Truncates strings or numbers in a specified column.
(Operates on the entire file if no column is specified.)

CAVEATS:
   * Assumes that there is a header line. (Override with -h 0)
   * Truncates *all text*, rather than just numbers, by default.
   * Handles rounding (0.05 will truncate to 0.1)
   * Does not handle scientific-notation-style significant figures.
     You are giving a number of decimal places, not a precision.
   * Will truncate any decimal it finds, even if it is part of a string.
     "Song867.5309" would be truncated into "Song867.531"

Useful for trimming decimal places from numbers with unnecessary precision.

OPTIONS:

-q: Quiet mode (default is verbose)

-f RANGES: (Default: *all* columns will be truncated)
  Set the column to be truncated to RANGES. Leftmost column is column 1.
  RANGES are comma-separated lists of single columns or a range of columns
           for example:
   -f 1    is just the first column      -f 1-3 is columns 1,2, and 3
   -f -1   would operate on only the *last* column for a line
   -f 2,2,2,2   would select column 2 many times. No error results from this.

-d DELIM: (Default: tab)
  Set the field delimiter to DELIM.

-h HEADERS: (Default: 1 header line)
  Set the number of header lines to HEADERS.

-n N: (Default: 1)
  Make it so that at most N characters follow the decimal point.
  Does not handle significant figures--0.00009 truncates to 0.00
  (and not 9.00e-5).

-s: Assume the entries are strings and truncate to N characters.

EXAMPLES:

Normal usage for truncating numbers to three decimal places:
  trunc.pl -n 3 FILE
That would make a file with the number will make 1434.93933 into 1434.939.

Perhaps you only want to truncate numbers found in the second through 4th columns:
  cat FILE | trunc.pl -f 2-4  -n 3

