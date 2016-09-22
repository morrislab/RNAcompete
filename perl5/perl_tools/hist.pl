#!/usr/local/bin/perl

##############################################################################
##############################################################################
##
## hist.pl - Compute a histogram of the data in a tab-delimited file.
##
##############################################################################
##############################################################################
##
## Written by Josh Stuart.
##
##  Email address: jstuart@soe.ucsc.edu
##          Phone: (831) 459-1344
##
## Postal address: Department of Bioengineering, UCSC
##                 1156 High Street
##                 Santa Cruz, CA 95060
##
##       Web site: http://www.soe.ucsc.edu/~jstuart/
##
##############################################################################
##############################################################################

require "libfile.pl";
require "$ENV{MYPERLDIR}/lib/libstats.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-h', 'scalar',     0, undef]
                , [    '-k', 'scalar', undef, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-n', 'scalar', undef, undef]
                , [    '-m', 'scalar',   's', undef]
                , [  '-min', 'scalar',    10, undef]
                , [  '-max', 'scalar',   100, undef]
                , [  '-inc', 'scalar',    10, undef]
                , [ '-same', 'scalar',     0,     1]
                , [    '-f', 'scalar',     0,     1]
                , [    '-c', 'scalar', undef, undef]
                , [    '-t', 'scalar',     0,     1]
                , [    '-s', 'scalar', undef, undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose       = not($args{'-q'});
my $headers       = $args{'-h'};
my $delim         = $args{'-d'};
my $key_col       = defined($args{'-k'}) ? $args{'-k'}-1 : undef;
my $method        = $args{'-m'};
my $num_bin_min   = $args{'-min'};
my $num_bin_max   = $args{'-max'};
my $num_bin_inc   = $args{'-inc'};
my $same          = $args{'-same'};
my $freqs         = $args{'-f'};
my $centers_file  = $args{'-c'};
my $transpose     = $args{'-t'};
my $sigfigs_user  = $args{'-s'};
my $file          = $args{'--file'};

# If the user supplied the centers in a file, read them in.
my $global_centers = undef;
if(defined($centers_file) and ((-f $centers_file) or (-l $centers_file))) {
   $global_centers = &getFileNumbers($centers_file);
}

my @data;
my @num;
my @sum;
my @max;
my @min;
my $n = 0;
my $header = undef;
my $keys = undef;

my $max_sigfigs;

my $line_no = 0;
my $filep;
my $sprintf_ctrl;
open($filep, $file) or die("Could not open file '$file' for reading");
while(<$filep>) {
   $line_no++;
   my @x = split($delim);
   chomp($x[$#x]);

   if(defined($key_col)) {
      if(not(defined($keys))) {
         $keys = [];
      }
      push(@{$keys},splice(@x,$key_col,1));
   }

   if(scalar(@x) > $n) {
      $n = scalar(@x);
   }
   if($line_no > $headers) {
      my $xmax    = &vec_max(\@x);
      my $xmin    = &vec_min(\@x);
      if($transpose) {
         &recordColumnEntry(\@x,\@data,\@num,\@sum,\@max,\@min);
      }
      elsif($same) {
         &recordRowEntry(\@x,\@data,\@num,\@sum,\@max,\@min);
      }
      else {
         &removeNonNumbers(\@x);
         my $sigfigs = defined($sigfigs_user) ? $sigfigs_user : 1 + int(log($xmax-$xmin)/log(10));
         $sprintf_ctrl = '%' . '.' . $sigfigs . 'f';
         if(not(defined($max_sigfigs)) or $max_sigfigs < $sigfigs) {
            $max_sigfigs = $sigfigs;
         }

         @x = sort {$a <=> $b;} @x;

         my $counts = undef;
         my $centers = undef;

         my $numj = scalar(@x);
         # print STDERR "Number of elements in sample $line_no is $numj.\n";

         if(not(defined($global_centers))) {
            if($method eq 's') {
               ($centers,$counts) = &binUsingShimazakiShinomoto(\@x,$num_bin_min,$num_bin_max,$num_bin_inc);
            }
         }
         else {
            $centers = $global_centers;
         }
         if(not(defined($counts))) {
            $counts = &histogram(\@x,$centers);
         }

         if($freqs) {
            $counts = &getFreqsFromCounts($counts);
         }

         my $width = $$centers[1] - $$centers[0];

         my $num = scalar(@{$centers});

         my $keyn = defined($keys) ? scalar(@{$keys})-1 : 0;
         my $key = defined($keys) ? "'$$keys[$keyn]'" : $line_no;
         my $width_str = sprintf($sprintf_ctrl,$width);
         $verbose and print STDERR "Binned line $key. Bin width=$width_str, Num bins=$num.\n";
         $key = defined($keys) ? "$$keys[$keyn]" : undef;

         &printDiffCenters($centers,$counts,$key,$freqs,$sprintf_ctrl,$delim,1);
      }
   }
   elsif($transpose) {
      if(not(defined($header))) {
         $header = [];
      }
      for(my $j = 0; $j < @x; $j++) {
         if($x[$j] =~ /\S/) {
            $$header[$j] = defined($$header[$j]) ? ($$header[$j] . $delim . $x[$j]) : $x[$j];
         }
      }
   }
   else {
      print;
   }
}
close($filep);

# print STDERR "Biggest tuple had $n dimensions.\n";

if($same and not(defined($global_centers))) {
   $verbose and print STDERR "Forcing all samples to use the same bins.";
   my @all_data;
   foreach my $d (@data) {
      if(defined($d)) {
         push(@all_data, @{$d});
      }
   }

   @all_data = sort {$a <=> $b;} @all_data;

   my $xmin = $all_data[0];
   my $xmax = $all_data[$#all_data];

   $max_sigfigs = 1 + int(log($xmax-$xmin)/log(10));

   my $counts;
   if($method eq 's') {
      ($global_centers,$counts) = &binUsingShimazakiShinomoto(\@all_data,$num_bin_min,$num_bin_max,$num_bin_inc);
   }
}

if($transpose or $same) {
   my $num = scalar(@data);

   if(not($transpose) and defined($key_col)) {
      $header = $keys;
   }

   for(my $j = 0; $j < $num; $j++) {

      my $sigfigs = undef;
      if(not(defined($max_sigfigs))) {
         my $xmax = &vec_max($data[$j]);
         my $xmin = &vec_min($data[$j]);
         my $sf = 1 + int(log($xmax-$xmin)/log(10));
         if(not(defined($sigfigs)) or $sigfigs < $sf) {
            $sigfigs = $sf;
         }
      }
      else {
         $sigfigs = $max_sigfigs;
      }

      $sigfigs = defined($sigfigs_user) ? $sigfigs_user : $sigfigs;

      $sprintf_ctrl = '%' . '.' . $sigfigs . 'f';

      @{$data[$j]} = defined($data[$j]) ? sort {$a <=> $b;} @{$data[$j]} : undef;

      my $numj = defined($data[$j]) ? scalar(@{$data[$j]}) : 0;
      # print STDERR "Number of elements in sample $j is $numj.\n";

      my ($counts,$centers);

      if(not(defined($global_centers))) {
         if($method eq 's') {
            ($centers,$counts) = &binUsingShimazakiShinomoto($data[$j],$num_bin_min,$num_bin_max,$num_bin_inc);
         }
      }
      else {
         $centers = $global_centers;
      }

      if(not(defined($counts))) {
         $counts = &histogram($data[$j],$centers);
      }

      if($freqs) {
         $counts = &getFreqsFromCounts($counts);
      }

      my $width = $$centers[1] - $$centers[0];

      my $num   = scalar(@{$centers});

      if(defined($header) and defined($$header[$j])) {
         my $width_str = sprintf($sprintf_ctrl,$width);
         $verbose and print STDERR "Binned column '$$header[$j]'. Bin width=$width_str, Num bins=$num.\n";
      }
      else {
         $verbose and print STDERR "Binned column $j. Bin width=$width, Num bins=$num.\n";
      }

      my $key = defined($header) ? $$header[$j] : undef;

      if($same and ($j == 0)) {
         &printDiffCenters($centers,undef,'Centers',$freqs,$sprintf_ctrl,$delim,0);
         &printDiffCenters(undef,$counts,$key,$freqs,$sprintf_ctrl,$delim,0);
      }
      elsif($same and ($j > 0)) {
         &printDiffCenters(undef,$counts,$key,$freqs,$sprintf_ctrl,$delim,0);
      }
      else {
         &printDiffCenters($centers,$counts,$key,$freqs,$sprintf_ctrl,$delim,1);
      }
   }
}


exit(0);

sub recordColumnEntry {
   my ($x,$data,$num,$sum,$max,$min) = @_;
   for(my $j = 0; $j < scalar(@{$x}); $j++) {
      if(&isNumber($$x[$j])) {
         $$num[$j] += 1;
         $$sum[$j] += $$x[$j];
         $$data[$j][$$num[$j]-1] = $$x[$j];
         if(not(defined($$max[$j])) or ($$max[$j] < $$x[$j])) {
            $$max[$j] = $$x[$j];
         }
         if(not(defined($$min[$j])) or ($$min[$j] > $$x[$j])) {
            $$min[$j] = $$x[$j];
         }
      }
   }
}

sub removeNonNumbers {
   my ($x) = @_;
   my $n = scalar(@{$x});
   for(my $i = $n-1; $i >= 0; $i--) {
      if(not(&isNumber($$x[$i]))) {
         splice(@{$x},$i,1);
      }
   }
}

sub printDiffCenters {
   my($centers,$counts,$key,$freqs,$sprintf_ctrl,$delim,$print_extra_column) = @_;

   if(defined($centers)) {
      my @print_list;
      if($print_extra_column) {
         push(@print_list,'Centers');
      }
      if(defined($key)) {
         push(@print_list,$key);
      }
      for(my $i = 0; $i < @{$centers}; $i++) {
         push(@print_list, sprintf($sprintf_ctrl,$$centers[$i]));
      }
      print join($delim, @print_list), "\n";
   }

   if(defined($counts)) {
      my $label = $freqs ? 'Freqs' : 'Counts';
      my @print_list;
      if($print_extra_column) {
         push(@print_list,$freqs ? 'Freqs' : 'Counts');
      }
      if(defined($key)) {
         push(@print_list,$key);
      }
      for(my $i = 0; $i < @{$counts}; $i++) {
         if(defined($$counts[$i])) {
            push(@print_list,
               ($freqs ? sprintf($sprintf_ctrl,$$counts[$i]) : $$counts[$i]));
         }
         else {
            push(@print_list, '');
         }
      }
      print join($delim, @print_list), "\n";
   }
}

sub recordRowEntry {
   my ($x,$data,$num,$sum,$max,$min) = @_;
   my (@d, $n, $s, $mx, $mn);
   for(my $j = 0; $j < scalar(@{$x}); $j++) {
      if(&isNumber($$x[$j])) {
         $n += 1;
         $s += $$x[$j];
         push(@d,$$x[$j]);
         if(not(defined($mx)) or ($mx < $$x[$j])) {
            $mx = $$x[$j];
         }
         if(not(defined($mn)) or ($mn > $$x[$j])) {
            $mn = $$x[$j];
         }
      }
   }
   push(@{$data},\@d);
   push(@{$num}, $n);
   push(@{$sum}, $s);
   push(@{$max}, $mx);
   push(@{$min}, $mn);
}

__DATA__
syntax: hist.pl [OPTIONS]

OPTIONS are:

-q: Quiet mode (default is verbose)

-k KEY_COL: Set the key column to KEY_COL (default is none).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Number of header rows to ignore.

-m METHOD: Set the bin determination method. Allowed values for METHOD are:
    s - use the Shimazaki-Shinomoto iterative method (default)
    i - compute bin width as a function of the inter-quartile range
    l - compute the number of bins as a log factor of the number of data points.               

-same: Force all of the columns to use the same bin centers. By default, bins
       are found for each data column separately.

The following three options are only useful for the Shimazaki-Shinomoto method:

-min MINBINS: The minimum number of bins to consider (default is 10).

-max MAXBINS: The maximum number of bins to consider (default is 100).

-inc INCBINS: The step size in the number of bins (default is 10).

-c CENTERS_FILE: Supply the bin centers from the file CENTERS_FILE. By
                 default, the script determines the centers for each row
                 of the data.

-t: Transpose. Compute the histogram on the columns of the data file rather
               than the rows.

-f: Print out the frequencies instead of the counts.

