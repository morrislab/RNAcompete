#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";
require "$ENV{MYPERLDIR}/lib/libstats.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $data_file   = $ARGV[0];
my $key1  = $ARGV[1];
my $key2  = $ARGV[2];

my %args = &load_args(\@ARGV);
my $method = &get_arg("m", "Pearson", \%args);

my $vec1_str = `grep $key1 $data_file`;
my $vec2_str = `grep $key2 $data_file`;

my @row = split(/\t/, $vec1_str);
my @vec1;
for (my $i = 1; $i < @row; $i++)
{
  $vec1[$i - 1] = $row[$i];
}

my @row = split(/\t/, $vec2_str);
my @vec2;
for (my $i = 1; $i < @row; $i++)
{
  $vec2[$i - 1] = $row[$i];
}

@vec1 = &vec_center(\@vec1);
@vec2 = &vec_center(\@vec2);

my $correlation = -1000;

my $num;
if ($method eq "Pearson")
{
  ($correlation,$num) = &vec_pearson(\@vec1, \@vec2);
}

print "$correlation\n";

__DATA__

compute_correlation.pl <data file> <key 1> <key 2>

   Computes correlation between two vectors selected from a specified file

   -m <method>:     The correlation method to use (default: Pearson)

