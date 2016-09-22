#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/libset.pl";
require "$ENV{MYPERLDIR}/lib/liblist.pl";
require "libfile.pl";

my $verbose    = 1;
my @files;
my %files;
my @cols       = (0);
my $delim_in   = "\t";
my $delim_out  = ",";
my $min        = undef;
my $max        = undef;
my $col_ranges = 1;
my @totals;
my @combo_totals;
my $f = 0;
my $ordered = 0;

while(@ARGV)
{
   my $arg = shift @ARGV;
   if($arg eq '--help')
   {
      print STDOUT <DATA>;
      exit(0);
   }
   elsif(-f $arg)
   {
      push(@files, $arg);
      $files{$arg} = $f;
      print STDERR "'$arg' --> $f'\n";
      $f++;
   }
   elsif($arg eq '-q')
   {
      $verbose = 0;
   }
   elsif($arg eq '-k')
   {
      $col_ranges = shift @ARGV;
   }
   elsif($arg eq '-di' or $arg eq '-d')
   {
      $delim_in = shift @ARGV;
   }
   elsif($arg eq '-do')
   {
      $delim_out = shift @ARGV;
   }
   elsif($arg eq '-min')
   {
      $min = shift @ARGV;
   }
   elsif($arg eq '-max')
   {
      $max = shift @ARGV;
   }
   elsif($arg eq '-tot')
   {
      $arg = shift @ARGV;
      open(TOT, $arg) or die("Could not open totals file '$arg'");
      while(<TOT>)
      {
         s/^\s+//g;
         s/\s+$//g;
         my @tuple = split;
         chomp($tuple[$#tuple]);
         push(@totals, $tuple[0]);
      }
      close(TOT);
   }
   elsif($arg eq '-ctot')
   {
      $arg = shift @ARGV;
      open(TOT, $arg) or die("Could not open combination totals file '$arg'");
      while(<TOT>)
      {
         s/^\s+//g;
         s/\s+$//g;
         my @tuple = split;
         chomp($tuple[$#tuple]);
         push(@combo_totals, $tuple[0]);
      }
      close(TOT);
   }
   else
   {
      die("Invalid argument '$arg'");
   }
}

scalar(@files) >= 2 or die("Must supply at least 2 files");

my $max_cols = undef;
foreach my $file (@files)
{
   print STDERR "--> Studying file '$file'...";
   my $num_cols = &getNumCols($file, $delim_in);
   if(not(defined($max_cols)) or $num_cols > $max_cols)
   {
      $max_cols = $num_cols;
   }
   print STDERR " done. File has $num_cols columns.<--\n";
}

@cols = &parseRanges($col_ranges, $max_cols);
for(my $i = 0; $i <= $#cols; $i++)
{
   $cols[$i]--;
}

print STDERR "Here's the totals you gave me:\n";
foreach my $file (@files)
{
   my $i = $files{$file};
   my $total = $totals[$i];
   print STDERR "File '$file' $total\n";
}


# print STDERR "Columns = '", join(",", @cols), "' (from ranges='$col_ranges')\n";

my %sets;
my %sizes;
foreach my $file (@files)
{
   print STDERR "--> Reading in set from file '$file'...";

   # $sets{$file} = &setRead($file, $col, $delim_in);

   $sets{$file} = &setReadTuples($file, $delim_in, $delim_out, \@cols, not($ordered));

   $sizes{$file} = &setSize($sets{$file});

   my $size = $sizes{$file};

   print STDERR " done. Set of size $size read.<--\n";

   # &setPrint($sets{$file}, \*STDERR);
}

# print STDERR "All sets\n";
# &setsPrint(\%sets, \*STDERR);

print STDOUT "Combination";
if(scalar(@totals) > 0)
{
   print STDOUT "\tZ-score\tExpected\tStdDev";
}
print STDOUT "\tOverlaps\tSet Sizes\n";

my $combinations = &listCombinations(\@files, $min, $max);

my $combo_index = 0;
foreach my $combination (@{$combinations})
{
   my @combination  = split("\t", $combination);
   my %combination  = %{&list2Set(\@combination)};
   my $subsets      = &setsSubset(\%sets, \%combination);
   my $subsizes     = &setsSubset(\%sizes, \%combination);
   my @subsizes     = values(%{$subsizes});
   my $intersection = &setsIntersectionSelf($subsets);
   my $overlaps     = &setSize($intersection);

   # &setPrint($intersection, \*STDERR);

   print STDERR "$combination selection\n";
   # &setPrint(\%combination, \*STDERR);

   print STDERR "$combination subset:\n";
   # &setsPrint($subsets, \*STDERR);

   print STDERR "$combination intersections\n";
   # &setPrint($intersection, \*STDERR);

   print STDOUT join($delim_out, @combination);

   # print STDERR "%combination:\n";
   # &setPrint(\%combination, \*STDERR);

   print STDERR join($delim_out, @combination);

   if(scalar(@totals) > 0 and scalar(@combo_totals) > 0)
   {
      my $Px = 1;
      my $x = '(';
      my $t = '(';
      foreach my $file (@combination)
      {
         my $i        = $files{$file};
         my $fraction = $sizes{$file} / $totals[$i];
         $Px *= $fraction;

         $x .= ' ' . $sizes{$file};
         $t .= ' ' . $totals[$i];
      }
      $x .= ' )';
      $t .= ' )';

      my $Nx = $combo_totals[$combo_index];
      my $Ex = $Nx * $Px;
      my $Vx = $Nx * $Px * (1 - $Px);
      my $Sx = $Vx > 0 ? sqrt($Vx) : undef;
      my $Zx = defined($Sx) ? ($overlaps - $Ex) / $Sx : undef;

      $Sx = defined($Sx) ? $Sx : 'NaN';
      $Zx = defined($Zx) ? $Zx : 'NaN';

      print STDOUT "\t$Zx\t$Ex\t$Sx\t$Nx\t$Px ($x) ($t)";
      print STDERR "\t$Zx\t$Ex\t$Sx\t$Nx\t$Px ($x) ($t)";
   }

   print STDOUT "\t", $overlaps, "\t", join(" ", @subsizes), "\n";
   print STDERR "\t", $overlaps, "\t", join(" ", @subsizes), "\n";

   $combo_index++;
}

close(STDOUT);

print STDERR "All done (indeed).\n";

exit(0);


__DATA__
syntax: overlap_combinations.pl [OPTIONS] FILE1 FILE2 [FILE3 ...]

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Compare the values in column COL to the threshold in the file (default is 1).

-di DELIM: Set the input delimiter to DELIM (default is tab).

-do DELIM: Set the output delimiter to DELIM (default is comma).

-d DELIM: Same as -di

-min MIN: Set the minimum size of a combination to MIN (default is 1).

-max MAX: Set the maximum size of a combination to MAX (default is infinite).

-tot FILE: File containing the population size for each list.

-ctot FILE: File containing the possible size for each combination

-ord: Specify that the tuples read in are ordered (default is unordered).


