#!/usr/bin/perl

use strict;

require "libfile.pl";

$| = 1;
srand(time|$$);

my $TOL = 0.001;

my @flags   = (
                  [    '-f', 'scalar',     0,     1]
                , [    '-l', 'scalar',     100,     undef]
                , [    '-s', 'scalar',     undef,     undef]
                , [    '-n', 'scalar',     1,     undef]
                , [    '-a', 'scalar',  0.25, undef]
                , [    '-c', 'scalar',  0.25, undef]
                , [    '-g', 'scalar',  0.25, undef]
                , [    '-t', 'scalar',  0.25, undef]
                , [    '-r', 'scalar',  0, 1]
                , [    '-q', 'scalar',  0, 1]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $fasta_output   = $args{'-f'};
my $seq_length      = $args{'-l'};
my $spike      = $args{'-s'};
my $n_seqs      = $args{'-n'};
my $perc_a = $args{'-a'};
my $perc_c = $args{'-c'};
my $perc_g = $args{'-g'};
my $perc_t = $args{'-t'};
my $rna = $args{'-r'};
my $quiet = $args{'-q'};

if ($quiet && $fasta_output){
	die "can't suppress sequence IDs with fasta output";
}

if(length($spike) > $seq_length){
	die "can't spike sequence longer than specified length";
}

unless (1 - ($perc_a + $perc_c + $perc_g + $perc_t) < $TOL){
	die "error: if base composition specified, they must all be specified and must sum to 1"
}

my @dist = ($perc_a,$perc_c,$perc_g,$perc_t);

my @alph = ('A','C','G','T');
@alph = ('A','C','G','U') if $rna;

foreach my $iSeq (1..$n_seqs){
	my $seqID = "seq_$iSeq";
		
	my $nextSeq = "";
	
	unless ($spike){
		my $l = $seq_length;
		while($l > 0){
			$nextSeq .= _rand_base(\@alph,\@dist);
			$l--;
		}
	} else {
		my $spikepos = int(rand($seq_length-length($spike)+1));
		my $p = 0;
		while($p < $seq_length){
			if($p == $spikepos){
				$nextSeq .= $spike;
				$p += length($spike);
			} else {
				$nextSeq .= _rand_base(\@alph,\@dist);
				$p++;
			}
		}
	}
	
	if($quiet){
		print "$nextSeq\n";
	} else{
		if($fasta_output){
			print ">$seqID\n$nextSeq\n";
		} else {
			print "$seqID\t$nextSeq\n";
		}
	}	
}

sub _rand_base{
    my $alph = shift;
    my $probs = shift;
    
	my $r = rand(1);
	
	if($r < $probs->[0]) {
		return $alph->[0];
	}elsif($r < $probs->[0] + $probs->[1]) {
		return $alph->[1];
	}elsif($r < $probs->[0] + $probs->[1] + $probs->[2]) {
		return $alph->[2];
	}else{
		return $alph->[3];
	}

}



__DATA__

gen_sequence.pl [options]

   Generates (pseuro-)random DNA or RNA.
   
   -f:			Generate fasta output (default is tab-delimited)
   -r:			Generate RNA (default is DNA)
   -l <value>:	Length of sequence(s) to output (default: 100)
   -n <value>:	Number of sequences to output (default: 1)
   -q:			Suppress sequence IDs (incompatible with fasta format)
   -a <value>:	A base probability (need to set all bases or none) (default: 0.25)
   -c <value>:	C base probability (need to set all bases or none) (default: 0.25)
   -g <value>:	G base probability (need to set all bases or none) (default: 0.25)
   -t <value>:	T/U base probability (need to set all bases or none) (default: 0.25)

