#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $file = $ARGV[0];

my %args = load_args(\@ARGV);

my $beginning = get_arg("b", 0, \%args);
my $target_column = get_arg("c", 0, \%args);
my $start_counter = get_arg("n", 0, \%args);
my $column_string = get_arg("s", "", \%args);

open(FILE, "<$file") or die "could not open $file\n";
while (<FILE>)
{
  chop;

  my $str;
  if (length($column_string) > 0) { $str = $column_string; }
  else { $str = $start_counter++; }

  my @row = split(/\t/);

  for (my $i = 0; $i < @row; $i++)
  {
    if ($i == $target_column)
    {
      if ($beginning == 1) { print "$str$row[$i]\t"; }
      else { print "$row[$i]$str\t"; }
    }
    else { print "$row[$i]\t"; }
  }

  print "\n";
}

__DATA__

add_to_column.pl <file>

   Adds text to a column for each line in a file.

So it could turn:
	A    B
	Z    C
	M    N

Into:
    A_G  B
    Z_G  C
    M_G  N

   -b:           add to the beginning of the column (default: add at the end)
   -c <num>:     add to the num-th column (default: 0)
   -n <num>      add a column counter, starting at num.
   -s <str>      add a column with the specified string

