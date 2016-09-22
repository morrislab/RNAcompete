# Simple module to get an n-mer alignment
# Should really develop this into a proper class

use strict;

# align_nmers
#
# Aligns Nmers and returns an array with orientation and offset
sub align_nmers{
   my @asNmers = @_;
   
   # Make a pairwise alignment between all input sequences and select the
   # sequence with the highest overall alignment score as the seed sequence
   my $nSeedID = &get_seed_sequence_id(@asNmers);

   # Compare the seed sequence against all other sequences (including itself
   my @aaSpacingOrientation = &get_spacing_orientation($nSeedID, @asNmers);
   
   # Return the array
   return(@aaSpacingOrientation);
}



# get_seed_sequence_id
#
# Selects the seed sequence based on the highest aggregate alignment score
# The method returns the array ID of the seed element
sub get_seed_sequence_id{
   my @asNmers = @_;
   
   # First get the aggregate scores and spacings for all seed alignments
   my (@anAggregateScores, @anAggregateSpacings);
   for (my $i=0 ; $i<@asNmers ; $i++){
      my @aaScores = get_spacing_orientation($i, @asNmers);
      my ($nAggregateScore, $nAggregateSpace) = (0,0);   
      foreach my $rRow (@aaScores){
         $nAggregateScore += $rRow->[3];
         $nAggregateSpace += abs($rRow->[4]);
      }
      push @anAggregateScores, $nAggregateScore;
      push @anAggregateSpacings, $nAggregateSpace;
   }
   
   # Now get the maximum score and retain all elements that have a tied score
   my $nMaxScore=0;
   my %hMaxScores;
   for (my $i=0 ; $i<@anAggregateScores ; $i++){
      push @{$hMaxScores{$anAggregateScores[$i]}}, $i;
      $nMaxScore = $anAggregateScores[$i] if ($anAggregateScores[$i] > $nMaxScore);
   }
   
   # In case the max score was tied between more than one element, select the best
   # seed based on the one that requires the smallest number of spacing changes
   my $nSeedID   = $hMaxScores{$nMaxScore}[0];
   my $nMinSpace = $anAggregateSpacings[$hMaxScores{$nMaxScore}[0]];
   foreach my $nID (@{$hMaxScores{$nMaxScore}}){
      if ($anAggregateSpacings[$nID] < $nMinSpace){
         ($nSeedID, $nMinSpace) = ($nID, $anAggregateSpacings[$nID]);
      }
   }
   
   # Finally, return the seed ID
   return($nSeedID);
}


# get_spacing_orientation
#
# Returns an array that has spacing and orientation info for each inputted sequence
# Applying this matrix to the original sequences will give the optimal motif alignment
# Briefly, all sequences are compared to the seed sequence. For each comparison, choose
# either the sequence passed or its reverse complement, based on which one has the highest 
# alignment score with the reference sequence. Then for each comparison return the 
# array-id, original sequence, the strand (+ for original or - for reverse complement), 
# the spacing offset and the alignment score against the seed
sub get_spacing_orientation{
   my $nSeedID = shift @_;
   my @asNmers = @_;
   my @aaResult;
   
   for (my $i=0 ; $i<@asNmers ; $i++) {
      my ($nFwdScore, $nFwdSpacing) = &get_max_ungapped_alignment_score($asNmers[$nSeedID], $asNmers[$i]);

	 push @aaResult, [$asNmers[$i], '+', $nFwdSpacing, $nFwdScore];

   }
   
   return (@aaResult);
}


# get_max_ungapped_alignment_score
#
# Compares two equal-sized n-mer sequence motifs and returns the maximum alignment 
# score (number of matches) and offset
sub get_max_ungapped_alignment_score{
   my ($sSeqA, $sSeqB) = @_;
   my ($nMaxScore, $nMinOffset) = (0,0);
   
   # Convert both sequences to array format and change case
   my @aSeqA = split '', uc($sSeqA);
   my @aSeqB = split '', uc($sSeqB);
   
   # Make sure that the arrays have equal length
   die "Error: sequences must be of equal length in get_max_alignment_score\n" unless (length(@aSeqA) == length(@aSeqB));
   
   # Start with alignment of both sequences and shift the top sequence left
   for(my $i=0 ; $i<@aSeqA ; $i++){
      my @cmp = @aSeqA[$i..$#aSeqA];
      my $nMatches = 0;
      for (my $j=0 ; $j<@cmp ; $j++){ $nMatches++ if ($cmp[$j] eq $aSeqB[$j])}
      if ($nMatches > $nMaxScore){
         ($nMaxScore, $nMinOffset) = ($nMatches, $i);
      }
      last if(@cmp<=$nMaxScore);
   }
   
   # Start with alignment of both sequences and shift the bottom sequence to the left
   for(my $i=0 ; $i<@aSeqB ; $i++){
      my @cmp = @aSeqB[$i..$#aSeqB];
      my $nMatches = 0;
      for (my $j=0 ; $j<@cmp ; $j++){ $nMatches++ if ($cmp[$j] eq $aSeqA[$j])}
      if ($nMatches > $nMaxScore){
         ($nMaxScore, $nMinOffset) = ($nMatches, -$i);
      }
      last if(@cmp<=$nMaxScore);
   }
   
   return($nMaxScore, $nMinOffset);
}


# reverse_complement (string)
#
# returns the reverse-complement of a sequence (N replaced by N again)
sub reverse_complement{
	die "ERROR ERROR: revcomp called\n";
#    my $sSequence   = shift @_;
#    my $sRevComp    = '';
#    my %hComplement = ('A'=>'T', 'T'=>'A', 'G'=>'C', 'C'=>'G', 'N'=>'N', 'a'=>'t', 't'=>'a', 'g'=>'c', 'c'=>'g', 'n'=>'n');
# 
#    for (my $i=length($sSequence)-1 ; $i>=0 ; $i--){
#       my $sBase = substr($sSequence, $i, 1);
#       if (exists($hComplement{$sBase})) { $sRevComp .= $hComplement{$sBase}; }
#       else{ die "Illegal base type found in reverse_complement: $sSequence\n"}
#    }
#    return ($sRevComp);
}


return 1;
