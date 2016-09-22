#!/usr/bin/perl

# Collection of functions to obtain lists of nmers used for score calculations

package RNACgetNmers;

use strict;
use warnings;
use Carp qw( croak );
require Exporter;

our @ISA    = qw(Exporter);
our @EXPORT = qw(initialize_nmer_list_from_alphabet initialize_nmer_list_from_file initialize_nmer_list_from_probes);


# initialize_nmer_list_from_alphabet
#
# Generates an alphabetic list of N-mers, with optional dropping of 
# reverse-complement motifs
sub initialize_nmer_list_from_alphabet {
   my ($nMotifSize) = @_;
   my %hReturn;
   
   my @DNA = qw/A C G U/;
   my $seq = _gen_permutate($nMotifSize, $nMotifSize, @DNA);
   while ( my $strand = $seq->() ) {
	 $hReturn{$strand} = ();
   }
   return \%hReturn;
}


# initialize_nmer_list_from_file
#
# Initializes a lookup hash with all nmers
sub initialize_nmer_list_from_file{
   my ($sFile) = @_;
   my $nMotifSize = -1;
   my %hReturn;
   
   open(LIST, $sFile) or die "Error: Cannot open '$sFile' for reading: $!\n";
   while (<LIST>){
      next if (/^\s*$/);
      s/[\n\r]+$//;
      if ( exists $hReturn{$_} ){
         die "Error: [func]initialize_nmer_list_from_file: Duplicate n-mers in reference list: $_\n";
      }
      else{
         $hReturn{$_} = '';
         if ($nMotifSize <0){
            $nMotifSize = length($_);
         }
         else{
            die "Error: motif size changes on line $. in file '$sFile'\n" unless (length($_) == $nMotifSize);
         }
      }
   }
   close LIST;
   return(\%hReturn, $nMotifSize);
}


# initialize_nmer_list_from_probes
#
# Initializes a lookup hash with all nmers, from the actual RNAcompete array probe sequences
sub initialize_nmer_list_from_probes{
   my ($dbh, $nHybID, $nMotifSize, $flKeepReverseComplement) = @_;
   my %hReturn;
  
   # Query the db
   my $sql = join(" ", "SELECT L.id_probe,L.probeset,L.rna_sequence",
                       "FROM tLayout_schemes L ",
                       "LEFT JOIN tHybridizations H on H.id_layout=L.id_layout",
                       "WHERE H.id_hybridization=$nHybID AND L.control='FALSE'");
   my $oQuery = $dbh->prepare($sql);
   my $nCount = $oQuery->execute();
   die "Error: could not find raw data associated with hybridization $nHybID\n" if ($nCount eq '0E0');
   
   # Process the probe sequence data
   while(my ($id, $probeset, $seq) = $oQuery->fetchrow_array() ){
      my $seqlen = length($seq);
      
      # For each probe sequence, go through each Nmer,
      # record in the hash the probe ID for this Nmer
      for(my $offset=0; $offset<$seqlen-$nMotifSize+1; $offset++){
         my $nmer = substr($seq, $offset, $nMotifSize);
         if ($nmer !~ /N/){
            if ($flKeepReverseComplement){
               $hReturn{$nmer} = '' unless (exists($hReturn{$nmer}));
            }
            else{
               my $rev = _rev_comp($nmer);
               $hReturn{$nmer} = '' unless (exists($hReturn{$nmer}) or (exists$hReturn{$rev}));
            }
         }
      }
   }
   
   # Close the query and return the reference list
   $oQuery->finish();
   return \%hReturn;
}



# _gen_permutate
#
# Iterative subroutine to generate all possible N-mers
# Credit goes to Jay Hannah (http://www.bioperl.org/wiki/Getting_all_k-mer_combinations_of_residues)
sub _gen_permutate {
   my ($min, $max, @list) = @_;
   my @curr = ($#list) x ($min - 1);
 
   return sub {
       if ( (join '', map { $list[ $_ ] } @curr) eq $list[ -1 ] x @curr ) {
           @curr = (0) x (@curr + 1);
       }
       else {
           my $pos = @curr;
           while ( --$pos > -1 ) {
               ++$curr[ $pos ], last if $curr[ $pos ] < $#list;
               $curr[ $pos ] = 0;
           }
       }
       return undef if @curr > $max;
       return join '', map { $list[ $_ ] } @curr;
   };
}

# _rev_comp
#
# Returns the reverse complement of a DNA sequence
sub _rev_comp{
   my $seq = shift(@_);
   $seq = uc($seq);
   my $rev = reverse $seq;
   $rev =~ tr/ACGU/UGCA/;
   return $rev;
}


1;