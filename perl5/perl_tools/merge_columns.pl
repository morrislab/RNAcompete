#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";
require "libfile.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $file = $ARGV[0];

my %args = load_args(\@ARGV);

my $column_1 = get_arg("1", 0, \%args);
my $column_2 = get_arg("2", 0, \%args);
my $delimiter = get_arg("d", "", \%args);
my $reverse = get_arg("r", 0, \%args);

open(FILE, "<$file") or die "could not open $file\n";
while (<FILE>)
{
  chop;

  my @row = split(/\t/);

  for (my $i = 0; $i < @row; $i++)
  {
    if ($i == $column_1)
    {
      if ($reverse == 1)
      {
	print "$row[$column_2]$delimiter$row[$column_1]\t";
      }
      else
      {
	print "$row[$column_1]$delimiter$row[$column_2]\t";
      }
    }
    elsif ($i != $column_2) { print "$row[$i]\t"; }
  }

  print "\n";
}

__DATA__

merge_columns.pl <file>

   Merges 2 columns with a specified delimiter

   -1 <num>      First column (default: 0)
   -2 <num>      Second column (default: 1)
   -d <delim>    Delimiter (default: "")
   -r            If specified, then it's reverse: column 2 goes before column 1

