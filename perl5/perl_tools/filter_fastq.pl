#!/usr/bin/perl

use strict;

require "libfile.pl";

$| = 1;

my @flags   = (
                  [    '-l', 'scalar',     40, undef]
                , [    '-q', 'scalar',     30, undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $len = $args{'-l'};
my $minQual = $args{'-q'};
my $file  = $args{'--file'};

open(FILE, $file) or die "could not open file '$file'";

while(<FILE>){
	my $seq = <FILE>;
	chomp($seq);
	<FILE>;
	my $qual = <FILE>;
	chomp($qual);
	#print $seq,"\n";
	#print $qual,"\n";
	my @quals = split(//,$qual);
	my @phreds = map {ord($_) - 33} @quals;
	#print join(':',@phreds),"\n";
	@phreds = @phreds[0..($len-1)];
	#print  _mean(\@phreds),"\n";
	next if _mean(\@phreds) < $minQual;
	$seq = substr($seq,0,$len);
	print $seq,"\n";
}

close(FILE);

sub _mean{
	my $a = shift;
	my $sum = 0;
	$sum += $_ for @$a;
	return $sum/scalar(@$a);
}




__DATA__

filter_fastq.pl [FILE | < FILE]

Extracts sequences from a fastq file, trims them to the length 
specified, and passes them to output if the average quality score
is more than the -q cutoff.

   -l <num>:  length of sequence to trim (default: 40)
   -q <num>:  Minimum average quality score (up to <len>) (default: 30)

