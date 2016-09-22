#!/usr/bin/perl

use strict;
require "libfile.pl";

$| = 1;

my @flags   = (
                  [    '-d', 'scalar',     "\t", undef]
                , [    '-i', 'scalar',     'seq', undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $delim = $args{'-d'};
my $idRoot = $args{'-i'};
my $file  = $args{'--file'};

open(FILE, $file) or die "could not open file '$file'";

my $i = 0;
while(<FILE>)
{
  chop;
  if(/\S/)
  {
    my @split = split($delim);
    if( scalar(@split) > 1){	# assume first column is ID and rest is lines of fasta seq
    	my $name = shift @split;
		print ">$name\n", join("\n",@split), "\n";    
    } else { # assume all seq, use given ID base
    	print ">${idRoot}_$i\n$split[0]\n";
    }
  }
  $i++;
}

exit(0);

__DATA__

syntax: tab2fasta.pl [OPTIONS] < STAB

TAB is a tab-delimited file. If there is only one column, assign IDs, otherwise assume
that the first column is the sequence ID and the rest of the columns are sequences.

OPTIONS are:

-i ID <str>: if the file doesn't contain IDs, set the ID root to <str>.
	Default seq, so FASTA IDs will come out looking like seq_0, seq_1, etc
-d DELIM: change the delimiter from tab to DELIM

