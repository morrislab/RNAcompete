#!/usr/local/bin/perl

##############################################################################
##############################################################################
##
## col_ops.pl
##
##############################################################################
##############################################################################
##
## Written by Josh Stuart.
##
##  Email address: jstuart@soe.ucsc.edu
##          Phone: (831) 459-1344
##
## Postal address: 1156 High Street, 308 Physical Sciences
##                 Mail Stop: SOE2
##                 Santa Cruz, CA 95064
##
##       Web site: http://www.soe.ucsc.edu/~jstuart/
##
## Column operations.
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
                , [    '-k', 'scalar',     1, undef]
                , [    '-a', 'scalar',     2, undef]
                , [    '-b', 'scalar',     3, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [   '-op', 'scalar', 'a-b', undef]
                , [   '-ag', 'scalar','mean', undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'})) {
   print STDOUT <DATA>;
   exit(0);
}

my $verbose   = not($args{'-q'});
my $headers   = $args{'-h'};
my $key_col   = int($args{'-k'}) - 1;
my $a_fields  = $args{'-a'};
my $b_fields  = $args{'-b'};
my $op        = $args{'-op'};
my $agg_mtd   = $args{'-ag'};
my $delim     = &interpMetaChars($args{'-d'});
my $file      = $args{'--file'};
my @extra     = @{$args{'--extra'}};

my $filep;
open($filep, $file) or die("Could not open file '$file' for reading");
my $prev_num_cols = 0;
my @a_cols;
my @b_cols;
my $line_no = 0;
while(<$filep>) {
   $line_no++;
   
   my @x        = split($delim, $_);
   my $num_cols = scalar(@x);
   chomp($x[$#x]);
   if(defined($a_fields) and $num_cols != $prev_num_cols) {
      @a_cols = &parseRanges($a_fields, $num_cols, -1);
   }
   if(defined($b_fields) and $num_cols != $prev_num_cols) {
      @b_cols = &parseRanges($b_fields, $num_cols, -1);
   }
   my @a;
   my @b;
   foreach my $i (@a_cols) {
     if($i <= $#x) {
        push(@a,$x[$i]);
     }
   }
   foreach my $i (@b_cols) {
     if($i <= $#x) {
        push(@b,$x[$i]);
     }
   }


   if($line_no > $headers) {
      my $b_agg = &aggregate(\@b,$agg_mtd);
      for(my $i = 0; $i < @a; $i++) {
         $a[$i] = &operation($a[$i],$b_agg,$op);
      }
   }

   my @printable = defined($key_col) ? ($x[$key_col],@a) : @a;

   print STDOUT join($delim, @printable), "\n";

   $prev_num_cols = $num_cols;
}
close($filep);



exit(0);

sub operation {
   my ($a, $b, $op) = @_;
   my $result = undef;
   if(not(&good($a))) {
      $result = '';
   }
   elsif(not(&good($b))) {
      $result = $a;
   }
   else {
      if($op eq 'a-b') {
         $result = $a - $b;
      }
      elsif($op eq 'b-a') {
         $result = $b - $a;
      }
      elsif($op eq 'a+b' or $op eq 'b+a') {
         $result = $a + $b;
     } elsif ($op eq 'a*b' or $op eq 'b*a') {
	 $result = $a * $b;
     } elsif ($op eq 'a/b') {
	 if ($b == 0) {
	     $result = 'UNDEFINED';
	 } else {
	     $result = $a / $b;
	 }
     } elsif ($op eq 'b/a') {
	 if ($a == 0) {
	     $result = 'UNDEFINED';
	 } else {
	     $result = $b / $a;
	 }
     } else {
	 die "ERROR in col_ops.pl: the OP argument was an unrecognized value. It should be something like -op a*b or -op a/b or -op a-b, for example.\n";
     }
   }
   return $result;
}

sub aggregate {
   my ($vector, $method) = @_;
   my $result = undef;
   if(defined($vector) and scalar(@{$vector}) > 0) {
      if(scalar(@{$vector}) == 1) {
         $result = $$vector[0];
      }
      else {
         if($method eq 'mean') {
            $result = &vec_mean($vector);
         }
      }
   }
   return $result;
}

sub good {
   my ($x) = @_;
   return ((defined($x) and ($x =~ /\d/)) ? 1 : 0);
}

__DATA__
syntax: col_ops.pl [OPTIONS]

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Set the key column to COL (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h NUMBER: Set the number of header lines (default: no headers)

-a COL: Which column has the "a" value

-b COL: Which column has the "b" value

-op: specifies whether we add, subtract, or what. Defaults to subtraction, for some reason.
  Options:    a-b
              b-a
              a+b or b+a
              a*b or b*a

-agg: something about aggregation??

--file: ???

Sample usage:

    col_ops.pl -h 1 -k 1 -b 2 -a 3-5    SOME_FILE
