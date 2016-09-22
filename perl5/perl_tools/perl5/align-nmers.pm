#!/usr/bin/perl

use strict;
require 'orient-nmers.pm';

###########
## START ##
###########

sub align_and_print{
	my $rasNmers = shift;

	# Read in the N-mer sequences (and check if they are of equal length)
	my @asNmers = @{$rasNmers};

	# Do the alignment
	my @aaSpacingOrientation = &align_nmers(@asNmers);

	#foreach my $rR (@aaSpacingOrientation){ print join(' ', @$rR), "\n"}
	#print "\n";

	# Finally, use the array above to output an alignment against the reference sequence
	my $sReturn = &print_alignment(@aaSpacingOrientation);
	return $sReturn;
}



#################
## SUBROUTINES ##
#################

# print_alignment
#
# pretty-print the alignment
sub print_alignment{
   my @aaAlignArray = @_;
   
   # First we need to find the minimum and maximum spacing change
   my ($nMinSpace, $nMaxSpace) = ($aaAlignArray[0][2], $aaAlignArray[0][2]);
   foreach my $rRow (@aaAlignArray){
      $nMinSpace = $rRow->[2] if ($rRow->[2] < $nMinSpace);
      $nMaxSpace = $rRow->[2] if ($rRow->[2] > $nMaxSpace);
   }
   
   my @asReturn = ();
   
   # Now print the alignment
   foreach my $rRow (@aaAlignArray){
      my $nPadLeft  = $rRow->[2] - $nMinSpace;
      my $nPadRight = $nMaxSpace - $rRow->[2];
      my $sSeq = $rRow->[0];
      push(@asReturn,join('', ('-' x $nPadLeft), $sSeq, ('-' x $nPadRight)));
   }
   
   return \@asReturn;
   
}


# read_nmers
#
# Read the input file with N-mers and check that all are equal length
sub read_nmers{
   my $sInput = shift @_;
   my @asNmers;
   
   # Rad input
   open INPUT, $sInput or die "Can't open input file '$sInput': $!\n";
   while(<INPUT>){
      next if /^\s*$/;
      s/[\n\r]//g;
      my (@asSequences) = split /\s+/;
      push @asNmers, @asSequences;
   }
   close INPUT;
   
   # Make sure all N-mers are same size
   my $nNmerLength = length($asNmers[0]);
   foreach my $sNmer (@asNmers){
      die "Error: all input sequences must be of the same length\n" unless ($nNmerLength == length($sNmer));
   }
   
   return @asNmers;
}

return 1;