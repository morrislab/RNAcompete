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

my $column = get_arg("c", 0, \%args);
my $add_number = get_arg("a", 0, \%args);
my $subtract_number = get_arg("s", 0, \%args);

open(FILE, "<$file") or die "could not open $file\n";
while (<FILE>)
{
  chop;

  my @row = split(/\t/);

  for (my $i = 0; $i < @row; $i++)
  {
    if ($i == $column)
    {
      my $num = $row[$i] + $add_number;
      $num -= $subtract_number;
      print "$num\t";
    }
    else
    {
      print "$row[$i]\t";
    }
  }
  print "\n";
}

__DATA__

modify_column.pl <file>

   Modifies a column according to predefined operations

   -c <num>      The column to modify (default: 0)
   -a <num>      Add <num> to the column (default: 0)
   -s <num>      Substract <num> to the column (default: 0)

