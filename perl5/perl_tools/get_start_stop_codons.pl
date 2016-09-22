#!/usr/bin/perl

use strict;
use warnings;

my $inStr = shift @ARGV;

die "usage: get_start_stop_codons.pl <DNA or RNA sequence>\n" unless $inStr;

$inStr =~ s/U/T/;


my $start = "ATG";

my $stopAmber = "TAG";
my $stopOchre = "TAA";
my $stopOpal = "TGA";

my $startPos = index($inStr,$start);

while ($inStr =~ /($stopAmber|$stopOchre|$stopOpal)/g) {
	my $stopPos = $-[0];
	next if $stopPos < $startPos;
	print "".(($stopPos - $startPos) % 3 )."\n";
	next if (($stopPos - $startPos) % 3 ) != 0;
	print "$startPos\t$stopPos\n";
	exit;
}
