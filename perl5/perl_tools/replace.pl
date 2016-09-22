#!/usr/bin/perl

##############################################################################
##############################################################################
##
## replace.pl
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
                , [    '-k', 'scalar',     1, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose   = not($args{'-q'});
my $col       = int($args{'-k'}) - 1;
my $delim     = $args{'-d'};
my $file      = $args{'--file'};
my @extra     = @{$args{'--extra'}};

my $condition = shift @extra;

my $value = '';

if(&doesEat($condition))
{
   $value = shift @extra;
}

my $replacement = shift @extra;

my $filep;
open($filep, $file) or die("Could not open file '$file' for reading");
while(<$filep>)
{
   my @x = split($delim, $_);
   chomp($x[$#x]);

   for(my $i = 0; $i <= $#x; $i++)
   {
      if(&isTrue($condition, \@x, $i, $value))
      {
         &replace($condition, \@x, $i, $replacement);
      }
   }
   print join($delim, @x), "\n";
}
close($filep);

exit(0);

sub doesEat
{
   my ($condition) = @_;

   my $yes = 1;

   return $yes;
}

sub replace
{
   my ($condition, $tuple, $i, $val) = @_;

   if($val =~ /\$(\d+)/)
   {
      $$tuple[$i] = $$tuple[$1-1];
   }
   else
   {
      $$tuple[$i] = $val;
   }
}

sub isTrue
{
   my ($condition, $tuple, $i, $val) = @_;

   my $result = 0;

   if    ($condition =~ /eq/i)  { $result = ($$tuple[$i] == $val); }
   elsif ($condition =~ /eql/i) { $result = ($$tuple[$i] eq $val); }
   elsif ($condition =~ /lt/i)  { $result = ($$tuple[$i] < $val);  }
   elsif ($condition =~ /ltl/i) { $result = ($$tuple[$i] lt $val); }

   return $result;

}



__DATA__
syntax: replace.pl CONDITION [VALUE] REPLACEMENT [OPTIONS] [< FILE | FILE]

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Compare the values in column COL to the threshold in the file (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-lt VALUE



