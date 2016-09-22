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

my $column = get_arg("c", -1, \%args);
my $min_filter = get_arg("min", "None", \%args);
my $max_filter = get_arg("max", "None", \%args);
my $skip_rows = get_arg("sk", 0, \%args);

open(FILE, "<$file");

for (my $i = 0; $i < $skip_rows; $i++) { my $line = <FILE>; print $line; }

while(<FILE>)
{
  chop;

  my @row = split(/\t/);

  if ($column ne "-1") { if (&pass_filter($row[$column]) == 1) { print "$_\n"; } }
  else
  {
    for (my $i = 0; $i < @row; $i++)
    {
      if (&pass_filter($row[$i]) == 1)
      {
	print "$_\n";
	last;
      }
    }
  }
}

sub pass_filter
{
  my ($num) = @_;

  my $pass = 1;

  my $sci_number = $num =~ /^[0-9\.]+[Ee][\-][0-9]+/;

  if ($num =~ /[A-Z]/ and $sci_number != 1) { if ($min_filter ne "None" or $max_filter ne "None") { $pass = 0; } }

  if ($min_filter ne "None" and $num < $min_filter) { $pass = 0; }
  if ($max_filter ne "None" and $num > $max_filter) { $pass = 0; }

  return $pass;
}

__DATA__

filter.pl <data file>

   Filters the rows of a file based on filters. A row is printed if it passes
   the filter. The filter can be defined on a specific column or if no column
   is specified, then the row passes the filter if any of the columns passes.

   -c <num>:         The column to which the filter is applied (if not specified,
                     then if either column passes, the row passes.
   -min <num>:       Filter passes if the number is above <num>
   -max <num>:       Filter passes if the number is below <num>

   -sk <num>:        Print first num rows without filtering

