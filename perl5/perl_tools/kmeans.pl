#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";
require "$ENV{MYPERLDIR}/lib/bio_system.pl";
require "$ENV{MYPERLDIR}/lib/libstats.pl";

my $k_null_value = "K___NULL___K";

#---------------------------------------------------------------------------------
# perform k-means
#---------------------------------------------------------------------------------
sub vec_kmeans (\@\@$$)
{
  my ($vec_str, $seeds_str, $K, $max_iterations) = @_;

  my @vec = @{$vec_str};
  my @clusters = @{$seeds_str};

  my $iterations = 0;
  my $done = 0;
  my @assignments;
  my @num_per_cluster;
  while (!$done)
  {
    #------------------------------------------------------------------
    # according to the current clusters, associate points with clusters
    #------------------------------------------------------------------
    for (my $i = 0; $i < $K; $i++) { $num_per_cluster[$i] = 0; }

    my $any_changes = 0;
    for (my $j = 0; $j < @vec; $j++)
    {
      if (length($vec[$j]) > 0)
      {
	my $cur_label = 0;
	my $best_distance = 100000000;
	for (my $cluster = 0; $cluster < $K; $cluster++)
	{
	  my $d = $vec[$j] - $clusters[$cluster];
	  my $distance += $d * $d;
	  $distance = sqrt($distance);

	  if ($distance < $best_distance)
	  {
	    $cur_label = $cluster;
	    $best_distance = $distance;
	  }
	}
	
	if ($assignments[$j] != $cur_label) { $any_changes = 1; }
	
	$assignments[$j] = $cur_label;
	$num_per_cluster[$cur_label]++;
      }
      else { $assignments[$j] = "?"; }
    }

    #---------------------------------------------------------------------------------
    # according to the calculated cluster assignments, recalculate the cluster centers
    #---------------------------------------------------------------------------------
    for (my $cluster = 0; $cluster < $K; $cluster++) { $clusters[$cluster] = 0; }

    for (my $j = 0; $j < @vec; $j++)
    {
      my $cluster = $assignments[$j];

      if ($cluster ne "?") { $clusters[$cluster] += $vec[$j] / $num_per_cluster[$cluster]; }
    }

    $iterations++;
    if ($iterations == $max_iterations) { $done = 1; }
    if ($iterations > 10 && $any_changes == 0) { $done = 1; }

    # print STDERR "Finished iteration $iterations (maximum $max_iterations), changes = $any_changes\n";
  }

  #print "@num_per_cluster @clusters\n";
  return @assignments;
}

#--------------------------------------------------------------------------------
# kmeans
#--------------------------------------------------------------------------------
sub kmeans
{
  my ($data_file, $K, $max_iterations, $seed, $labels, $skip_rows, $skip_cols, $force_num_cols) = @_;

  $seed = "-1,0,1";
  #$seed = "MIN,MEDIAN,MAX";
  $labels = "-1,0,1";

  my @seed_vec = split(/\,/, $seed);
  my @label_vec = split(/\,/, $labels);

  open(DATA_FILE, "<$data_file");

  for (my $i = 0; $i < $skip_rows; $i++) { my $skip_line = <DATA_FILE>; print $skip_line; }

  while(<DATA_FILE>)
  {
    chop;

    my @vec = split(/\t/);
    my @data_vec;

    my $num = @vec;
    #print "$num";

    for (my $i = 0; $i < $skip_cols; $i++)
    {
      print "$vec[$i]\t";
    }

    for (my $i = $skip_cols; $i < @vec; $i++)
    {
      $data_vec[$i - $skip_cols] = $vec[$i];
    }

    if ($seed eq "MIN,MEDIAN,MAX")
    {
      my $vec_size = @vec;
      $seed_vec[0] = vec_nth_stat(\@vec, 3);
      $seed_vec[1] = vec_nth_stat(\@vec, int($vec_size / 2));
      $seed_vec[2] = vec_nth_stat(\@vec, $vec_size - 3);
      print "@seed_vec\n";
    }

    my @clustered = vec_kmeans(@data_vec, @seed_vec, $K, $max_iterations);

    my $num_columns = $force_num_cols eq $k_null_value ? @clustered : ($force_num_cols - $skip_cols);
    for (my $i = 0; $i < $num_columns; $i++)
    {
      #if ($clustered[$i] eq "?" || length($clustered[$i]) == 0) { print "?\t"; }
      if ($clustered[$i] eq "?" || length($clustered[$i]) == 0) { print "0\t"; }
      else                       { print "$label_vec[$clustered[$i]]\t"; }
    }

    print "\n";
  }
}

#--------------------------------------------------------------------------------
# STDIN
#--------------------------------------------------------------------------------
if (length($ARGV[1]) > 0)
{
  my %args = load_args(\@ARGV);

  kmeans($ARGV[0],
	 get_arg("k", 3,             \%args),
	 get_arg("m", 50,            \%args),
	 get_arg("s", $k_null_value, \%args),
	 get_arg("l", $k_null_value, \%args),
	 get_arg("r", 0,             \%args),
	 get_arg("c", 0,             \%args),
	 get_arg("nc", $k_null_value,\%args));
}
else
{
  print "Usage: kmeans.pl data_file\n";
  print "      -k <num_clusters>:   the number of clusters to find (default 3)\n";
  print "      -m <max iterations>: the maximum number of iterations allowed within each kmean for each data item (default 50)\n";
  print "      -s <seed>:           the seeding of the centers separated by commas \"-1,0,1\"\n";
  print "      -l <labels>:         for each of the clusters, we can associate labels, separated by commas e.g. \"-1,0,1\"\n";
  print "      -r <header rows>:    the number of header rows in before the actual data starts (default 0)\n";
  print "      -c <header cols>:    the number of header column in each row before the actual data starts (default 0)\n\n";
  print "      -nc <num_cols>:      force this number of columns\n\n";
}

1
