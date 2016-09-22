#!/usr/local/bin/perl

##############################################################################
##############################################################################
##
## uniq.pl
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
##############################################################################
##############################################################################

require "libfile.pl";
require "$ENV{MYPERLDIR}/lib/liblist.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;


my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-f', 'scalar', undef, undef]
                , [    '-k', 'scalar', undef, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [ '-keep', 'scalar',     0,     1]
                , [   '-ds', 'scalar',    '', undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'})) {
   print STDOUT <DATA>;
   exit(0);
}

my $verbose      = not($args{'-q'});
my $fields       = $args{'-f'};
my $fields_      = $args{'-k'};
my $delim        = &interpMetaChars($args{'-d'});
my $keep         = $args{'-keep'};
my $delim_suffix = &interpMetaChars($args{'-ds'});
my $file         = $args{'--file'};
my @extra        = @{$args{'--extra'}};

$fields = defined($fields) ? $fields : $fields_;

my %count;
my $passify = 1000000;
my $filep;
my @data;
my $i = 0;
my @cols = (0);
open($filep, $file) or die("Could not open file '$file' for reading");
while(<$filep>) {
   my @x = split($delim, $_);
   chomp($x[$#x]);
   my $key = $x[0];
   if(defined($fields)) {
      @cols = &parseRanges($fields, scalar(@x), -1);
      $key = &listSubJoin($delim, \@x, \@cols);
   }
   if(not(exists($count{$key}))) {
      $count{$key} = 0;
      if(not($keep)) {
         print;
      }
   }

   if($keep) {
      $count{$key}++;
      push(@data, [$key,\@x]);
   }

   $i++;
   if($i % $passify == 0) {
      $verbose and print STDERR "$i lines read.\n";
   }
}
close($filep);

if($keep) {

   my %renamed;

   # Force keys that are not uniue to be unique.
   foreach my $key (keys(%count)) {
      my $num_occurrences = $count{$key};
      if($num_occurrences > 1) {
         &renameKeys($key, $num_occurrences, \%count, \%renamed);
      }
   }
   
   $verbose and print STDERR "Ensuring uniqueness of keys by appending numeric suffixes to any non-unique keys.\n";

   my $last_column = $cols[$#cols];

   # Print out the data with the new key names.
   for($i = 0; $i < @data; $i++) {
      my $key  = $data[$i][0];
      my $x    = $data[$i][1];
      if(exists($renamed{$key})) {
         my $suffix = splice(@{$renamed{$key}},0,1);
         $$x[$last_column] .= $delim_suffix . $suffix;
      }
      print join($delim, @{$x}), "\n";
   }
}

exit(0);

sub renameKeys {
   my ($key, $count, $orig_hash, $old2new_hash) = @_;
   my $num_renamed = 0;
   $$old2new_hash{$key} = [];
   for(my $i = 1; $num_renamed <= $count; $i++) {
      my $suffix = "$i";
      my $new = $key . $suffix;
      if(not(exists($$orig_hash{$new}))) {
         push(@{$$old2new_hash{$key}}, $suffix);
         $num_renamed++;
      }
   }
}

__DATA__
syntax: uniq.pl [OPTIONS]

Assumes the file is already ordered. Keeps only the first occurrence of
each key.

OPTIONS are:

-q: Quiet mode (default is verbose)

-f COL(S): Extract the key from the given columns (default is the first column). Column ranges can
           be given as in cut.pl.

-d DELIM: Set the field delimiter to DELIM (default is tab).

-keep: This option tells the script to retain all of the entries it finds
       and change the keys so that they are guaranteed to be unique.
       If it finds a key that has been repeated, it appends _1, _2, ... to
       the end of each of the redundant keys so that each is mutually distinct.
       For example, if the keys in a file are:

                       a, b, a, c, b, a, d

       the script will produce the same entries with the keys:

                       a_1, b_1, a_2, c, b_2, a_3, d

-ds DELIM: Set the delimiter for the appended suffixes to previously non-unique
           keys (default is the blank). This option is only
           relevant when used with the -keep option.


