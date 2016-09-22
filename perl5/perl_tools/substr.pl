#!/usr/bin/perl

##############################################################################
##############################################################################
##
## substr.pl
##
##############################################################################
##############################################################################
##
## Written by Josh Stuart.
##
##  Email address: jstuart@ucsc.edu
##          Phone: (650) 725-7612
##
## Postal address: Department of Bioengineering, UCSC
##                 1156 High Street
##                 Santa Cruz, CA 95060
##
##       Web site: http://www.soe.ucsc.edu/~jstuart/
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
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose = not($args{'-q'});
my $file    = $args{'--file'};
my @extra   = @{$args{'--extra'}};

if(scalar(@extra) != 2)
{
   die("Must supply BEG and END.");
}

my $beg = $extra[0];

my $end = $extra[1];

my $filep;
open($filep, $file) or die("Could not open file '$file' for reading");
while(my $line = <$filep>)
{
   chomp($line);

   my $len = length($line);

   my $i = &fixIndex($beg,$len);

   my $j = &fixIndex($end,$len);

   my $sub = '';

   if($i <= $j)
   {
      $sub = substr($line, $i, $j-$i+1);
   }
   else
   {
      $sub = reverse(substr($line, $j, $i-$j+1));
   }

   print STDOUT "$sub\n";

}
close($filep);

exit(0);

sub fixIndex
{
   my ($i, $n) = @_;

   if($i < 0)   { $i += $n + 1; }
   $i--;
   if($i < 0)   { $i = 0; }
   if($i >= $n) { $i = $n - 1; }

   return $i;
}

__DATA__
syntax: substr.pl BEG END [OPTIONS]

OPTIONS are:

-q: Quiet mode (default is verbose)

