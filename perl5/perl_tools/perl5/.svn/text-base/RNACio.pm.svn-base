#!/usr/bin/perl

# Collection of functions to retrieve various types of data from the RNAcompete database

package RNACio;

use strict;
use warnings;
use Carp qw( croak );
require Exporter;

our @ISA    = qw(Exporter);
our @EXPORT = qw(get_rnacompete_assay_details);

# get_rnacompete_assay_details
#
# Function to retrieve a formatted filename for an RNAcompete assay with
# some additional details
sub get_rnacompete_assay_details {
   my ($dbh, $nHybID, $sPrefix) = @_;

   # Get required info for filename
   my ($sHybedBy,$sHybDate,$sHybCondition,$sProteinID,$sGeneName,$sSystematicID,$sPrimaryProject,$sLayout) = ('','','','','','','','');
   my $sSQL      = join(" ",
                        "SELECT H.hybridized_by,H.hybridization_date,H.hybridization_condition,H.id_protein,",
                        "M.gene_name,M.id_systematic,M.primary_project,",
                        "L.abbreviation",
                        "FROM tHybridizations H",
                        "LEFT JOIN tProteins P ON H.id_protein=P.id_protein",
                        "LEFT JOIN tPlasmids M ON P.id_plasmid=M.id_plasmid",
                        "LEFT JOIN tLayouts L ON H.id_layout=L.id_layout",
                        "WHERE H.id_hybridization=$nHybID");
   my $oQuery    = $dbh->prepare($sSQL);
   my $nCount    = $oQuery->execute();
   if ($nCount eq '0E0'){
      die "Error: could not retrieve hyb info from the database\n";
   }
   else{
      ($sHybedBy,$sHybDate,$sHybCondition,$sProteinID,$sGeneName,$sSystematicID,$sPrimaryProject,$sLayout) = $oQuery->fetchrow_array()
   }
   $oQuery->finish();
   
   # Format the gene name
   $sGeneName ||= $sSystematicID;
   $sGeneName ||= 'unknown';
   $sGeneName =~ s/\//-/g;
   $sGeneName =~ s/[:_]/-/g;
   $sGeneName =~ tr/a-zA-Z0-9-//dc; # remove special characters

   # Format the output filename
   my $sOutFile =  join('_', $sHybDate, $nHybID, $sLayout, $sHybCondition, $sProteinID, $sGeneName) . '.txt';
   $sOutFile    =~ s/\s+//g;
   $sOutFile    = join('', $sPrefix, $sOutFile) if ($sPrefix);

   # Format the name of the user that did the hyb
   $sHybedBy   =~ tr/a-zA-Z0-9-//dc; # remove special characters
   $sHybedBy ||= 'Unknown';

   # Check the primary project name
   $sPrimaryProject =~ s/\s+//g;

   return($sOutFile, $sHybedBy, $sPrimaryProject);
}


1;
