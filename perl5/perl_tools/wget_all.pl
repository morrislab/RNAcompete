#!/usr/bin/perl

##############################################################################
##############################################################################
##
## wget_all.pl
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
                  [     '-q', 'scalar',     0,     1]
                , [     '-k', 'scalar',     1, undef]
                , [     '-d', 'scalar',  "\t", undef]
                , [     '-h', 'scalar',     1, undef]
                , [     '-P', 'scalar',  './', undef]
                , ['-prefix', 'scalar',    '', undef]
                , ['-suffix', 'scalar',    '', undef]
                , [  '-lynx', 'scalar',     0,     1]
                , [ '--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose = not($args{'-q'});
my $key_col = $args{'-k'};
my $delim   = $args{'-d'};
my $headers = $args{'-h'};
my $dir     = $args{'-P'};
my $prefix  = $args{'-prefix'};
my $suffix  = $args{'-suffix'};
my $lynx    = $args{'-lynx'};
my $file    = $args{'--file'};
my @extra   = @{$args{'--extra'}};

$key_col--;

my $exe = $lynx ? 'lynx -dump' : 'wget';

my $filep;
open($filep, $file) or die("Could not open file '$file' for reading");
while(<$filep>)
{
   my @tuple = split($delim, $_);
   chomp($tuple[$#tuple]);
   my $item  = $tuple[$key_col];

   my $url = $prefix . $item . $suffix;

   my $command = "$exe " . join(' ', @extra) . ' ' . "'$url'";

   if($lynx)
   {
      $command .= " > $dir/$item";
   }
   else
   {
      $command .= " -P $dir";
   }

   $verbose and print STDERR "Executing '$command'.\n";
   # my $result = `$command`;
   system($command);
   $verbose and print STDERR "Done executing '$command'.\n";
}
close($filep);

exit(0);


__DATA__
syntax: wget_all.pl [OPTIONS] [FILE | < FILE]

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Compare the values in key_column COL to the threshold in the file (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 1).

-prefix PRE: Set the prefix to all URLs to PRE (default is empty).

-suffix SUF Set the suffix to all URLs to SUF (default is empty).

-lynx: Use the lynx program instead of wget.

-P DIR: Specify an output directory.


