package RNACpwmutil;

require Exporter;

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(scan_seq_with_pwm get_pwm_from_aligned_kmers print_pssm_for_REDUCE get_pfm_from_aligned_kmers pretty_print_pssm get_count_matrix_from_aligned_kmers );


sub scan_seq_with_pwm{
	my ($rPWM,$sSeq) = @_;
	
	my $nWidth = scalar @{$rPWM};
	#print "width=$nWidth\n";
	
	# split sequence into characters
	my @anSeqChars = unpack("C*",$sSeq);
	#print "seq chars: ",join(',',@anSeqChars),"\n";
	
	my $nSeqScore = 0;
	
	# for each k-mer
	for(my $i = 0; $i <= length($sSeq) - $nWidth; $i++){
		#print "kmer=".substr($sSeq,$i,$nWidth)."\n";
		my $nKmerScore = 0;
		# for each base of k-mer
		for(my $j = 0; $j < $nWidth; $j++){
			# get score from pwm
			# add to k-mer score
			$nKmerScore += $rPWM->[$j]->{_to_base($anSeqChars[$i+$j])};
		}
		#print "kmerscore = $nKmerScore\n";
		#print "expkmerscore = ".exp($nKmerScore)."\n";
		# expsum kmer scores
		$nSeqScore += exp($nKmerScore) if $nKmerScore > 0;
		#print "seqscore = $nSeqScore\n";
	}
	
	return $nSeqScore;	
}

sub _to_base{
	my $char = shift;
	my %hash = (
		67 => 'C',
		71 => 'G',
		85 => 'U',
		65 => 'A'
	);
	if($hash{$char}){
		return $hash{$char}; 
	} else {
		die "bad character: $char\n";
	}	
}

# sub load_pwm_from_file{
# 	my $inFile = shift;
# 	open(my $in, $inFile) or die "couldn't open $inFile\n";
# 	while(<$in>){
# 		next if /^#/;
# 	}
# }

#pwm: position --> base --> score

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
				}elsif(substr( $sKmer, $i , 1 ) eq '-'){
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
			} else {
				$rPFM->[$i]->{$b} = $rPFM->[$i]->{$b} / $anTotals[$i];
			}
		}
	}
	
	return $rPFM;
	#print "PFM!\n";
	#pretty_print_pssm($rPFM);

}

sub get_count_matrix_from_aligned_kmers{
	my ($raKmers) = @_;
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
				}
			}
		}
	}
	
	# convert to probabilities
	
	
	return $rPFM;
	#print "PFM!\n";
	#pretty_print_pssm($rPFM);

}



sub get_pwm_from_aligned_kmers{
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
				}
			}
		}
	}
		
	#convert to PWM (log2 base, background probabilities all 0.25, ss correction if flag)
	my $rPWM;

	for(my $i=0; $i<$nWidth; $i++){ #position in width
		foreach my $b ('A','C','G','U'){
			if($bSmallSampleCor){
				$rPWM->[$i]->{$b} = ( $rPFM->[$i]->{$b} + sqrt($anTotals[$i])*0.25 ) / ($anTotals[$i] + sqrt($anTotals[$i]))  /  0.25;
			} else {
				$rPWM->[$i]->{$b} = $rPFM->[$i]->{$b} / ($anTotals[$i]  /  0.25);
			}
			
			if($rPWM->[$i]->{$b} > 0){
				$rPWM->[$i]->{$b} = log2($rPWM->[$i]->{$b});
			} 
		}
	}

	
	#print "PWM!\n";
	#pretty_print_pssm($rPWM);
	
	return $rPWM
}

sub log2 {
	my $n = shift;
	return log($n)/log(2);
}

sub pretty_print_pssm {
	my $rPSSM = shift;
	my $nWidth = scalar @{$rPSSM};
	my $output = '';
	foreach my $b ('A','C','G','U'){
		$output .= "$b:";
		for (my $i=0; $i<$nWidth; $i++){
			$output .= "\t".sprintf("%.3f",$rPSSM->[$i]->{$b});
		}
		$output .= "\n";
	}
	return $output;
}


sub print_pssm_for_REDUCE {
	my $rPSSM = shift;
	my $nWidth = scalar @{$rPSSM};
	my $output = '';
	$output .=  "# The four columns must be in the order of A, C, G, and U\n";
	$output .=  "# \tA\tC\tG\tU\n";
	$output .=  "# --------------------------------------------------------\n";
	for (my $i=0; $i<$nWidth; $i++){
		foreach my $b ('A','C','G','U'){
			$output .=  "\t".sprintf("%.3f",$rPSSM->[$i]->{$b});
		}
		$output .= "\n";
	}
	return $output;
}



1;