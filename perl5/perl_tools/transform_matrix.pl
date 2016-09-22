#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";
require "$ENV{MYPERLDIR}/lib/bio_system.pl";
require "libfile.pl";

sub transform
{
  my ($data_file, $transformation, $header_rows, $header_cols) = @_;

  open(DATA_FILE, "<$data_file") or die "Could not open $data_file\n";

  for (my $i = 0; $i < $header_rows; $i++)
  {
    my $line = <DATA_FILE>;
    print $line;
  }

  while(<DATA_FILE>)
  {
    chop;

    my @row = split(/\t/);

    for (my $i = 0; $i < @row; $i++)
    {
      if ($i < $header_cols)
      {
	print "$row[$i]\t";
      }
      elsif (length($row[$i]) == 0)
      {
	print "\t";
      }
      else
      {
	if ($transformation eq "log2")
	{
	  my $log2 = log($row[$i]) / log(2);
	  $log2 = format_number($log2, 3);
	  print "$log2\t";
	}
      }
    }
    print "\n";
  }
}

#--------------------------------------------------------------------------------
# STDIN
#--------------------------------------------------------------------------------
if (length($ARGV[0]) > 0)
{
  my %args = load_args(\@ARGV);

  transform($ARGV[0],
	    get_arg("t", "log2", \%args),
	    get_arg("r", 0,      \%args),
	    get_arg("c", 0,      \%args));
}
else
{
  print "Usage: transform_matrix.pl data_file\n";
  print "      -t <transformation>: Supporting: log2/ (the default)\n";
  print "      -r <header rows>:    the number of header rows in before the actual data starts (default 0)\n";
  print "      -c <header cols>:    the number of header column in each row before the actual data starts (default 0)\n\n";
}

1
