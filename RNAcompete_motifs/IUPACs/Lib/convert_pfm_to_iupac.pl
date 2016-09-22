#!/usr/bin/perl

use strict;
use warnings;

my $distType = shift @ARGV;
die "specify dist: ed or kl" unless $distType;

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



#my $testfile = $ARGV[0];
#my $testpfm = _read_pwm($testfile);
my $testpfm = _read_pwm_from_stdin();
my $iupacstr = _convert_pfm($testpfm);
my $trimmed = _trim_Ns($iupacstr);
print "$trimmed\n";


sub _convert_pfm{
	my $pfm = shift;
	my $length = scalar @{ $pfm };
	my $iupacStr = '';
	for(my $i=0; $i<$length; $i++){
		my $pfmPos = $pfm->[$i];
		my $letter = _pos_to_letter($pfmPos);
		$iupacStr .= $letter;
	}
	return $iupacStr;
}

sub _pos_to_letter{
	my $pfmPos = shift;
	my $bestDist = 3; #max should be 2
	my $bestLetter = '';
	foreach my $letter (keys %IUPAC){
		my $dist;
		if($distType eq 'ed'){
			$dist = _ed($pfmPos,$IUPAC{$letter});
		} elsif($distType eq 'kl'){
			$dist = _kl($pfmPos,$IUPAC{$letter});
		} else {
			die "unknown dist type: $distType\n";
		}
		if ($dist < $bestDist){
			$bestLetter = $letter;
			$bestDist = $dist;
		}
	}
	return $bestLetter;
}

sub _read_pwm_from_stdin{
	my $header = <>;
	die "couldn't understand format" unless $header =~ /[Pp].+\tA\tC\tG\t[TU]/;
	my @pfm = ();
	while(<>){
		chomp; chop while /\r/;
		my ($pos,$a,$c,$g,$u) = split("\t");
		push(@pfm,[$a,$c,$g,$u]);
	}
	return \@pfm;
}


sub _read_pwm{
	my $file = shift;
	open(my $fh, $file) or die "couldn't open $file";
	my $header = <$fh>;
	die "couldn't understand format" unless $header =~ /[Pp].+\tA\tC\tG\t[TU]/;
	my @pfm = ();
	while(<$fh>){
		chomp; chop while /\r/;
		my ($pos,$a,$c,$g,$u) = split("\t");
		push(@pfm,[$a,$c,$g,$u]);
	}
	return \@pfm;
}

sub _kl{
	my $raFirst = shift;
	my $raSecond = shift;
	my $length = scalar @{ $raFirst };
	die "error in ed: arrays must be same length" unless $length == scalar @{ $raSecond };
	my $epp = 0.000000001;
	my $kl = 0;
	for(my $i=0; $i<$length; $i++){
		$kl += $raSecond->[$i] * (log($raSecond->[$i]+$epp)-log($raFirst->[$i]+$epp))
	}
	return $kl;
}

sub _ed{
	my $raFirst = shift;
	my $raSecond = shift;
	my $length = scalar @{ $raFirst };
	die "error in ed: arrays must be same length" unless $length == scalar @{ $raSecond };
	my $sum = 0;
	for(my $i=0; $i<$length; $i++){
		$sum += ($raFirst->[$i] - $raSecond->[$i])*($raFirst->[$i] - $raSecond->[$i]);
	}
	return sqrt($sum);
}

sub _trim_Ns{
	my $str = shift;
	$str =~ s/^N+(?!N)//;
	$str =~ s/(?<!N)N+$//;
	return $str;
}