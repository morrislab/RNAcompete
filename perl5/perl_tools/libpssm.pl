#!/usr/bin/perl

##------------------------------------------------------------------------
## \@array of hashes readPSSM(FILEHANDLE)
##------------------------------------------------------------------------
sub readMatrix {
   my ($FILEHANDLE) = @_;
   my $rPSSM;
   my $i = 0;
   while(my $line = <$FILEHANDLE>) {
      chomp($line);
      my @scores = split("\t",$line);
      die "ERROR in readMatrix: line $i didn't have 4 entries\n$line" if scalar(@scores) != 4;
	  my @bases = ('A','C','G','U');
	  my $j = 0;
      foreach my $b (@bases){
      	$rPSSM->[$i]->{$b} = $scores[$j];
      	$j++;
      }
      $i++;
   }
   return $rPSSM;
}

1;