#!/usr/bin/perl

require "libfile.pl";

use strict;
use warnings;

$| = 1;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-h', 'scalar',     0, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-i', 'scalar',     0,     1]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose   = not($args{'-q'});
my $headers   = $args{'-h'};
my $delim     = $args{'-d'};
my $indicator = $args{'-i'};
my $file      = $args{'--file'};

my $line_no = 0;
my $filep   = &openFile($file);
while(<$filep>)
{
   $line_no++;

   chomp;

   my ($key1,$key2,$stuff) = split($delim,$_,3);

   if(defined($key1) and defined($key2))
   {
      my $flip = ($line_no > $headers and ($key1 cmp $key2) > 0) ? 1 : 0;

      $stuff = (defined($stuff) and length($stuff) > 0) ? ($delim . $stuff) : '';

      if($indicator)
      {
	 $stuff = $delim . (($line_no > $headers) ? $flip : 'Indicator') . $stuff;
      }

      if($flip)
	{ print $key2, $delim, $key1, $stuff, "\n"; }
      else
	{ print $key1, $delim, $key2, $stuff, "\n"; }
   }
}


__DATA__
syntax: order_keys.pl [FILE | < FILE]

Assumes two keys are in the file on columns 1 and 2.  Makes sure that key 1, in
column one, sorts lexically first otherwise it swaps it with the second key.

-d DELIM: Give a delimiter (default is tab).

-i: Print out an indicator {0,1} that tells if the keys were flipped 0 means the
    keys were not flipped and appear in their original order while 1 indicates that
    they have been flipped.


