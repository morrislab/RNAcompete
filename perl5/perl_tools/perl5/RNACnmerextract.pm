package RNACnmerextract;

# Given a file of normalized probe data, extract the nmer trimmed means and zscores
#
# The input should be a tab-delimited file with rows corresponding to probes and
# columns corresponding to arrays.
# 
# The first column should be the probe IDs and rna sequence in the form "probeID:rnaseq"
#

use strict;
use warnings;
use RNACgetNmers;
use DBI;

require "db-connect.conf";
require Exporter;

$| = 1;

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(extract_trimmed_mean_nmers);


sub extract_trimmed_mean_nmers{
	my ($sProbeFile,$sArrayDesignFile,$nMotifSize,$trim,$outDir,$outFile) = @_;
	$nMotifSize = 7 if !$nMotifSize;
	
	$outFile = "${nMotifSize}mer_trimmedmeans" if !$outFile;
	
	my $sOutFileSetA = $outDir . "/${outFile}_setA.txt";
	my $sOutFileSetB = $outDir . "/${outFile}_setB.txt";

	
#	my $rhProbeIDToDesc = _get_array_seqs_from_db();
	my $rhProbeIDToDesc = _get_array_seqs_from_file($sArrayDesignFile);
		
	open(my $in, $sProbeFile) or die "couldn't open $sProbeFile\n";
	my $sHeaderLine = <$in>; # header line
	my ($sJunk, @asColHeaders) = split("\t",$sHeaderLine);
		
	close($in);

	
	my $rhaTrimmedMeansSetA;
	my $rhaTrimmedMeansSetB;
	my $rhaZscoresSetA;
	my $rhaZscoresSetB;
	
	print "Extracting ${nMotifSize}mers from probe sequences and calculating trimmed means...\n";
	for (my $ii=0; $ii<=$#asColHeaders; $ii++){
		print "".$asColHeaders[$ii]."...\n";
		my $rhaSetAnmers = initialize_nmer_list_from_alphabet($nMotifSize);
		my $rhaSetBnmers = initialize_nmer_list_from_alphabet($nMotifSize);
		open(my $in, $sProbeFile) or die "couldn't open $sProbeFile\n";
		<$in>; #header
		my $nSet; # 0 for A, 1 for B
		my $nLines = 0;
		while(<$in>){
			chomp; chop while /\n/;
			my ($sProbeID, @anData) = split("\t");
			next if $anData[$ii] =~ /N/i; # added 2012-02-16 to account for new probe norm
			my $sProbeDesc = $rhProbeIDToDesc->{$sProbeID}{'desc_probe'};
			my $sRNASeq = $rhProbeIDToDesc->{$sProbeID}{'rna_sequence'};
			for(my $offset=0; $offset <= length($sRNASeq)-$nMotifSize; $offset++){
				my $nmer = substr($sRNASeq,$offset,$nMotifSize);
				my $rhaNmers;
				if($sProbeDesc =~ /SetA/){
					$rhaNmers = $rhaSetAnmers;
				}elsif($sProbeDesc =~ /SetB/){
					$rhaNmers = $rhaSetBnmers;
				}elsif($sProbeDesc !~ /Control/){
					print STDERR "Probe $sProbeID with desc $sProbeDesc not in set A or B!\n";
				}
				if ($rhaNmers->{$nmer}){
					push(@{$rhaNmers->{$nmer}},$anData[$ii]);
				} else {
					$rhaNmers->{$nmer} = [ $anData[$ii] ];
				}
			}
			$nLines++;
			print "." if $nLines % 10000 == 0;
		}
		close($in);
		print "\n";
		$rhaTrimmedMeansSetA->{$asColHeaders[$ii]} = _get_trimmed_means($rhaSetAnmers,$trim);
		$rhaTrimmedMeansSetB->{$asColHeaders[$ii]} = _get_trimmed_means($rhaSetBnmers,$trim);
		#last if $ii == 5;
	}
	
	
	
	
	
	
	print "Writing output...\n";
	open(my $outA, ">$sOutFileSetA") or die "couldn't open $sOutFileSetA\n";
	open(my $outB, ">$sOutFileSetB") or die "couldn't open $sOutFileSetB\n";
	
	#headers
	
	print $outA "${nMotifSize}mer";
	print $outB "${nMotifSize}mer";

	foreach my $sample (sort {$a cmp $b} @asColHeaders) {
		chomp $sample;
		chop $sample if $sample =~ /\r/;
		print $outA "\t${sample}_TRMEAN";
		print $outB "\t${sample}_TRMEAN";
	}
	print $outA "\n";
	print $outB "\n";

	my $nmers = initialize_nmer_list_from_alphabet($nMotifSize);

	_print_data($nmers,$rhaTrimmedMeansSetA,$outA);
	_print_data($nmers,$rhaTrimmedMeansSetB,$outB);
	
}

sub _get_array_seqs_from_db{
	#	print "Connecting to database...\n";
	#my $dbh = DBI->connect($ENV{DB_CONFIG},undef,undef, {'RaiseError' => 1}) or die "Database connection could not be made!";
	my $dbh = DBI->connect("dbi:mysql:katecook_rnacompete:hughes-db.ccbr.utoronto.ca:3306",'katecook','buGo8vI96v', {'RaiseError' => 1}) or die "Database connection could not be made!";
	my $sProbeIDDescSQL = 'SELECT id_probe,desc_probe,rna_sequence from tLayout_schemes';
	my $oProbeIDDescSth = $dbh->prepare($sProbeIDDescSQL);
	my $nProbeIDDescCount = $oProbeIDDescSth->execute();

	if($nProbeIDDescCount eq '0E0'){
		$oProbeIDDescSth->finish;
		$dbh->disconnect;
		print STDERR "Error: No data in tLayout_schemes\n";
		exit;
	}
	
	my $rhProbeIDToDesc = $oProbeIDDescSth->fetchall_hashref('id_probe');
	$oProbeIDDescSth->finish;
	$dbh->disconnect;
	return $rhProbeIDToDesc;
}

sub _get_array_seqs_from_file{
	my $inFile = shift;
	my $rhProbeIDToDesc = {};
#	my $inFile = "RBD_v3_design_unified.txt";
	open (my $in, $inFile) or die "couldn't open $inFile\n";
	while(<$in>){
		my ($id_probe,$desc_probe,$rna_sequence) = (split("\t"))[4,9,11];
		$rhProbeIDToDesc->{$id_probe}->{'desc_probe'} = $desc_probe;
		$rhProbeIDToDesc->{$id_probe}->{'rna_sequence'} = $rna_sequence;
	}
	return $rhProbeIDToDesc;
}

sub _print_data{
	my ($nmers,$rhaTrimmedMeans,$out) = @_;
	my $i = 0;
	my @asHeaders = sort {$a cmp $b} keys %{$rhaTrimmedMeans};
	foreach my $nmer (sort {$a cmp $b} keys %{$nmers}){
		next if ($nmer =~ /GAAGAGC/ || $nmer =~ /GCUCUUC/);
		print $out $nmer;
		foreach my $sample (@asHeaders){
			print $out "\t".$rhaTrimmedMeans->{$sample}->[$i];
		}
		$i++;
		print $out "\n";
	}
	close($out);
}

sub _get_trimmed_means{
	my ($rhaNmerData,$trim) = @_;
	my @anTrimmedMeans = ();
	my $ii =0;
	foreach my $nmer (sort {$a cmp $b} keys %{$rhaNmerData}){
			next if ($nmer =~ /GAAGAGC/ || $nmer =~ /GCUCUUC/);
			if(!$rhaNmerData->{$nmer}){
				$anTrimmedMeans[$ii] = 'NaN';
				$ii++;
				#print "NMER MISSING:$nmer???\n";
				next;
			}
			my @anSortedVals = sort {$a <=> $b}  @{$rhaNmerData->{$nmer}};
			if(scalar @anSortedVals > 0){
				my $nObs = $#anSortedVals +1;
				my $nToTrim = ($nObs - $nObs % (100/$trim)) / (100/$trim);
				my $start_ix = $nToTrim+1;
				my $end_ix  = $nObs-$nToTrim;
				my $total = 0;
				for (my $j = $nToTrim+1; $j <= $end_ix; $j++) {
					$total += $anSortedVals[$j];
				}
				my $mean = $total / ($end_ix - $start_ix + 1);
				#print "\t$total\t$mean\n" if $mean =~ /N/i;
				$anTrimmedMeans[$ii] = $mean;
			} else {
				$anTrimmedMeans[$ii] = 'NaN';
				#print "No Data for Nmer:$ii $nmer???\n";
			}
			$ii++;
	}
	return \@anTrimmedMeans;
}




1;