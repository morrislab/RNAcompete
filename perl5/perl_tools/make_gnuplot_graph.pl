#!/usr/bin/perl

use strict;

require "$ENV{MYPERLDIR}/lib/load_args.pl";

if ($ARGV[0] eq "--help")
{
  print STDOUT <DATA>;
  exit;
}

my $data_file = $ARGV[0];

my %args = load_args(\@ARGV);

my $x_column = get_arg("x", 1, \%args);
my $y_column = get_arg("y", 2, \%args);

my $output_file = get_arg("o", "", \%args);

my $data_style = get_arg("ds", "point", \%args);
my $point_size = get_arg("ps", 0.6, \%args);

my $log_scale_x = get_arg("lsx", 0, \%args);
my $log_scale_y = get_arg("lsy", 0, \%args);

my $x_label = get_arg("xl", "", \%args);
my $y_label = get_arg("yl", "", \%args);

my $extra_command = get_arg("c", "", \%args);

print "set term gif medium\n";
print "set output \"$output_file\"\n";
print "set data style $data_style\n";
print "set pointsize $point_size\n";
print "set size square\n";

if ($log_scale_x) { print "set logscale x\n"; }
if ($log_scale_y) { print "set logscale y\n"; }

if (length($x_label) > 0) { print "set xlabel \"$x_label\"\n"; }
if (length($y_label) > 0) { print "set ylabel \"$y_label\"\n"; }

if (length($extra_command) > 0)
{
  print "plot $extra_command, \"$data_file\" using $x_column:$y_column with p lt 3 pt 8\n";
}
else
{
  print "plot \"$data_file\" using $x_column:$y_column with p lt 3 pt 8\n";
}


__DATA__

make_gnuplot_graph.pl <data file>

   Make a gnuplot graph

   -x <num>:        Index of the x column (x-axis). Note: 1-based
   -y <num>:        Index of the y column (x-axis). Note: 1-based

   -o <file>:       The name of the gif file to produce

   -ds <style>:     Data style (line or point default: point)
   -ps <num>:       Point size (default: 0.2)

   -lsx             Log scale for x-axis
   -lsy             Log scale for y-axis

   -xl <label>      Label for x-axis
   -yl <label>      Label for y-axis

   -c <command>     Extra command for plotting (e.g. [0.00001:1] 3.7)

