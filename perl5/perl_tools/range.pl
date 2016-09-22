#!/usr/bin/perl

use strict;

my ($beg,$end,$inc,$delim) = (undef,undef,undef,undef);
my $pad = 0;
while(@ARGV)
{
  my $arg = shift @ARGV;

  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
  elsif($arg eq '-pad')
  {
    $pad = 1;
  }
  elsif(not(defined($beg)))
  {
    $beg = $arg;
  }
  elsif(not(defined($end)))
  {
    $end = $arg;
  }
  elsif(not(defined($inc)))
  {
    $inc = $arg;
  }
  elsif(not(defined($delim)))
  {
    $delim = $arg;
  }
  else
  {
    die("Invalid argument '$arg'.");
  }
}

$beg   = defined($beg)   ? $beg   : 1;
$end   = defined($end)   ? $end   : ($beg + int(100*rand));
$inc   = defined($inc)   ? $inc   : 1;
$delim = defined($delim) ? $delim : ' ';

my @vals;
my $max_len = 0;
for(my $i=$beg; $i<=$end; $i+=$inc)
{
  push(@vals,$i);

  my $len = length("$i");
  if($len > $max_len)
    { $max_len = $len; }
}

if($pad)
{
  for(my $i=0; $i<=$#vals; $i++)
  {
    my $len     = length($vals[$i]);
    my $zeros   = &makeZeros($max_len-$len);
    $vals[$i]   = $zeros . $vals[$i];
  }
}

print STDOUT join($delim,@vals), "\n";

exit(0);

sub makeZeros
{
  my $n = shift;

  my $zeros = '';
  for(my $i=0; $i<$n; $i++)
  {
    $zeros .= '0';
  }
  return $zeros;
}


__DATA__
syntax: range.pl BEG END INC DELIM

