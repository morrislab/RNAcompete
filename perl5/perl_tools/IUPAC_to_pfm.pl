#!/usr/bin/perl

use strict;
use warnings;

my %IUPAC = (
	'A' => [1,0,0,0],
	'C' => [0,1,0,0],
	'G' => [0,0,1,0],
	'U' => [0,0,0,1],
	'R' => [0.5,0,0.5,0],
	'Y' => [0,0.5,0,0.5],
	'S' => [0,0.5,0.5,0],
	'W' => [0.5,0,0,0.5],
	'K' => [0,0,0.5,0.5],
	'M' => [0.5,0.5,0,0],
	'B' => [0,0.333,0.333,0.333],
	'D' => [0.333,0,0.333,0.333],
	'H' => [0.333,0.333,0,0.333],
	'V' => [0.333,0.333,0.333,0],
	'N' => [0.25,0.25,0.25,0.25]
);


my $iupac = <STDIN>;
chomp($iupac);

my $pfm = _convert_IUPAC_to_pfm(_trim_Ns($iupac));

_print_pfm($pfm);

sub _print_pfm{
	my $pfm = shift;
	my $length = scalar @{$pfm};
	print "Pos\tA\tC\tG\tU\n";
	for(my $i=0; $i<$length; $i++){
		print "".($i+1)."\t";
		print join("\t",@{$pfm->[$i]});
		print "\n";
	}
}

sub _convert_IUPAC_to_pfm{
	my $iupac = shift;
	#print "iupac: $iupac\n";
	my $length = length($iupac);
	my $pfm = ();
	for(my $i=0; $i<$length; $i++){
		my $letter = substr($iupac,$i,1);
		# print "letter: $letter\n";
		my $pos = $IUPAC{$letter};
		#print join(":",@{$pos}),"\n";
		$pfm->[$i] = $pos;
	}
	return $pfm;
}


sub _trim_Ns{
	my $str = shift;
	$str =~ s/^N+(?!N)//;
	$str =~ s/(?<!N)N+$//;
	return $str;
}