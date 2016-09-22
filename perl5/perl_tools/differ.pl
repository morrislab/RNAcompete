#!/usr/bin/perl

##############################################################################
##############################################################################
##
## differ.pl
##
##############################################################################
##############################################################################
##
## Written by Josh Stuart in the lab of Stuart Kim, Stanford University.
##
##  Email address: jstuart@stanford.edu
##          Phone: (650) 725-7612
##
## Postal address: Department of Developmental Biology
##                 Beckman Center Room B314
##                 279 Campus Dr.
##                 Stanford, CA 94305
##
##       Web site: http://www.smi.stanford.edu/people/stuart
##
##############################################################################
##############################################################################
##
## Written: 00/00/02
## Updated: 00/00/02
##
##############################################################################
##############################################################################

require "libfile.pl";
require "$ENV{MYPERLDIR}/lib/libset.pl";
require "$ENV{MYPERLDIR}/lib/libattrib.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [   '-m1', 'scalar',     1, undef]
                , [   '-m2', 'scalar',     1, undef]
                , [   '-s1', 'scalar',     2, undef]
                , [   '-s2', 'scalar',     2, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-h', 'scalar',     1, undef]
                , [ '-same', 'scalar', undef, undef]
                , ['--file',   'list', ['-'], undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose   = not($args{'-q'});
my $mem_col1  = $args{'-m1'};
my $mem_col2  = $args{'-m2'};
my $set_col1  = $args{'-s1'};
my $set_col2  = $args{'-s2'};
my $delim     = $args{'-d'};
my $headers   = $args{'-h'};
my $same_file = $args{'-same'};
my @files     = @{$args{'--file'}};

if(defined($same_file))
{
   open(SAME, ">$same_file") or die("Could not open same file '$same_file'");
}

$mem_col1--;
$mem_col2--;
$set_col1--;
$set_col2--;

scalar(@files) == 2 or die("Must supply two set files");

$verbose and print STDERR "Reading in set 1 from '$files[0]'...";
my $sets1     = &setsRead($files[0], $delim, $mem_col1, $set_col1);
my $num_sets1 = &setSize($sets1);
$verbose and print STDERR " done ($num_sets1 sets read).\n";

$verbose and print STDERR "Reading in set 2 from '$files[1]'...";
my $sets2     = &setsRead($files[1], $delim, $mem_col2, $set_col2);
my $num_sets2 = &setSize($sets2);
$verbose and print STDERR " done ($num_sets2 sets read).\n";

$verbose and print STDERR "Joining members of sets from set 1...";
my $join1 = &setsJoin($sets1, 1);
$verbose and print STDERR " done.\n";

$verbose and print STDERR "Joining members of sets from set 2...";
my $join2 = &setsJoin($sets2, 1);
$verbose and print STDERR " done.\n";

$verbose and print STDERR "Inverting members of sets from set 1...";
my $inv1 = &attribInvert($join1);
$verbose and print STDERR " done.\n";

$verbose and print STDERR "Inverting members of sets from set 2...";
my $inv2 = &attribInvert($join2);
$verbose and print STDERR " done.\n";

$verbose and print STDERR "Finding which sets are different.\n";

print STDOUT ">1\n";
foreach my $member_string (keys(%{$inv1}))
{
   my $set_key = $$inv1{$member_string};
   if(not(exists($$inv2{$member_string})))
   {
      print STDOUT "$set_key\n";
   }

   elsif(defined($same_file))
   {
      my $set_key2 = $$inv2{$member_string};
      print SAME "$set_key\t$set_key2\n";
   }
}

print STDOUT ">2\n";
foreach my $member_string (keys(%{$inv2}))
{
   my $set_key = $$inv2{$member_string};
   if(not(exists($$inv1{$member_string})))
   {
      print STDOUT "$set_key\n";
   }
}

if(defined($same_file))
{
   close(SAME);
}

exit(0);


__DATA__
syntax: differ.pl [OPTIONS] FILE1 FILE2

Print the set keys that have different members.

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Compare the values in key_column COL to the threshold in the file (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 1).

