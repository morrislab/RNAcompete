#!/usr/bin/perl


use strict;
require "libfile.pl";

$| = 1;

my @flags   = (
                  [    '-s', 'scalar',     0, 1]
                 ,[    '-c', 'scalar',     0, 1]
                 ,[    '-g', 'scalar',     0, 1]
                 ,['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $file  = $args{'--file'};
my $bSmallSampleCor = $args{'-s'};
my $bGapAdjust = !$args{'-g'};
my $bGetCounts = $args{'-c'};

die "error: can't use small sample correction with counts!" if ($bSmallSampleCor && $bGetCounts);

open(my $fh, $file) or die "could not open file '$file'";
my $raKmers = readFile($fh);

my $rPFM = get_pfm_from_aligned_kmers($raKmers,$bSmallSampleCor);

my $output = '';
foreach my $position (@{$rPFM}){
	foreach my $b ('A','C','G','U'){
		$output .= $position->{$b} . "\t";
	}
	chop $output;
	$output .= "\n";
}
print $output;

# ===============
# SUBROUTINES

sub get_pfm_from_aligned_kmers{
	my ($raKmers,$bSmallSampleCor) = @_;
	#make frequency matrix
	my $nWidth = length($raKmers->[0]); #assume alignments are all same length
	my $rPFM;
	my @anTotals = (0) x $nWidth;
	# count occurrence of each base at each position
	for(my $i=0; $i<$nWidth; $i++){ #position in width
		foreach my $b ('A','C','G','U'){
			$rPFM->[$i]->{$b} = 0;
			foreach my $sKmer (@{$raKmers}){
				if (substr( $sKmer, $i , 1 ) eq $b){
					$rPFM->[$i]->{$b}++;
#					print "".$rPFM->[$i]->{$b}."\n";
					$anTotals[$i]++;
				}elsif($bGapAdjust && ( substr( $sKmer, $i , 1 ) eq '-') ){
					$rPFM->[$i]->{$b}+=.25;
					$anTotals[$i]+=.25;
				}
			}
		}
	}
	
	# convert to probabilities
	
	for(my $i=0; $i<$nWidth; $i++){ #position in width
		foreach my $b ('A','C','G','U'){
			if($bSmallSampleCor){
				$rPFM->[$i]->{$b} = ( $rPFM->[$i]->{$b} + sqrt($anTotals[$i])*0.25 ) / ($anTotals[$i] + sqrt($anTotals[$i]));
			} elsif (!$bGetCounts) {
				$rPFM->[$i]->{$b} = $rPFM->[$i]->{$b} / $anTotals[$i];
			}
		}
	}
	
	return $rPFM;
	#print "PFM!\n";
	#pretty_print_pssm($rPFM);

}


__DATA__

pfm_from_aligned.pl [FILE | < FILE]

Reads in a file (or piped input) containing a list of aligned k-mers and
spits out a PFM.

Note 1: gaps ('-') characters give a weight of 0.25 to all bases. This is
primarily so that logos made from this PFM don't have high-stringency bases
on the edges. TODO: make a flag to adjust this behaviour.

Note 2: RNA-based alphabet.

   -s:  apply small sample correction TODO: show math here
   		Note: incompatible with the -c option
   -c:  use frequency counts instead of fractions (ie dont divide by the number of sites)
   -g:	don't set '-' characters to 0.25 for all bases (allows for trimming later)

