#!/usr/bin/perl

use warnings;
use strict;

while (<>) {
	chomp;
	my @parts = split /\t/;
	print "@","$parts[0]:$parts[2]:$parts[3]:$parts[4]:$parts[5]#$parts[6]/$parts[7]\n";
	$parts[8] =~ tr/./N/;
	print "$parts[8]\n";
	print "+\n";
	my @quals = split(//,$parts[9]);
#	my @phreds = map {ord($_) - 65} @quals;
	my @phreds = map {chr(ord($_))} @quals;
	print join('',@phreds),"\n";
}
