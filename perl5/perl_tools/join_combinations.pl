#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/libstats.pl";

my $verbose       = 1;
my @combinations;
my @out_files;
my $col1          = 1;
my $col2          = 1;
my $delim         = "\t";

while(@ARGV)
{
   my $arg = shift @ARGV;
   if($arg eq '--help')
   {
      print STDOUT <DATA>;
      exit(0);
   }
   elsif($arg eq '-q')
   {
      $verbose = 0;
   }
   elsif($arg eq '-k')
   {
      $col1 = int(shift @ARGV);
      $col2 = $col1;
   }
   elsif($arg eq '-1')
   {
      $col1 = int(shift @ARGV);
   }
   elsif($arg eq '-2')
   {
      $col2 = int(shift @ARGV);
   }
   elsif($arg eq '-d')
   {
      $delim = shift @ARGV;
   }
   elsif(-f $arg)
   {
      open(FILE, $arg) or die("Could not open combinations file '$arg'");
      while(<FILE>)
      {
	 chomp;
	 my ($out_file, $combination) = split("\t");

	 my @files = split(/\s/, $combination);
	 push(@combinations, \@files);
	 push(@out_files, $out_file);
      }
      close(FILE);
   }
   else
   {
      die("Invalid argument '$arg'");
   }
}

($#combinations >= 0) or die("No combinations found in combinations file");

($#out_files == $#combinations) or die("Must have the same number of outputs as combinations.");

for(my $i = 0; $i <= $#combinations; $i++)
{
   my ($file1, $file2) = @{$combinations[$i]};
   my $out_file = $out_files[$i];

   my $join = "join.pl -1 $col1 -2 $col2 $file1 $file2 > $out_file";

   $verbose and print STDERR "--> $join <--\n";
   `$join`;
   $verbose and print STDERR "Done.\n";
}

exit(0);


__DATA__
syntax: overlaps.pl [OPTIONS] LIST_FILE

LIST_FILE contains 2 columns (columns seperated by a <tab>).  Column 1 contains
the name of the output file and column 2 contains the name of the file combinations
to merge.

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Compare the values in column COL to the threshold in the file (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-names FILE: Supplies the names of the combinations (in order)


