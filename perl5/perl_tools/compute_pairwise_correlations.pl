#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";
require "$ENV{MYPERLDIR}/lib/libstats.pl";
require "libfile.pl";

# Flush standard output immediately (so we don't have to wait for results!).
$| = 1;

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $first_file   = $ARGV[0];
my $second_file  = $ARGV[1];

my %args         = &load_args(\@ARGV);
my $verbose      = &get_arg("q", 1, \%args);

my $first_key    = &get_arg("1k", 0, \%args);
my $first_start  = &get_arg("1s", 1, \%args);
my $first_end    = &get_arg("1e", -1, \%args);
my $first_row    = &get_arg("1r", 0, \%args);

my $second_key   = &get_arg("2k", 0, \%args);
my $second_start = &get_arg("2s", 1, \%args);
my $second_end   = &get_arg("2e", -1, \%args);
my $second_row   = &get_arg("2r", 0, \%args);

my $method       = &get_arg("m", "Pearson", \%args);
my $center       = &get_arg("center", 0, \%args);
my $print_data   = &get_arg("data", 0, \%args);

my $iter         = 0;
my $passify      = 1000;
my $first_lines  = &numRows($first_file, 0);
my $second_lines = &numRows($second_file, 0);
my $total        = ($first_lines - $first_row) * ($second_lines - $second_row);

$verbose and print STDERR "Computing $total pairwise $method correlations.\n";
my $first_filep;
open($first_filep, $first_file);
for (my $i = 0; $i < $first_row; $i++)
  { <$first_filep>; }
while(<$first_filep>)
{
  chop;

  my @first_row = split(/\t/);

  my @first;
  my $last = $first_end >= 0 ? $first_end : scalar(@first_row) + $first_end;
  for (my $i = $first_start; $i < $last; $i++)
    { $first[$i - $first_start] = $first_row[$i]; }

  if ($center == 1)
    { @first = &vec_center(\@first); }

  my $second_filep;
  open($second_filep, $second_file);
  for (my $i = 0; $i < $second_row; $i++)
    { <$second_filep>; }
  while(<$second_filep>)
  {
    $iter++;

    chop;

    my @second_row = split(/\t/);
    my @second;
    $last = $second_end >= 0 ? $second_end : scalar(@second_row) + $second_end;
    for (my $i = $second_start; $i < $last; $i++)
      { $second[$i - $second_start] = $second_row[$i]; }

    if ($center == 1)
      { @second = &vec_center(\@second); }

    my $correlation = -1000;
    if ($method eq "Pearson")
      { $correlation = &vec_pearson(\@first, \@second); }

    print STDOUT "$first_row[$first_key]\t$second_row[$second_key]\t$correlation";

    if ($print_data)
    {
      for (my $i = 0; $i < @first; $i++) { print STDOUT "\t$first[$i]"; }
      for (my $i = 0; $i < @second; $i++) { print STDOUT "\t$second[$i]"; }
    }

    print STDOUT "\n";

    if($verbose and $iter % $passify == 0)
    {
      my $done = int($iter / $total * 100.0);
      print STDERR "$iter out of $total $method correlations computed ($done% done).\n";
    }
  }
  close($second_filep);
}

__DATA__

compute_pairwise_correlations.pl <data file 1> <data file 2>

   Computes pairwise correlations between

   -1k <num>:       The key column in the first data file (default: 0)
   -1s <num>:       The start column in the first data file (default: 1)
   -1e <num>:       The last column in the first data file (default: 1)
   -1r <num>:       The row where data in the first file begins (default: 0)

   -2k <num>:       The key column in the second data file (default: 0)
   -2s <num>:       The start column in the second data file (default: 1)
   -2e <num>:       The last column in the second data file (default: 1)
   -2r <num>:       The row where data in the second file begins (default: 0)

   -m <method>:     The correlation method to use (default: Pearson)

   -center:         If specified, then center the vectors before the pearson

   -data:           If specified, prints the actual data of the vectors as well

   -q               Quiet mode (default is verbose).
