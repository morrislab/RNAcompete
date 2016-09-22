#!/usr/bin/perl

require "libfile.pl";

use strict;

my $delim     = "\t";
my $key_col   = 1;
my $fin       = \*STDIN;
my $headers   = 0;
my $transform = 0;
my $neg       = 0;
my $base      = undef;
my $from_base = undef;
my $to_base   = undef;
my $verbose   = 1;
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
  elsif($arg eq '-x')
  {
    $transform = 1;
  }
  elsif($arg eq '-b')
  {
    $base = shift @ARGV;
    $base = ($base eq 'e') ? exp(1) : $base;
  }
  elsif($arg eq '-k')
  {
    $key_col = int(shift @ARGV);
  }
  elsif($arg eq '-h')
  {
    $headers = int(shift @ARGV);
  }
  elsif($arg eq '-n')
  {
    $neg = 1;
  }
}
$key_col--;

$base      = not(defined($base)) ? 10.0 : $base;
$from_base = $base;
$to_base   = $transform ? 2.0 : $base;
my $log_normalizer = log($from_base) / log($to_base);

for(my $h = 0; $h < $headers; $h++)
{ 
  my $header = <$fin>;
  print $header;
}

if($verbose)
{ 
  $transform      and print STDERR "Transforming log from base $from_base to base $to_base...";
  not($transform) and print STDERR "Taking the log base $to_base of the data...";
}
while(<$fin>)
{
  my @tuple = split($delim);
  chomp($tuple[$#tuple]);

  my $precision = &getTuplePrecision(\@tuple,1);
  for(my $i=0; $i<=$#tuple; $i++)
  {
    if($i != $key_col)
    {
      my $val = $tuple[$i];
      if($val =~ /\d/)
      {
        $val = $transform ? ($val*$log_normalizer) : (log($val) / log($to_base));
        $tuple[$i] = $neg ? -$val : $val;
      }
    }
  }
  &forceTuplePrecision(\@tuple,$precision,1);
  print join($delim, @tuple), "\n";
}
$verbose and print STDERR " done.\n";

exit(0);

__DATA__
syntax: log.pl [OPTIONS] FILE

-k COL: Set the key column to COL (default is 1).

-h HEADERS: specifiy number of headers.

-x: Transform the data from one logarithm base to base 2 (i.e. the data has already been
    log transformed only to a different base).  Specify the source base using the -b option.  If
    no source base is specified then 10.0 is assumed.

-b BASE: Set the base of the logarithm to tranform to (if taking logs) or from (if transforming
         from an already logged data set). Default is log base 10.

-n Report the negative of the logarithm


