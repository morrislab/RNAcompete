#!/usr/bin/perl

require "$ENV{MYPERLDIR}/lib/libmap.pl";

use strict;

# my $dir = &getMapDir('Data') . '/Expression';

my $type = 'Expression';
my @files;
my $headers = 1;
my $verbose = 1;
my $delim   = "\t";
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

  elsif($arg eq '-h')
  {
    $headers = int(shift @ARGV);
  }

  elsif($arg eq '-d')
  {
    $delim = shift @ARGV;
  }

  elsif($arg eq '-type')
  {
    $type = shift @ARGV;
  }

  elsif(-f $arg)
  {
    push(@files,$arg);
  }
  else
  {
    die("Invalid argument '$arg'.");
  }
}

my @organisms = &getMapOrganismNames();

my $errors = 0;
foreach my $file (@files)
{
  my $fin; open($fin,$file) or die("Could not open file '$file'.");
  # Check Expression data.
  $errors += &checkExpressionData($file,$headers,$verbose);
}

exit(0);

sub checkExpressionData
{
  my ($file,$headers,$verbose) = @_;
  my $errors   = 0;
  my $beg      = $headers + 1;
  my $pre_pipe = "cut -f 1 | body.pl $beg -1";

  # Check if every row has the same number of columns.
  my $row_sizes = &numTokensPerLine($file, $delim, 1);
  my $total_rows = scalar(@{$row_sizes});

  my %size2rows;
  for(my $r = 0; $r < $total_rows; $r++) {
     my $size = $$row_sizes[$r];
     if(not(exists($size2rows{$size}))) {
        $size2rows{$size} = [];
     }
     push(@{$size2rows{$size}}, $r);
  }
  my @sizes     = sort { $a <=> $b; } keys(%size2rows);
  my $num_sizes = scalar(@sizes);

  $verbose and print STDOUT "[$file] Number of rows = $total_rows.\n";

  $verbose and print STDOUT "[$file] Row size equality check --> ";

  if($num_sizes > 1) {
     my $min  = $sizes[0];
     my $max  = $sizes[$num_sizes-1];
     my $med  = &findMedian(\@sizes, \%size2rows, $total_rows);
     my $first_min_row = $size2rows{$min}[0] + 1;
     my $first_max_row = $size2rows{$max}[0] + 1;
     $verbose and print STDOUT "Failed.  $num_sizes different row sizes exist; min=$min, max=$max, median=$med\n";
     $verbose and print STDOUT "[$file] First row with $min column(s) is $first_min_row; first row with $max column(s) is $first_max_row.\n";
  }
  else {
     my $size = $sizes[0];
     $verbose and print STDOUT "Passed.  Every row has exactly $size columns.\n";
  }

  if($num_sizes > 1 and $num_sizes <= 10) {
     for(my $s = 0; $s < @sizes; $s++) {
        my $size = $sizes[$s];
        my $num_rows = scalar(@{$size2rows{$size}});
        $verbose and print STDOUT "[$file]\t$num_rows row(s) have size $size.\n";
     }
  }

  # Check if the keys are sorted and unique.
  $verbose and print STDOUT "[$file] Keys sorted? --> ";
  system("cat $file | $pre_pipe | sort -c >& /dev/null");
  my $sorted = $?;
  if($sorted != 0)
  { 
    $verbose and print STDOUT "!!! *NO* !!!\n";
    $errors++;
  }
  else
  {
    $verbose and print STDOUT "Yes.\n";
  }

  $verbose and print STDOUT "[$file] Keys unique? --> ";
  my $num_file = `cat $file | $pre_pipe | wc`;
  my $num_uniq = `cat $file | $pre_pipe | uniq | wc`;

  if($num_file ne $num_uniq) {
    $verbose and print STDOUT "!!! *NO* !!!\n";
    $errors++;
  }
  else {
    $verbose and print STDOUT "Yes.\n";
  }

  return $errors;
}

sub findMedian {
   my ($sorted_sizes, $size2entries, $total_entries) = @_;

   if($total_entries <= 0) {
      return -1;
   }

   my $e = 0;
   foreach my $size (@{$sorted_sizes}) {
      my $num = scalar(@{$$size2entries{$size}});
      $e += $num;
      my $fraction = $e / $total_entries;
      if($fraction >= 0.50) {
         return $size;
      }
   }

   return -1;
}

__DATA__
syntax: check_data.pl [OPTIONS] FILE1 [FILE2 FILE3 ...]

Performs various integrity checks on the MAP data and generates a report
about which items do not meet certain criteria.

OPTIONS are:

-q: Quiet mode.

-type DATA_TYPE: specify the data type for the input files.  If not supplied,
                 the script will try to guess it from the extension(s) of the
                 FILE(s) (this obviously doesn't work for files supplied to
                 standard input).  The type defaults to 'Expression' in this
                 case.  Valid types are:

                         Expression

-h NUM: specify that NUM number of header rows preceed data in the file (default is 1).
