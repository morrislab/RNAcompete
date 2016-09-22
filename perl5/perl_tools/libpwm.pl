#!/usr/bin/perl/

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



sub read_pwm{
	my $file = shift;
	my @pwm;
	open(my $in, $file) or die "couldn't open $file";
	<$in>; #header
	while(<$in>){
		chomp; chop while /\r/;
		my ($pos,$a,$c,$g,$u) = split("\t");
		my $hr = { 	'pos' =>$pos,
					'A' => $a,
					'C' => $c,
					'G' => $g,
					'U' => $u };
		push(@pwm,$hr);
	}
	close($in);
	return \@pwm;
}


sub print_pwm{
	my $pwm = shift;
	my $len = scalar @{$pwm};
	print "Pos\tA\tC\tG\tU\n";
	foreach my $i (0..($len-1)){
		print $pwm->[$i]->{'pos'};
		foreach my $b ('A','C','G','U'){
			print "\t".$pwm->[$i]->{$b};
		}
		print "\n";
	}
}


sub trim_pwm{
	my $pwm = shift;
	my @trimpwm = ();
	my $min_trim_pct = shift;
	$min_trim_pct = 0.5 if !$min_trim_pct;

	my $firstpos = -1; # first position with high info content
	my $lastpos = -1; # last position with high info content

	#print "getting first pos\n";
	foreach my $i (1..(scalar @{$pwm})){
		my $max = 0;
		foreach my $b ('A','C','G','U'){
			$max = $pwm->[$i-1]->{$b} if $pwm->[$i-1]->{$b} > $max;
			#print "".($i-1)." $max\n";
		}
		if ($max >= $min_trim_pct){
			$firstpos = $i-1;
			last;
		} 
	}
	
	#print "getting last pos\n";
	foreach my $i (reverse 1..(scalar @{$pwm})){
		my $max = 0;
		foreach my $b ('A','C','G','U'){
			$max = $pwm->[$i-1]->{$b} if $pwm->[$i-1]->{$b} > $max;
			#print "".($i-1)." $max\n";
		}
		if ($max >= $min_trim_pct){
			$lastpos = $i-1;
			last;
		} 
	}
	
	
	return undef if $firstpos < 0;
	
	foreach my $i ($firstpos..$lastpos){
		push(@trimpwm,$pwm->[$i]);
	}
	return \@trimpwm;
}

sub pad_pwm{
	my $pwm = shift;
	my $padLen = shift;
	my $position = shift;
	my @paddedpwm = ();
	
	my $pwmlen = scalar @{$pwm};
	my $firstpos = $pwm->[0]->{'pos'};
	
	if($position eq 'before'){
		my $pos = -$padLen + $firstpos;
		while($pos < $firstpos){
			push(@paddedpwm, {'pos' => $pos, 'A' => 0.25, 'C' => 0.25, 'G' => 0.25, 'U' => 0.25});
			$pos++;
		}
	}
	
	foreach my $i (1..$pwmlen){
		push(@paddedpwm,$pwm->[$i-1]);
	}
	
	if($position eq 'after'){
		my $pos = $firstpos + $pwmlen;
		while($pos < ( $firstpos + $pwmlen + $padLen)){
			push(@paddedpwm, {'pos' => $pos, 'A' => 0.25, 'C' => 0.25, 'G' => 0.25, 'U' => 0.25});
			$pos++;
		}

	}
	return \@paddedpwm;
}

sub print_pfm{
	return print_pwm(@_);
}

sub trim_pfm{
	return trim_pwm(@_);
}

sub read_pfm{
	return read_pwm(@_);
}

sub pad_pfm{
	return pad_pwm(@_);
}

1;
