#!/usr/bin/perl

use strict;

require "load_args.pl";
require "libfile.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $file = $ARGV[0];

my %args = load_args(\@ARGV);

my $beginning = get_arg("b", 0, \%args);
my $start_counter = get_arg("n", 0, \%args);
my $column_string = get_arg("s", "", \%args);

open(FILE, "<$file") or die "could not open $file\n";
while (<FILE>)
{
  chop;

  my $str;
  if (length($column_string) > 0) { $str = $column_string; }
  else { $str = $start_counter++; }

  if ($beginning == 1) { print "$str\t$_\n"; }
  else { print "$_\t$str\n"; }
}

__DATA__

add_column.pl <file>

   Adds a column to some location in each of the lines of a file.
   Default: adds a new column at the end (much like paste.pl - 'end_thing').

   -b:           add the column as the first in the file (default: add at the end)
   -n <num>      add a column counter, starting at num.
   -s <str>      add a column with the specified string
