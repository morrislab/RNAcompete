#!/usr/bin/perl

# Collection of functions to deal with the split raw data storage tables

package RNACstorage;

use strict;
use warnings;
use Carp qw( croak );
require Exporter;

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(get_storage_table_name create_storage_table_if_not_exists save_batch_to_file);



# get_storage_table_name
#
# Retrieve the storage table name
sub get_storage_table_name {
   my ($nHybID, $nIsPool, $nTableSize) = @_;
   $nTableSize ||= 1000;
   
   my $nTableNo = int($nHybID/$nTableSize);
   my $sTableName = join('', 'tData_raw', sprintf("%03s", $nTableNo));
   $sTableName = join('', 'tData_pool', sprintf("%03s", $nTableNo)) if $nIsPool;
   return $sTableName;
}



# create_storage_table_if_not_exists
#
# Creates a new storage table if needed
sub create_storage_table_if_not_exists {
   my ($dbh, $sTableName) = @_;
      
      die "Error: No storage table name passed to subroutine 'create_storage_table_if_not_exists'\n" unless ($sTableName);
      my $sSQL      = join(" ",
                        "CREATE TABLE IF NOT EXISTS `$sTableName` (",
                        "  `id_hybridization` mediumint(8) unsigned NOT NULL,",
                        "  `id_spot` mediumint(8) unsigned NOT NULL,",
                        "  `flag` tinyint(3) unsigned NOT NULL,",
                        "  `mean_signal_intensity` double unsigned NOT NULL,",
                        "  INDEX (`id_hybridization`),",
                        "  INDEX (`id_spot`)",
                        ") ENGINE=MyISAM DEFAULT CHARSET=latin1;");
      $dbh->do($sSQL);
}

# save_batch_to_file
#
# Given a batch ID and a filename, saves the raw data for that batch to a tab-delimited file
# format is: spot ID, spot name, spot RNA sequence,
#    spot median for protein 1, spot flag for protein 1, spot median for protein 2, ...
#    spot median for pool 1, spot flag for pool 1, spot median for pool 2, ...
sub save_batch_to_file {
	my ($sBatchID,$dataOutFile) = @_;

	die "batch id or data out file not specified\n" if (!$sBatchID or !$dataOutFile);

	my $starttime = time;
	print "Connecting to database...\n";
	
	open(my $out, ">$dataOutFile") or die "couldn't open $dataOutFile\n";
	
	my $dbh = DBI->connect($ENV{DB_CONFIG},$ENV{USERNAME},$ENV{PASSWORD}, {'RaiseError' => 1}) or die "Database connection could not be made!";
	
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
	
	my $sSQLLayout = join(" ","SELECT L.id_spot,L.rna_sequence",
							"FROM tLayout_schemes L",
							"WHERE L.id_layout = ?",
							"AND L.control='FALSE'",
							"ORDER by id_spot"
						);
	my $oLayoutSth = $dbh->prepare($sSQLLayout);
	my $nLayoutSpots = $oLayoutSth->execute($nLayoutID);
	
	my @aRNASeqs = ();
	my @aSpotIDs = ();
	while(my ($nSpotID,$sRNA) = $oLayoutSth->fetchrow_array()){
		push (@aRNASeqs,$sRNA);
		push (@aSpotIDs,$nSpotID);
	}
	
	$oLayoutSth->finish();
	
	#get protein data
	
	my $rData;
	my $rFlags;
	
	
	my $oProteinHybsSth = $dbh->prepare("SELECT id_hybridization,id_protein FROM tHybridizations WHERE id_batch = ?");
	my $nCount = $oProteinHybsSth->execute($sBatchID);
	
	if ($nCount eq '0E0'){
		$oProteinHybsSth->finish();
		$dbh->disconnect();
		print STDERR "Error: No protein hybs associated with batch $sBatchID\n";
		exit;
	}
	
	print "Found $nCount protein hybs for batch $sBatchID, retrieving...\n";
	
	
					
	while (my ($nHybID,$sProtID) = $oProteinHybsSth->fetchrow_array()){
		# Query and retrieve raw data
		my $sHybString = 'ProtHybID_' . $nHybID . '_ProtID_' . $sProtID;
		print "Getting data for hyb $nHybID, protein $sProtID\n";
	
		my $sDataTable = get_storage_table_name($nHybID,0);
		
		my $sSQLdata = join(" ","SELECT H.id_protein,D.id_spot,D.median_signal_intensity AS median_signal_protein, D.flag AS flag_protein",
						"FROM tLayout_schemes L",
						"LEFT JOIN $sDataTable D ON D.id_spot=L.id_spot",
						"LEFT JOIN tHybridizations H ON D.id_hybridization=H.id_hybridization",
						"WHERE D.id_hybridization = ?",
						"AND L.control='FALSE'");
						
		my $oDataSth = $dbh->prepare($sSQLdata);
		
		my $nCount = $oDataSth->execute($nHybID) or die "Error querying database\n";
		die "Error: could not find raw data associated with hybridization $nHybID\n" if ($nCount eq '0E0');
	
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
			
			push(@aMedData,$nMedSignal);
			push(@aFlags,$nFlag);
			
			$idx++;
		}
		
		$rData->{$sHybString} = \@aMedData;
		$rFlags->{$sHybString} = \@aFlags;
		
		$oDataSth->finish();
	}
	
	$oProteinHybsSth->finish();
	
	# get pool data
	
	
	my $oPoolHybsSth = $dbh->prepare("SELECT id_pool_hybridization,id_pool FROM tPool_Hybridizations WHERE id_batch = ?");
	my $nPoolCount = $oPoolHybsSth->execute($sBatchID);
	
	if ($nPoolCount eq '0E0'){
		$oPoolHybsSth->finish();
		$dbh->disconnect();
		print STDERR "Error: No pool hybs associated with batch $sBatchID\n";
		exit;
	}
	
	print "Found $nPoolCount pool hybs for batch $sBatchID, retrieving...\n";
	
	
					
	while (my ($nHybID,$sPoolID) = $oPoolHybsSth->fetchrow_array()){
		# Query and retrieve raw data
		my $sHybString = 'PoolHybID_' . $nHybID . '_PoolID_' . $sPoolID;
		print "Getting data for hyb $nHybID, pool $sPoolID\n";
	
		my $sDataTable = get_storage_table_name($nHybID,1);
		
		my $sSQLdata = join(" ","SELECT H.id_pool,D.id_spot,D.median_signal_intensity AS median_signal_pool, D.flag AS flag_pool",
						"FROM tLayout_schemes L",
						"LEFT JOIN $sDataTable D ON D.id_spot=L.id_spot",
						"LEFT JOIN tPool_Hybridizations H ON D.id_hybridization=H.id_pool_hybridization",
						"WHERE D.id_hybridization = ?",
						"AND L.control='FALSE'");
		
		
		my $oDataSth = $dbh->prepare($sSQLdata);
		
		my $nCount = $oDataSth->execute($nHybID) or die "Error querying database\n";
		die "Error: could not find raw data associated with hybridization $nHybID\n" if ($nCount eq '0E0');
	
		my @aMedData = ();
		my @aFlags = ();
	
		my $idx = 0;					
		while(my ($sProtID,$nSpotID,$nMedSignal,$nFlag) = $oDataSth->fetchrow_array() ){
			# make sure the order is preserved for each protein
			if($nSpotID ne $aSpotIDs[$idx]){
				$oProteinHybsSth->finish();
				$oDataSth->finish();
				$dbh->disconnect();
				print STDERR "Error: spot id for pool $sPoolID doesn't match layout spots\n";
				exit;
			}
			
			push(@aMedData,$nMedSignal);
			push(@aFlags,$nFlag);
			
			$idx++;
		}
		
		$rData->{$sHybString} = \@aMedData;
		$rFlags->{$sHybString} = \@aFlags;
		
		$oDataSth->finish();
	}
	
	$oPoolHybsSth->finish();
	
	
	
	# print data
	
	print "Printing data to file $dataOutFile...\n";
	
	my $sHeader = "id_spot\trna_sequence\t";
	my @aHybs = sort keys %{$rData};
	foreach my $sHyb (@aHybs){
		$sHeader .= "$sHyb.MEDIAN\t$sHyb.FLAG\t";
	}
	chop $sHeader; # take off last tab
	print $out "$sHeader\n";
	
	foreach my $i (0..$#aSpotIDs){
		my $sOutLine = $aSpotIDs[$i]."\t".$aRNASeqs[$i]."\t";
		foreach my $sHyb (@aHybs){
			my $nMedSignal = $rData->{$sHyb}->[$i];
			my $nFlag = $rFlags->{$sHyb}->[$i];
			#print "$i $sHyb $nMedSignal $nFlag\n" if $i < 100;
			$sOutLine .= $rData->{$sHyb}->[$i] ."\t" . $rFlags->{$sHyb}->[$i] . "\t";
		}
		chop $sOutLine;
		print $out $sOutLine."\n";
	}
	
	
	
	my $endtime = time;
	
	print "Got the data no prob-lemo! Only took " . ($endtime-$starttime) . "s!\n";
}

1;
