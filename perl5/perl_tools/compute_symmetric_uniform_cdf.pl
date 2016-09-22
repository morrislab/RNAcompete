#!/usr/bin/perl

##############################################################################
##############################################################################
##
## compute_symmetric_uniform_cdf.pl
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
require "$ENV{MYPERLDIR}/lib/libstats.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-f', 'scalar',     0, undef]
                , [    '-l', 'scalar',     0,     1]
                , [    '-s', 'scalar', undef, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , ['--file', 'scalar',   '-', undef]
            );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}
my $file     = $args{'--file'};
my $key_col  = $args{'-f'} - 1;
my $delim    = $args{'-d'};
my $log      = $args{'-l'};
my $sigdig   = $args{'-s'};
my @extra    = @{$args{'--extra'}};

my $pctl     = defined($sigdig) ? ('%.' . $sigdig . 'f') : '%g';

if(scalar(@extra) > 1)
{
   my $cum_prob = &ComputeSymmetricUniformCdf(\@extra);
   print STDOUT "args", $delim, $cum_prob, "\n";
}

my $line_no = 0;

if(($file eq '-') or (-f $file) or (-l $file))
{
   my $fp = &openFile($file);

   while(<$fp>)
   {
      $line_no++;

      chomp;

      my @x = split($delim);

      my $key = $key_col >= 0 ? splice(@x, $key_col, 1) : undef;

      my $cum_prob = &ComputeSymmetricUniformCdf(\@x);

      my $cum_str = "NaN";

      if($log)
      {
         $cum_str = $cum_prob > 0 ? sprintf($pctl, log($cum_prob)/log(10)) : "Inf";
      }
      else
      {
         $cum_str = $cum_prob <= 0 ? '0' : sprintf($pctl, $cum_prob);
      }

      print STDOUT (defined($key) ? ($key . $delim) : ("")), $cum_str, "\n";
   }

   close($fp);
}

exit(0);


__DATA__
syntax: compute_symmetric_uniform_cdf.pl FRACTION1 [FRACTION2, FRACTION3 ...]

-l: Print the log of the cummalitive probability.

-s DIGITS: Number of significant digits to report (default is 5).


