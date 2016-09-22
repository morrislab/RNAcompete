#!/usr/bin/perl

require "libfile.pl";
require "$ENV{MYPERLDIR}/lib/libstats.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [     '-q', 'scalar',         0,     1]
                , [     '-k', 'scalar',         0, undef]
                , [     '-s', 'scalar',         1, undef]
                , [     '-e', 'scalar',        -1, undef]
                , [     '-r', 'scalar',         0, undef]
                , [     '-m', 'scalar', 'Pearson', undef]
                , [     '-c', 'scalar',         0,     1]
                , ['-center', 'scalar',         0,     1]
                , [     '-l', 'scalar',     undef, undef]
                , [ '-print', 'scalar',     undef, undef]
                , [   '-rev', 'scalar',         0,     1]
                , [     '-d', 'scalar',      "\t", undef]
                , [   '-log', 'scalar',         0,     1]
                , [     '-h', 'scalar',         0, undef]
                , [ '--file', 'scalar',       '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $file         = $args{'--file'};
my $verbose      = not($args{'-q'});
my $key_column   = $args{'-k'};
my $start_column = $args{'-s'};
my $end_column   = $args{'-e'};
my $first_row    = $args{'-r'};
my $method       = $args{'-m'};
my $consecutive  = $args{'-c'};
my $center       = $args{'-center'};
my $key_list     = $args{'-l'};
my $print_cutoff = $args{'-print'};
my $reverse      = $args{'-rev'};
my $take_log     = $args{'-log'};
my $delim        = $args{'-d'};
my $headers      = $args{'-h'};

my %keys;
if (defined($key_list))
{
  open(KEYS, $key_list);
  while(<KEYS>)
  {
    chomp;

    $keys{$_} = "1";
  }
  close(KEYS);
}

open(FILE, $file);

for (my $i = 0; $i < $first_row; $i++) { <FILE>; }

my @rows;
my @keys;
my $rows_counter = 0;

while(<FILE>)
{
  my ($key, $x) = &get_row_data($_);

  if(not(defined($key_list)) or exists($keys{$key}))
  {
    if($rows_counter >= $headers)
    {
       for(my $i = 0; $i < scalar(@{$x}); $i++)
       {
          $$x[$i] = (defined($$x[$i]) and not($$x[$i] =~ /NaN/i)) ?
             (($take_log and ($$x[$i] > 0)) ?
                log($$x[$i]) / log(10) : $$x[$i]) : undef;
       }
    }

    $keys[$rows_counter] = $key;

    $rows[$rows_counter] = $x;

    $rows_counter++;

    $verbose and print STDERR "Read $rows_counter rows of data that matched given keys.\n";
  }
}
# print "num_rows=" . $rows_counter . "\n";
# my $sum_x = 0;
# my $sum_xx = 0;
# my $num_x = 0;

my @is_significant;
my %r_ij;
my %d_ij;
for (my $i = 0; $i < scalar(@rows) - 1; $i++)
{
  if ($i % 10 == 0) { print STDERR "Processing $i...\n"; }

  my $end = $consecutive ? $i + 1 : scalar(@rows) - 1;

  $verbose and print STDERR "$i. Computing correlations for gene $keys[$i].\n";

  for (my $j = $i + 1; $j <= $end; $j++)
  {
    my $metric     = undef;

    my $dimensions = 0;

    ($metric) = &dot_product($rows[$i], $rows[$j]);
    $dimensions = 0;

    if(defined($metric))
    {
       # $sum_x += $metric;
       # $sum_xx += $metric * $metric;
       # $num_x++;

      # print STDERR "$metric [$print_cutoff]\n";
      if(not(defined($print_cutoff)) or $metric >= $print_cutoff)
      {
         $is_significant[$i] = 1;
         $is_significant[$j] = 1;
         $r_ij{$i,$j} = $metric;
         $d_ij{$i,$j} = $dimensions;
      }
    }
    elsif(not(defined($print_cutoff)))
    {
       $is_significant[$i] = 1;
       $is_significant[$j] = 1;
       $r_ij{$i,$j} = undef;
       $d_ij{$i,$j} = 0;
    }
  }
}

for(my $i = 0; $i < scalar(@rows) - 1; $i++)
{
   $verbose and print STDERR "$i. Printing correlations for gene $keys[$i].\n";

   if($is_significant[$i])
   {
      my $end = $consecutive ? $i + 1 : scalar(@rows) - 1;
      for (my $j = $i + 1; $j <= $end; $j++)
      {
         if($is_significant[$j])
         {
            my $rij = $r_ij{$i,$j};
            my $r   = defined($rij) ? "$rij" : 'NaN';
            my $d   = $d_ij{$i,$j};
            print STDOUT "$keys[$i]\t$keys[$j]\t$r\t$d\n";
         }
      }
   }
}

# if(not(defined($print_cutoff)))
# {
#    if ($num_x > 0)
#    {
#      print "Num  = " . $num_x . "\n";
#      print "Mean = " . ($sum_x / $num_x) . "\n";
#      print "Std  = " . sqrt((($sum_xx / $num_x) - ($sum_x / $num_x) * ($sum_x / $num_x))) . "\n";
#    }
# }

sub get_row_data
{
  my ($row_str) = @_;

  my @row = split(/\t/, $row_str);

  chomp($row[$#row]);

  my $key = $row[$key_column];

  my $end = $end_column >= 0 ? $end_column : @row;

  my @row_data;
  for (my $i = $start_column; $i <= $end; $i++)
  { 
     $row_data[$i - $start_column] = $row[$i];
  }

  if ($center == 1)
     { @row_data = &vec_center(\@row_data); }

  return ($key, \@row_data);
}

__DATA__

compute_all_pairwise_correlations.pl <data file>

   Computes all pairwise correlations between all pairs of genes in data file

   -k <num>:        The key column in the first data file (default: 0)
   -s <num>:        The start column in the first data file (default: 1)
   -e <num>:        The last column in the first data file (default: -1 for all columns)
   -r <num>:        The first row in the data file (default: 0)

   -m <method>:     The correlation method to use (default: Pearson)

   -l <file name>:  List of keys on which to work

   -center:         If specified, then center the vectors before the pearson

   -print CORR:     Print correlations that are greater than CORR to standard
                    output (and don't print summary data).

   -rev             Print out correlations that are less than the cutoff.

   -c               Consecutive.  Instead of computing all pairs, just
                    compute correlations between consecutive entries as
                    supplied by the input file.

