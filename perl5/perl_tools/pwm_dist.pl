#!/usr/bin/perl


use strict;
require "libfile.pl";

$| = 1;

my @flags   = (
                  [    '-s', 'scalar',     0, 1]
                 ,[    '-c', 'scalar',     0, 1]
                 ,[    '-g', 'scalar',     0, 1]
                 ,['-p1', 'scalar',   undef, undef]
                 ,['-p2', 'scalar',   undef, undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $pwmFile1  = $args{'-p1'};
my $pwmFile2  = $args{'-p2'};

unless ($pwmFile1 && $pwmFile2){
	print <DATA>;
	die "must specify both pwms" ;
}

my $pwm1 = _read_pwm($pwmFile1);
my $pwm2 = _read_pwm($pwmFile2);

my $offset = _calculate_best_offset($pwm1,$pwm2);

my $dist = _ed($pwm1,$pwm2,$offset);

print $dist,"\n";

sub _read_pwm{
	my $file = shift;
	my @pwm;
	open(my $in, $file) or die "couldn't open $file";
	<$in>; #header
	while(<$in>){
		chomp; chop while /\r/;
		my ($pos,$a,$c,$g,$u) = split("\t");
		my $hr = { 	'A' => $a,
					'C' => $c,
					'G' => $g,
					'U' => $u };
		push(@pwm,$hr);
	}
	close($in);
	return \@pwm;
}

sub _calculate_best_offset{
	my ($pwm1,$pwm2) = @_;
	my $minoffset = -(scalar @{$pwm1} - 1);
	my $maxoffset = scalar @{$pwm2} - 1;
	print "minoffset: $minoffset\n";
	print "maxoffset: $maxoffset\n";
	my $bestoffset = $minoffset;
	my $curoffset = $minoffset;
	print "curoffset: $curoffset\n";
	my $bestdist = _ed($pwm1,$pwm2,$curoffset);
	print "dist: $bestdist\n";
	print "bestdist: $bestdist\n";
	print "bestoffset: $bestoffset\n";
	$curoffset++;
	while ($curoffset <= $maxoffset){
		print "curoffset: $curoffset\n";
		my $curdist = _ed($pwm1,$pwm2,$curoffset);
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
	return $bestoffset;
}

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
#				$val += $shorter->[$i]->{$b};
			} else {
				$overlap++;
				$val += $longer->[$i+($offset)]->{$b} - $shorter->[$i]->{$b};
			}
		}
		$ed += sqrt($val*$val);
	}
	
	
	print "overlap: $overlap\n";
	$ed = $ed / $overlap;
	
	return $ed;
}


__DATA__

pwm_dist.pl -p1 pwm1.txt -p2 pwm2.txt

Calculates the best offset between 2 pwms (or pfms...) and spits out the
euclidean distance between the two pwms.

Assumes that PWM is of this form (tab-delimited):

Pos	A	C	G	U
1	0	0.14	0.11	0.24
2	0	0.33	0.12	0.17
3	0.39	0.74	0.9	0
4	0	2.65	0.78	3.1
5	0	5.22	5.75	4.11
6	6.14	2.36	3.41	0
7	1.25	0.45	0.46	0
8	0	0.5	0.18	0.63


note: RNA-based, ie does not try reverse complementing the pwms


