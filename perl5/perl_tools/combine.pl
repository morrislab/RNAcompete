#!/usr/bin/perl

require "libfile.pl";

use strict;

my $fin = \*STDIN;

my @key_cols = (1);
my $val_col  = 2;
my $delim    = "\t";
my $verbose  = 1;
my $func = 'average';
my $transform_log = 0;
my $take_log      = 0;
my $to_base       = 2.0;
while(@ARGV)
{
  my $arg = shift @ARGV;
  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
  elsif(-f $arg or $arg eq '-')
  {
    $fin = &openFile($arg);
  }
  elsif($arg eq '-f' or $arg eq '-k')
  {
    @key_cols = &parseRanges(shift @ARGV);
  }
  elsif($arg eq '-v')
  {
    $val_col = shift @ARGV;
  }
  elsif($arg eq '-func')
  {
    $func = shift @ARGV;
  }
  elsif($arg eq '-d')
  {
    $delim = shift @ARGV;
  }
  elsif($arg eq '-log')
  {
    $take_log = shift(@ARGV);
  }
  elsif($arg eq '-xlog')
  {
    $transform_log = shift(@ARGV);
  }
  else
  {
    die("Invalid argument '$arg'.");
  }
}

for(my $i=0; $i<=$#key_cols; $i++)
  { $key_cols[$i]--; }
$val_col--;

my @sorted_key_cols = sort { $a <=> $b; } @key_cols;

my $prev_key   = undef;
my $prev_tuple = undef;
my $combined   = undef;
my @vals;
my $key;
my $values;
my $log_normalizer = $transform_log>0 ? (log($transform_log) / log($to_base)) : undef;
my $precision;
while(<$fin>)
{
  if(/\S/)
  {
    # ($key,$values) = &splitKeyAndValue($_,\@key_cols,\@sorted_key_cols,$delim);
    $key = &getSubTupleString($_,\@key_cols,$delim);
    chomp;
    my @tuple = split($delim);
    my $val = $tuple[$val_col];
    if(not(defined($prev_key)) or ($key ne $prev_key))
    {
      if(defined($prev_key))
      {
	$precision = 10**(&getTuplePrecision(\@vals));
        $combined = &combineValues(\@vals,$func);
	$combined = int($combined*$precision) / $precision;
	if($transform_log)
	  { $combined = $combined*$log_normalizer; }
	elsif($take_log)
	  { $combined = log($combined) / log($take_log); }
	$$prev_tuple[$val_col] = $combined;
	print join($delim, @{$prev_tuple}), "\n";
      }
      @vals = ($val);
      $prev_key = $key;
      $prev_tuple = \@tuple;
    }
    else
    {
      push(@vals,$val);
    }
  }
  else
  {
    $prev_key = '';
  }
}

if($#vals>=0)
{
  $combined = &combineValues(\@vals,$func);
  $combined = int($combined*$precision) / $precision;
  if($transform_log)
    { $combined = $combined*$log_normalizer; }
  elsif($take_log)
    { $combined = log($combined) / log($take_log); }
  print $key, $delim, $combined, "\n";
}

exit(0);

sub combineValues # (\@vals,$func)
{
  my ($vals,$func) = @_;
  my $val     = undef;
  my $val_str = '';

  if($func =~ /ave/ or $func =~ /mean/)
  {
    $val = 0.0;
    my $n = 0;
    for(my $i=0; $i<scalar(@{$vals}); $i++)
    {
      if(defined($$vals[$i]) and $$vals[$i] =~ /\d/)
        { $val += $$vals[$i]; $n++; }
    }

    if($n > 0)
      { $val /= $n; $val_str = "$val"; }
    else
      { $val_str = ''; }
  }

  return $val_str;
}

__DATA__
syntax: combine.pl [OPTIONS] FILE

-func FUNCTION: set the combine function to FUNCTION.  Valid values are:

                     ave

-d DELIM: set delimiter to DELIM (default is tab).

-k RANgES: Set the key column(s) to the value(s) in RANGES.

-q: Quiet mode (default is verbose)

-log BASE: Take the log of the base BASE of the data after combining.

-xlog BASE: Transform the data from base BASE to base 2.0 after combining.

