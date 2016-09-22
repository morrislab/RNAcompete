#!/usr/bin/perl

my $MIN_TRIM_PCT = 0.50;

use strict;
use warnings;

while(<>)
{
	chomp;
	my @tabs = split (/\t/);
	my $id = shift @tabs;
	my $max = 0;
	foreach (@tabs){
		$max = $_ if $_ > $max;
	}
	print "$id\t",join("\t",@tabs),"\n" if ($max >= $MIN_TRIM_PCT);
}

exit(0);
