#!/usr/bin/perl

use strict;
use warnings;

require 'libpwm.pl';

my ($pfmfile1,$pfmfile2) = @ARGV;

die "usage: calc_pfm_align_offset.pl <pfmfile1> <pfmfile2>" unless $pfmfile1 && $pfmfile2;

my $pfm1 = read_pwm($pfmfile1);
my $pfm2 = read_pwm($pfmfile2);

print "pfm 1:\n";
print_pwm($pfm1);
print "pfm 2:\n";
print_pwm($pfm2);

my $pfm1_trimmed = trim_pwm($pfm1);
my $pfm2_trimmed = trim_pwm($pfm2);
print "pfm 1 trimmed:\n";
print_pwm($pfm1_trimmed);
print "pfm 2 trimmed:\n";
print_pwm($pfm2_trimmed);


my $len1 = scalar @{$pfm1_trimmed};
my $len2 = scalar @{$pfm2_trimmed};
print "len1: $len1\n";
print "len2: $len2\n";


my $maxoffset = abs($len1 - $len2);
my $minoffset = -$maxoffset;
print "minoffset: $minoffset\n";
print "maxoffset: $maxoffset\n";

my $bestoffset = $minoffset;
my $curoffset = $minoffset;
print "curoffset: $curoffset\n";
my $bestdist = _ed($pfm1_trimmed,$pfm2_trimmed,$curoffset);
print "dist: $bestdist\n";
print "bestdist: $bestdist\n";
print "bestoffset: $bestoffset\n";
$curoffset++;
while ($curoffset <= $maxoffset){
	print "curoffset: $curoffset\n";
	my $curdist = _ed($pfm1_trimmed,$pfm2_trimmed,$curoffset);
	print "dist: $curdist\n";
	if ($curdist < $bestdist){
		$bestoffset = $curoffset;
		$bestdist = $curdist;
	}
	print "bestdist: $bestdist\n";
	print "bestoffset: $bestoffset\n";
	$curoffset++;
	print "\n";
}

print "offset on trimmed pfms: $bestoffset\n";
#print $pfm1_trimmed->[0]->{'pos'},"\n";
#print $pfm2_trimmed->[0]->{'pos'},"\n";
$bestoffset += ($pfm2_trimmed->[0]->{'pos'} - $pfm1_trimmed->[0]->{'pos'});
print "best offset: $bestoffset\n";

my $fulldist = _ed($pfm1,$pfm2,$bestoffset);

print "distance between full pfms: $fulldist\n";

sub _ed{
	my ($pwm1,$pwm2,$offset) = @_;
	my $ed = 0;
	my $len1 = scalar @{$pwm1};
	my $len2 = scalar @{$pwm2};
	
	my $lenshorter = $len1;
	my $lenlonger = $len2;
	my $shorter = $pwm1;
	my $longer = $pwm2;
	if ($len2 < $len1){
		$lenshorter = $len2;
		$lenlonger = $len1;
		$shorter = $pwm2;
		$longer = $pwm1;
		$offset = -$offset;
	}

	my $overlap = 0;
	
	foreach my $i (0..($lenshorter-1)){
		my $val = 0;
		foreach my $b ('A','C','G','U'){
			if($i+$offset < 0 || $i+$offset >= $lenlonger){
				#$val += $shorter->[$i]->{$b};
			} else {
				$overlap++;
				$val += $longer->[$i+($offset)]->{$b} - $shorter->[$i]->{$b};
			}
		}
		$ed += sqrt($val*$val);
	}
	
	
	#print "overlap: $overlap\n";
	#$ed = $ed / $overlap;
	
	return $ed;
}

sub _ed_simple{
	my ($pwm1,$pwm2) = @_;
	my $ed = 0;
	my $len1 = scalar @{$pwm1};
	my $len2 = scalar @{$pwm2};
	
	die "err: _ed_simple requires that both pwms be padded to the same length" if $len1 != $len2;
		
	foreach my $i (0..($len1-1)){
		my $val = 0;
		foreach my $b ('A','C','G','U'){
			$val += $pwm1->[$i]->{$b} - $pwm2->[$i]->{$b};
		}
		$ed += sqrt($val*$val);
	}
		
	return $ed;
}


