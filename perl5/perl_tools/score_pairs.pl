#!/usr/local/bin/perl

##############################################################################
##############################################################################
##
## score_pairs.pl
##
##############################################################################

require "libfile.pl";
require "$ENV{MYPERLDIR}/lib/libstats.pl";
# require "libfile.pl";
# require "libstats.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;


my @flags   = (
                  [    '-q', 'scalar',       0,     1]
                , [    '-k', 'scalar',       1, undef]
                , [    '-d', 'scalar',    "\t", undef]
                , [    '-m', 'scalar','euclid', undef]
                , [    '-h', 'scalar',       0, undef]
                , ['--file', 'scalar',     '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'})) {
   print STDOUT <DATA>;
   exit(0);
}

my $verbose = not($args{'-q'});
my $col     = int($args{'-k'}) - 1;
my $delim   = &interpMetaChars($args{'-d'});
my $metric  = $args{'-m'};
my $headers = $args{'-h'};
my $file    = $args{'--file'};
my @extra   = @{$args{'--extra'}};

my $filep;
open($filep, $file) or die("Could not open file '$file' for reading");
my $line = 0;
my @data;
my @keys;
while(<$filep>) {
   ++$line;
   if($line > $headers) {
      my @x = split($delim, $_);
      chomp($x[$#x]);
      my $key = splice(@x,$col,1);
      push(@keys,$key);
      push(@data,\@x);
   }
}
close($filep);

my $n = scalar(@data);

for(my $i = 0; $i < $n-1; $i++) {
   my $keyi = $keys[$i];
   for(my $j = $i + 1; $j < $n; $j++) {
      my $score = undef;
      my $keyj = $keys[$j];
      if($metric eq 'euclid') {
         $score = &vec_euclid($data[$i],$data[$j]);
         $score = sqrt($score);
      } elsif($metric eq 'seuclid') {
         $score = &vec_euclid($data[$i],$data[$j]);
      } elsif ($metric eq 'canberra') {
		$score = &vec_canbDist($data[$i],$data[$j]);
	  } elsif ($metric eq 'hamming') {
		$score = &vec_hammingDist($data[$i],$data[$j]);
	  } elsif ($metric eq 'rand') {
		$score = &vec_randIndex($data[$i],$data[$j]);
	  } elsif ($metric eq 'jaccard') {
		$score = &vec_jaccardSimCoeff($data[$i],$data[$j]);
	  } elsif ($metric eq 'mi') {
		$score = &mutual_information($data[$i],$data[$j]);
	  }
      print STDOUT $keyi, $delim, $keyj, $delim, $score, "\n";
   }
}

exit(0);

__DATA__
syntax: score_pairs.pl [OPTIONS]

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Set the key column to COL (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-m METRIC: Sets the score metric to METRIC (default is euclid). Allowed values are:

	euclid      - Euclidean distance
	seuclid     - Squared euclidean distance
	canberra	- Canberra distance
	hamming		- Hamming distance
	rand		- rand index
	jaccard		- Jaccard similarity coefficient
	pearson     - Centered pearson correlation
	mi     		- Mututal Informaiton


