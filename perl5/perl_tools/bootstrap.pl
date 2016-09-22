#!/usr/bin/perl

use strict;

if ($ARGV[0] eq "--help") { print STDOUT <DATA>; }

my $file = $ARGV[0];

my @rows;
my $num_rows = 0;

open(FILE, "<$file");
while(<FILE>)
{
  $rows[$num_rows++] = $_;
}

for (my $i = 0; $i < $num_rows; $i++)
{
  my $row = int(rand($num_rows));
  print $rows[$row];
}

__DATA__

bootstrap.pl input_file

Generates an output file with the same number of rows as in the input file except that
the rows were sampled randomly (with replacements) from the input file.

