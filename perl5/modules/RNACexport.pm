#!/usr/bin/perl

package RNACexport;

#############################
# RNACexport
#
#
# Right now, it only extracts one pool for each batch; the pool with the lowest id.
#
#
#############################


use strict;
use warnings;
use DBI;
use RNACio;
use RNACstorage qw(get_storage_table_name);
require "db-connect.conf";
require Exporter;

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(get_data_for_batch);


sub get_data_for_batch {
	my ($sBatchID,$dataOutFile,$getFlaggedExpts,$get_multiple_pools,$get_specific_hybs,$specific_hyb_ids,$noPools) = @_;

	#input checking
	die "batch id or data out file not specified\n" if (!$sBatchID or !$dataOutFile);
	die "get_specific_hybs set but no hyb IDs selected\n" if ($get_specific_hybs and !$specific_hyb_ids);


	my $starttime = time;
	print "Connecting to database...\n";
	
	open(my $out, ">$dataOutFile") or die "couldn't open $dataOutFile\n";
	
	my $dbh = DBI->connect($ENV{DB_CONFIG},undef,undef, {'RaiseError' => 1}) or die "Database connection could not be made!";
	
	print "Retrieving layout data...\n";
	
	
	# get layout
	my $oLayoutIDSth = $dbh->prepare("select distinct id_layout from tHybridizations where id_batch = ?");
	my $nLayoutIDCount = $oLayoutIDSth->execute($sBatchID);
	
	my $nLayoutID;
	
	if ($nLayoutIDCount eq '0E0'){
		$oLayoutIDSth->finish();
		$dbh->disconnect();
		print STDERR "Error: No layouts associated with batch $sBatchID\n";
		exit;
	} elsif($nLayoutIDCount > 1){
		$oLayoutIDSth->finish();
		$dbh->disconnect();
		print STDERR "Error: more than one layout associated with batch $sBatchID\n";
		exit;
	} else {
		($nLayoutID) = $oLayoutIDSth->fetchrow_array();
	}
	
	my $sSQLLayout = join(" ","SELECT L.id_spot,L.id_probe,L.rna_sequence",
							"FROM tLayout_schemes L",
							"WHERE L.id_layout = ?",
							"AND L.control='FALSE'",
							"ORDER by id_spot"
						);
	my $oLayoutSth = $dbh->prepare($sSQLLayout);
	my $nLayoutSpots = $oLayoutSth->execute($nLayoutID);
	
	my @aRNASeqs = ();
	my @aSpotIDs = ();
	my @aProbeIDs = ();
	
	while(my ($nSpotID,$sProbeID,$sRNA) = $oLayoutSth->fetchrow_array()){
		push (@aRNASeqs,$sRNA);
		push (@aSpotIDs,$nSpotID);
		push (@aProbeIDs,$sProbeID);
	}
	
	$oLayoutSth->finish();
	
	#get protein and pool data
	
	my $sProteinHybsSQL;
	my $oProteinHybsSth;
	my $rData;
	my $rFlags;
	my $nCount;
	
	#get a subset of hybs by hyb ID
	#one should be a pool hyb...
	if($get_specific_hybs){ 
	
		my @anHybIDs = @{$specific_hyb_ids};
		
		
		$sProteinHybsSQL = join(' ',"SELECT H.id_hybridization,H.id_protein,Pl.gene_name",
										"FROM tHybridizations H",
										"INNER JOIN tProteins Pr on H.id_protein=Pr.id_protein",
										"INNER JOIN tPlasmids Pl on Pr.id_plasmid=Pl.id_plasmid",
										"WHERE H.id_hybridization in",
										'('.join(',',@anHybIDs).')');
		#print $sProteinHybsSQL,"\n";
										
										
#		$sProteinHybsSQL .= " AND H.experiment_flag <> 0 " unless $getFlaggedExpts == 1;
		$sProteinHybsSQL .= " ORDER BY H.id_hybridization";
		$oProteinHybsSth = $dbh->prepare($sProteinHybsSQL);
		$nCount = $oProteinHybsSth->execute();
		
 	} else { # get all hybs for batch
 	
 		$sProteinHybsSQL = join(' ',"SELECT H.id_hybridization,H.id_protein,Pl.gene_name",
									"FROM tHybridizations H",
									"INNER JOIN tProteins Pr on H.id_protein=Pr.id_protein",
									"INNER JOIN tPlasmids Pl on Pr.id_plasmid=Pl.id_plasmid",
									"WHERE H.id_batch = ?");
		$sProteinHybsSQL .= " AND H.experiment_flag <> 0 " unless $getFlaggedExpts == 1;
		$sProteinHybsSQL .= " ORDER BY H.id_hybridization";
		$oProteinHybsSth = $dbh->prepare($sProteinHybsSQL);
	
		$nCount = $oProteinHybsSth->execute($sBatchID);

 	}
	
	if ($nCount eq '0E0'){
		$oProteinHybsSth->finish();
		$dbh->disconnect();
		print STDERR "Error: No hybs associated with batch $sBatchID\n";
		exit;
	}
	
	print "Found $nCount hybs (protein+pool) for batch $sBatchID, retrieving...\n";
	
	my $nPoolsSoFar = 0;
					
	while (my ($nHybID,$sProtID,$sGeneName) = $oProteinHybsSth->fetchrow_array()){
		# only retrieve first pool
		if($sGeneName =~ /pool/){
			if($nPoolsSoFar > 0){
				next if !$get_multiple_pools;
			}
			$nPoolsSoFar++;
		}
		
		# Query and retrieve raw data
		my $sHybString = 'HybID_' . $nHybID . '_' . $sGeneName;
		print "Getting data for hyb $nHybID, protein $sGeneName\n";
	
		my $sDataTable = get_storage_table_name($nHybID,0);
		
		
		my $sSQLdata = join(" ","SELECT H.id_protein,D.id_spot,D.median_signal_intensity AS median_signal_protein, D.flag AS flag_protein",
						"FROM tLayout_schemes L",
						"LEFT JOIN $sDataTable D ON D.id_spot=L.id_spot",
						"LEFT JOIN tHybridizations H ON D.id_hybridization=H.id_hybridization",
						"WHERE D.id_hybridization = ?",
						"AND L.control='FALSE'",
						"ORDER BY D.id_spot");
		#print  $sSQLdata,"\n";
		my $oDataSth = $dbh->prepare($sSQLdata);
		my $nCount = $oDataSth->execute($nHybID) or die "Error querying database\n";
		if ($nCount eq '0E0'){
			print "Error: could not find raw data associated with hybridization $nHybID, skipping\n";
			next;
		}
	
		my @aMedData = ();
		my @aFlags = ();
	
		my $idx = 0;					
		while(my ($sProtID,$nSpotID,$nMedSignal,$nFlag) = $oDataSth->fetchrow_array() ){
			# make sure the order is preserved for each protein
			if($nSpotID ne $aSpotIDs[$idx]){
				$oProteinHybsSth->finish();
				$oDataSth->finish();
				$dbh->disconnect();
				print STDERR "Error: spot id for protein $sProtID doesn't match layout spots\n";
				exit;
			}
		 	print "." if $idx%10000==0;	
			push(@aMedData,$nMedSignal);
			push(@aFlags,$nFlag);
			
			$idx++;
		}
		print "\n";
		
		$rData->{$sHybString} = \@aMedData;
		$rFlags->{$sHybString} = \@aFlags;
					
		$oDataSth->finish();
	}
	
	$oProteinHybsSth->finish();
	

	# print data
	
	print "Printing data to file $dataOutFile...\n";
	
	my $sHeader = "id_spot\t";
	# sort the output and make sure the first column is the pool channel (so the matlab script understands)
	my @aHybs = sort pool_first keys %{$rData};
	die "ERROR: first column of output isn't pool channel" if $aHybs[0] !~ /[Pp]ool/ && !$noPools;
	foreach my $sHyb (@aHybs){
		$sHeader .= "$sHyb.MEDIAN\t$sHyb.FLAG\t";
	}
	chop $sHeader; # take off last tab
	print $out "$sHeader\n";
	
	foreach my $i (0..$#aSpotIDs){
		my $sOutLine = $aProbeIDs[$i]."\t";
		foreach my $sHyb (@aHybs){
			my $nMedSignal = $rData->{$sHyb}->[$i];
			my $nFlag = $rFlags->{$sHyb}->[$i];
			#print "$i $sHyb $nMedSignal $nFlag\n" if $i < 100;
			$sOutLine .= $rData->{$sHyb}->[$i] ."\t" . $rFlags->{$sHyb}->[$i] . "\t";
			#$sOutLine .= $rData->{$sHyb}->[$i] ."\t" ;
		}
		chop $sOutLine;
		print $out $sOutLine."\n";
	}
	
	
	
	my $endtime = time;
	
	print "Got the data in " . ($endtime-$starttime) . "s!\n";
}

sub pool_first {
	return -1 if $a =~ /pool/;
	return 1 if $b =~ /pool/;
	return $a cmp $b;
}

1;
