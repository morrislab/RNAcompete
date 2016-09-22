#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";
require "$ENV{MYPERLDIR}/lib/libstats.pl";
require "libfile.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $file = $ARGV[0];

my %args = load_args(\@ARGV);

my $pvalue_type = get_arg("p", "HyperGeometric", \%args);
my $fixed_k = get_arg("k", "-1", \%args);
my $column_k = get_arg("kc", "0", \%args);
my $fixed_n = get_arg("n", "-1", \%args);
my $column_n = get_arg("nc", "1", \%args);
my $fixed_K = get_arg("K", "-1", \%args);
my $column_K = get_arg("Kc", "2", \%args);
my $fixed_N = get_arg("N", "-1", \%args);
my $column_N = get_arg("Nc", "3", \%args);

open(FILE, "<$file") or die "could not open $file\n";
while(<FILE>)
{
  chop;

  my @row = split(/\t/);

  my $k = $fixed_k == -1 ? $row[$column_k] : $fixed_k;
  my $n = $fixed_n == -1 ? $row[$column_n] : $fixed_n;
  my $K = $fixed_K == -1 ? $row[$column_K] : $fixed_K;
  my $N = $fixed_N == -1 ? $row[$column_N] : $fixed_N;

  my $pvalue;
  if ($pvalue_type eq "HyperGeometric")
  {
    $pvalue = &ComputeHyperPValue($k, $K, $n, $N);
    $pvalue = $k < $K/$N*$n ? 1 - $pvalue : $pvalue;
    $pvalue = format_number($pvalue, 5);
  }

  print "$k\t$n\t$K\t$N\t$pvalue\n";
}


__DATA__

compute_pvalues.pl <file>

   Computes pvalues for each line in a file.

   -p <str>          Type of pvalue (default: HyperGeometric)

   -k <num>          hypergeometric: fixed 'k' throughout
   -kc <num>         hypergeometric: column for 'k' in the data file

   -n <num>          hypergeometric: fixed 'n' throughout
   -nc <num>         hypergeometric: column for 'n' in the data file

   -K <num>          hypergeometric: fixed 'K' throughout
   -Kc <num>         hypergeometric: column for 'K' in the data file

   -N <num>          hypergeometric: fixed 'N' throughout
   -Nc <num>         hypergeometric: column for 'N' in the data file

