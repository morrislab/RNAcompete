#!/usr/bin/perl

# cg: ClueGene: Score and rank gene query sets read from the standard input.

#--------------------------------------------------------------------------------
# ClueGene: Recommending Pathway Genes Using a Compendium of Clustering Solutions
# Copyright (C) 2006 The Regents of the University of California
# All Rights Reserved
# Created by David M. Ng, Marcos H. Woehrmann, and Joshua M. Stuart
# Department of Biomolecular Engineering, University of California, Santa Cruz
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# You can contact the authors via electronic mail:
# dmng@soe.ucsc.edu, marcosw@soe.ucsc.edu, and jstuart@soe.ucsc.edu
#
# Postal address:
# Department of Biomolecular Engineering
# University of California, Santa Cruz
# 1156 High Street
# Santa Cruz, CA 95064
#--------------------------------------------------------------------------------

# Please cite the following article when using ClueGene:
#   Ng DM, Woehrmann MH, Stuart JM.
#   Recommending Pathway Genes Using a Compendium of Clustering Solutions.
#   Pacific Symposium on Biocomputing 12:379-390(2007).
#   Article: http://psb.stanford.edu/psb-online/proceedings/psb07/ng.pdf
#   Online Supplement: http://sysbio.soe.ucsc.edu/cluegene/psb07/

# See sub cg_printHelpInfo for usage information.
#
# Details for --scoremethod option:
#   --scoremethod <integer>
#       If specified: the specified scoring method is used.
#       If not specified: method 0 (the default scoring method) is used.
#       Method 0: The current default scoring method.
#       Method 1: A cluster's score is equal to 1 if it contains all of the query
#           genes, and 0 otherwise.  A gene's score is the sum of all the cluster
#           scores of clusters contining the gene.
#       Method 2: A cluster's score is the percentage of query genes present in
#           the cluster.  A gene's score is the sum of all the cluster scores
#           of clusters contining the gene.
#       Method 3: A cluster's score is the number of query genes found in the
#           cluster divided by the number of genes in the union of the query set
#           and the cluster.  A gene's score is the sum of all the cluster scores
#           of clusters contining the gene. This is similar to method 2, except
#           scores for larger clusters are downweighted.
#       Method 4: This is the same as method 3, except a gene's score is normalized
#           by dividing by the number of clusters contributing to the score.
#       Method 5: This is the same as method 3, except a cluster's score is
#           normalized by dividing by the total number of clusters within the same
#           dataset that have non-zero scores.
#       Method 6: This is the same as method 2, except a cluster's score is the
#           *square* of the percentage of query genes present in the cluster.
#       Method 7: This is the same as method 5, except a query gene does not
#           contribute to its score when scoring a cluster. This is currently the
#           default method.
#       Note: although the implementation of each scoring method was tested as
#           Gene Shopper/GeneShop/ClueGene evolved, the *selecting* between 
#           different methods was tested only for methods 3, 5, and (in the future)
#           beyond 6.
#
# Version History
# (Remember to update $cgversion.)
#	v4.1	2008-04-22: Added support for three-part cluster id. The second
#			part (dataset id) and third part (data type) are merged into a
#			single dataset id.
#	v4.0	2008-02-05: Implemented generating average precision of query genes
#			in score file. New scorefile version (1.1) for query set average
#			precision.
#   v3.9    2007-12-20: Completed initial implementation of --noidpound.
#           Implemented --testout. Updated help information for relevance 
#           feedback.
#           2007-12-19: Began implementation: Check gene ids for spurious #
#           characters, under control of new option --noidpound.
#               id#...                      keep id only
#               id, #...                    keep id only
#               INTERGENIC CONTROL #...     ignore entire id
#               INTERGENIC_CONTROL #...     ignore entire id
#           Implemented sub noGeneIdPound. Fixed version history comment for
#           2007-09-25.
#   v3.8    2007-09-25: Began implementation of pseudo-relevance feedback.
#   v3.7    2007-08-10: Corrected some comments.
#   v3.6    2007-08-09: Updated help information (use --printscores for mergescore.pl).
#   v3.5    2007-07-23: Implemented scoring method 7; it is now the default.
#   v3.4    2007-04-19: Implemented --genome and --nocasenorm options.
#   v3.3    2007-03-09: Fixed bug in printing execution time (added "use POSIX;").
#   v3.2    2007-03-03: Implement --quiet, --noincludecomments, and --datalinecomments
#           options. Updated comments and help information. Updated informational
#           comments. Implement --expected and --incquery options. Began
#           implementation of --noavgrank. Fixed a bug: expected genes with zero 
#           scores appear in the result list (see sub cg_score).
#   v3.1    2006-11-15: Print version and option information unconditionally (i.e.,
#           not under --verbose) to STDOUT (instead of STDERR).
#   v3.0    2006-11-15: Changed output to rank file format. Added option --scorefile.
#           Normalize AUC by theoretical maximum.
#   v2.2    2006-11-14: Fixed a comment (in cg_auc).
#   v2.1    2006-10-24: Added GPL. Minor documentation changes. Renumbered versions
#           from 1.x to 2.x for consistency with original cluegene.pl.
#           2006-10-23: Completed implementation of -a, -f, -g, and -s options.
#           2006-10-22: Improved help information. Prototyped implementation of -a,
#           -f, -g, and -s options.
#           2006-10-21: Check for invalid score method. Corrected code for detecting
#           comment lines. Refactored the code. For the gene type flag, in addition
#           to the Q and E flags, N is printed instead of nothing for neither Q nor E.
#           Changed "scores" option name to "printscores".
#           2006-10-20: Changed formatting of output area values (percentage, 1 
#           decimal place) and scores (scale 1000x, round to integer). All 
#           subfields (now including Q/E flag) are separated. Added --sep option.
#           Default is to not print scores; option changed from "noscores" to
#           "scores".
#   v2.0    2006-10-18: Created from cluegene.pl version 1.3.

use strict;
use POSIX;      # for strftime
 
my $cgversion = "4.1";          # ClueGene version
my $ccfileversion = "1.0";      # cluster compendium file version
my $pathwaycompendiumfileversion = "1.0";   # pathway compendium file version
my $queryfileversion = "1.0";   # query file version
my $rankfileversion = "1.0";    # rank file version
my $scorefileversion = "1.1";   # score file version
my $genomefileversion = "1.0";  # genome file version


# define error codes
my $ERR_NOERROR = 0;
my $ERR_FILEOPEN = 1;
my $ERR_DATAFORMAT = 2;
my $ERR_NODATASETS = 3;
my $ERR_EOF = 5;
my $ERR_INVALIDSCOREMETHOD = 6;


#==============================================================================
# sub cg_assignRanks
# Given a hash of gene ids (key) and corresponding score (value), assign
# ranks to the genes. Genes with equal scores are assigned the average rank
# (i.e., the fractional rank, or "1 2.5 2.5 4" rank) of the genes.
#==============================================================================

sub cg_assignRanks
{
    my $scores = shift;     # in: ref to hash for score for each gene
                            #   key = gene id; value = score
    my $ranks = shift;      # out: ref to hash for rank for each gene
                            #   key = gene id; value = rank
    
    my @orderedGenes = (sort {$$scores{$b} <=> $$scores{$a}} (keys %$scores));
    
    my $nextRank = 1;
    
    # repeat for each group of genes with equal scores
    my $i = 0;
    while ($i < @orderedGenes)
    {
        # find index of next element with a different score
        my $j = $i + 1;
        while ($j < @orderedGenes && 
               $$scores{$orderedGenes[$i]} == $$scores{$orderedGenes[$j]})
        {
            $j++
        };
    
        # compute average rank: (first+last)/2
        my $avgRank = ($nextRank + ($nextRank + ($j - $i - 1))) / 2; 
        
        # assign average rank to genes with same score
        for (my $k = $i; $k < $j; $k++)
        {
            $$ranks{$orderedGenes[$k]} = $avgRank;
        }
        
        $nextRank += ($j - $i);
        $i = $j;
    }
}


#==============================================================================
# sub cg_averagePrecision
# Given a hash of gene ids (key) and corresponding ranks (value), compute the
# average precision of those genes.
#==============================================================================

sub cg_averagePrecision
{
    my $geneRanks = shift;      # in: ref to hash enumerating basis genes
                                #   key = gene id; value = rank

    my @orderedGenes = (sort {$$geneRanks{$a} <=> $$geneRanks{$b}}
                             (keys %$geneRanks));
                                
    return 0 if (@orderedGenes <= 0);

    my $sumPrecision = 0;
    
    for (my $i = 0; $i < @orderedGenes; $i++)
    {
        # (number of genes recalled) / rank
        $sumPrecision += ($i + 1) / $$geneRanks{$orderedGenes[$i]};
    }
    
    return $sumPrecision / @orderedGenes;
}


#====================================================================
# sub noGeneIdPound
# Process gene ids for spurious pound characters:
#   id#...                      keep id only
#   id, #...                    keep id only
#   INTERGENIC CONTROL #...     ignore entire id
#   INTERGENIC_CONTROL #...     ignore entire id
#====================================================================

sub noGeneIdPound
{
    # process parameter
    my $geneid = shift;
    
    if (($geneid =~ /^INTERGENIC CONTROL #/) ||
        ($geneid =~ /^INTERGENIC_CONTROL #/))
    {
        # ignore entire id
        $geneid = "";
    }
    elsif (($geneid =~ /^(.+?), #/) || ($geneid =~ /^(.+?)#/))
    {
        # keep valid part of id (? for minimal match)
        $geneid = $1;
    }
    
    return $geneid;
}


##################################
# sub read_genome                #
# Input genome from genome file. #
##################################

sub read_genome
{
    # process parameters
    my $genome_file = shift;        # in: name of the genome file
    my $noincludecomments = shift;  # in: noincludecomments option
    my $datalinecomments = shift;   # in: datalinecomments option
    my $noCaseNorm = shift;         # in: nocasenorm option
    my $genome = shift;             # out: ref to hash of gene ids
    my $noidpound = shift;          # in: opt: noidpound option
    
    # initialize output parameters
    undef %$genome;
    
    
    # open genome file
    if (!open(GENOME, $genome_file))
    {
        # an error was detected
        return $ERR_FILEOPEN;
    }
    
    
    # repeat for each line of the genome file (each line has one gene id)
    while(<GENOME>) 
    {
        # handle non-data lines
        if ($_ =~ /^\s*#/)
        {
            # a comment line, copy to output if appropriate and otherwise ignore
            print "#$_" if !$noincludecomments;
            next;
        }
        elsif ($_ =~ /^\s*$/)
        {
            # ignore a blank line
            next;
        }
    
        chomp;
    
        if ($datalinecomments && $_ =~ /#/)
        {
            # data line comments are enabled, and data line contains an embedded "#"
            # remove the comment
            $_ =~ /(^.*?)#/;     # minimal match (?) to find first #
            $_ = $1;
        }
        
        # format of file: tab separated fields, first (zero-th) field is the gene id,
        # subsequent fields are ignored
        my @fields = split "\t";
        my $geneid = $fields[0];
        $geneid = uc $geneid if !$noCaseNorm;
            
        # processing for pound characters in id
        $geneid = noGeneIdPound($geneid) if ($noidpound);
        next if ($geneid eq "");
            
        $$genome{$geneid} = 1;
    }
    
    close(GENOME);
    
    return $ERR_NOERROR;
}


##############################################################
# sub read_compendium                                        #
# Input cluster data and dataset names from compendium file. #
##############################################################

sub read_compendium
{
    # process parameters
    my $compendium_file = shift;    # in: name of the compendium file
    my $noincludecomments = shift;  # in: noincludecomments option
    my $datalinecomments = shift;   # in: datalinecomments option
    my $noCaseNorm = shift;         # in: nocasenorm option
    my $extGenome = shift;          # in: true => genome defined externally
    my $clusters = shift;           # out: ref to array of cluster data
    my $genome = shift;             # out: ref to hash of gene ids
    my $datasets = shift;           # out: ref to array of dataset names
    my $noidpound = shift;          # in: opt: noidpound option
    
    # initialize output parameters
    undef @$clusters;
    undef %$genome if !$extGenome;
    undef @$datasets;
    
    
    # open compendium file
    if (!open(COMPENDIUM, $compendium_file))
    {
        # an error was detected
        return $ERR_FILEOPEN;
    }
    
    
    # number of datasets processed so far
    my $num_data_sets = 0;
    
    # map from dataset name to dataset index
    my %ds_name2index;
    
    # repeat for each line of the compendium file (each line has data for one cluster)
    while(<COMPENDIUM>) 
    {
        # handle non-data lines
        if ($_ =~ /^\s*#/)
        {
            # a comment line, copy to output if appropriate and otherwise ignore
            print "#$_" if !$noincludecomments;
            next;
        }
        elsif ($_ =~ /^\s*$/)
        {
            # ignore a blank line
            next;
        }
    
        chomp;
    
        if ($datalinecomments && $_ =~ /#/)
        {
            # data line comments are enabled, and data line contains an embedded "#"
            # remove the comment
            $_ =~ /(^.*?)#/;     # minimal match (?) to find first #
            $_ = $1;
        }
        
        # format of file: tab separated fields, first field is the cluster id
        # qualified with the dataset name (a string), subsequent fields are
        # gene ids (strings)
        my @fields = split "\t";
        if (@fields < 2)
        {
            # error: a line must have a cluster id and at least one member gene
            return $ERR_DATAFORMAT;
        }
        
        # get the cluster id and dataset name from the first field
		my ($cid, $datasetname);
		if ($fields[0] =~ /(.*)@(.*)@(.*)/)
		{
			# merge dataset id and data type into a single dataset id
			($cid, $datasetname) = ($1, $2."@".$3);
		}
		else
		{
			$fields[0] =~ /(.*)@(.*)/;
			($cid, $datasetname) = ($1, $2);
		}
        
        # process dataset name
        if (!exists $ds_name2index{$datasetname})
        {
            # a new dataset name
            $ds_name2index{$datasetname} = $num_data_sets;
            $$datasets[$num_data_sets] = $datasetname;
            $num_data_sets++;
        }
        my $d = $ds_name2index{$datasetname};
        
        # repeat for each gene in the cluster: record the gene in the cluster
        # and in the genome
        for (my $i = 1;  $i < @fields;  $i++) 
        {
            my $geneid = $fields[$i];
            $geneid = uc $geneid if !$noCaseNorm;
            
            # processing for pound characters in id
            $geneid = noGeneIdPound($geneid) if ($noidpound);
            next if ($geneid eq "");
             
            $$clusters[$d]{$cid}{$geneid} = 1;
            $$genome{$geneid} = 1 if !$extGenome;
        }
    }
    
    close(COMPENDIUM);
    
    if ($num_data_sets <= 0)
    {
        return $ERR_NODATASETS;
    }
    
    return $ERR_NOERROR;
}


###############################################
# sub read_expected                           #
# Input pathway gene sets from expected file. #
###############################################

sub read_expected
{
    # process parameters
    my $expected_file = shift;      # in: name of the expected set file
    my $noincludecomments = shift;  # in: noincludecomments option
    my $datalinecomments = shift;   # in: datalinecomments option
    my $noCaseNorm = shift;         # in: nocasenorm option
    my $expectedset = shift;        # out: ref to hash of expected sets
    my $noidpound = shift;          # in: opt: noidpound option
    
    # initialize output parameter
    undef %$expectedset;
    
    
    # open expected file
    if (!open(EXPECTED, $expected_file))
    {
        # an error was detected
        return $ERR_FILEOPEN;
    }
    
        
    # repeat for each line of the pathway compendium file (each line has
    # data for one pathway)print "$geneid.\n";

    while(my $line = <EXPECTED>) 
    {
        # handle non-data lines
        if ($line =~ /^\s*#/)
        {
            # a comment line, copy to output if appropriate and otherwise ignore
            print "#$line" if !$noincludecomments;
            next;
        }
        elsif ($line =~ /^\s*$/)
        {
            # ignore a blank line
            next;
        }
    
        chomp $line;
    
        if ($datalinecomments && $line =~ /#/)
        {
            # data line comments are enabled, and data line contains an embedded "#"
            # remove the comment
            $line =~ /(^.*?)#/;     # minimal match (?) to find first #
            $line = $1;
        }
        
        # format of file: tab separated fields, first field is the pathway id
        # subsequent fields are gene ids (strings)
        my @fields = split "\t", $line;
        my $pw_id = shift @fields;
        
        # for the expected set hash, the key is the pathway id and the value
        # is a hash of the genes of the pathway
        my %pwgenes;
        foreach my $g (@fields)
        {
            $g = uc $g if !$noCaseNorm;
            
            # processing for pound characters in id
            $g = noGeneIdPound($g) if ($noidpound);
            next if ($g eq "");

            $pwgenes{$g} = 1;
        }       
        $$expectedset{$pw_id} = \%pwgenes;
    }
    
    close(EXPECTED);
    
    return $ERR_NOERROR;
}


##################################################################
# sub cg_readQuerySet                                            #
# Read a query set (i.e., one set per line) from standard input. #
##################################################################
    
sub cg_readQuerySet
{
    # process parameters
    my $genome = shift;             # in: ref to hash of genome
    my $noincludecomments = shift;  # in: noincludecomments option
    my $datalinecomments = shift;   # in: datalinecomments option
    my $noCaseNorm = shift;         # in: nocasenorm option
    my $s_queries = shift;          # out: ref to string for query set
    my $a_queries = shift;          # out: ref to array for query set
    my $h_queries = shift;          # out: ref to hash for query set
    my $pathway_id = shift;         # out: ref to string for pathway id
    my $noidpound = shift;          # in: opt: noidpound option
    
    # initialize output parameter
    undef %$h_queries;
    
    
    # repeat until end-of-file or a non-comment line is read
    while (my $line = <STDIN>)
    {
        # handle non-data lines
        if ($line =~ /^\s*#/)
        {
            # a comment line, copy to output if appropriate and otherwise ignore
            print "#$line" if !$noincludecomments;
            next;
        }
        elsif ($line =~ /^\s*$/)
        {
            # ignore a blank line
            next;
        }
        
        chomp $line;
    
        if ($datalinecomments && $line =~ /#/)
        {
            # data line comments are enabled, and data line contains an embedded "#"
            # remove the comment
            $line =~ /(^.*?)#/;     # minimal match (?) to find first #
            $line = $1;
        }

        # put each gene in a separate array element
        my @genes = split /\t+/, $line;
        
        # the first field is the pathway id
        $$pathway_id = shift @genes;

        if (!$noCaseNorm)
        {
            # normalize the case of the gene ids
            @genes = split /\t+/, uc $line;
            shift @genes;   # discard the pathway id
        }
        
        # sort the query genes and interpolate to make one string of gene ids
        @genes = sort @genes;
        $$s_queries = "@genes";
        
        # represent the query set as an array
        @$a_queries = split /\s+/, $$s_queries;
        
        # repeat for each query gene
        for (my $i = 0;  $i < @$a_queries;  $i++)
        {            
            my $geneid = $$a_queries[$i];

            # processing for pound characters in id
            $geneid = noGeneIdPound($geneid) if ($noidpound);
            next if ($geneid eq "");
        
            # add the query gene to the hash if the query gene is in the genome
            if ($$genome{$geneid})
            {
                $$h_queries{$geneid} = 1;
            }
        }
        
        return $ERR_NOERROR;
    }
    
    # fell through loop, must be end-of-file
    $$pathway_id = "";
    $$s_queries = "";
    @$a_queries = ();
    return $ERR_EOF;
}


######################################
# sub cg_score                       #
# Score all the genes of the genome. #
######################################

sub cg_score
{
    # process parameters
    my $scoremethod = shift;    # in: the scoring method
    my $queries = shift;        # in: ref to array of query genes
    my $datasets = shift;       # in: ref to array of dataset names
    my $clusters = shift;       # in: ref to array of cluster data
    my $genome = shift;         # in: ref to hash of genome
    my $ccscore_g = shift;      # out: ref to hash for co-clustering scores for each gene
    my $ccscore_gd = shift;     # out: ref to hash for co-clustering scores for each
                                # gene, by dataset
    my $numclu_gd = shift;      # out: ref to hash for number of clusters
                                # contributing to each gene's score, by dataset 
                                
    # initialize output parameters
    undef %$ccscore_g;
    
    # v3.2 2007-03-03
    # initialize all genes in the genome to a score of 0
    # thus expected genes with a 0 score will have an explicit score
    for my $g (keys %{$genome})
    {
        $$ccscore_g{$g} = 0;
    }
    
    undef %$ccscore_gd;
    undef %$numclu_gd;
    
    my %contrib_clu;    # number of clusters contributing to score of the gene


    # repeat for each dataset
    for (my $ds = 0; $ds < @$datasets; $ds++) 
    {   
        # repeat for cluster in the current dataset
        for my $i (keys % {$$clusters[$ds]}) 
        {
            # count the number of query genes found in the cluster
            my $numq = 0;
            for my $query (@$queries) 
            {
                $numq += $$clusters[$ds]{$i}{$query};
            }
            
            # scoring method 3, 4, 5, and 7
            if ($scoremethod == 3 || $scoremethod == 4 ||
                $scoremethod == 5 || $scoremethod == 7)
            {
                # if the dataset and cluster contribute to the score ...
                # weight the score by the dataset weight
                if ($numq > 0)
                {
                    my $clusterSize = scalar(keys % {$$clusters[$ds]{$i}});
                    my $score = $numq/(@$queries+$clusterSize-$numq);
                    my $qg_score = ($numq-1)/(@$queries+$clusterSize-$numq);
                    
                    for my $g (keys % {$$clusters[$ds]{$i}}) 
                    {                   
                        # determine if query gene
                        my $isQuery = 0;
                        for my $q (@$queries)
                        {
                            if ($g eq $q)
                            {
                                $isQuery = 1;
                                last;
                            }
                        }

                        my $s = $score;
                        if ($scoremethod == 7 && $isQuery)
                        {
                            $s = $qg_score;
                        }
                        $$ccscore_g{$g} += $s;
                        $$ccscore_gd{$g}{$$datasets[$ds]} += $s;
                        $$numclu_gd{$g}{$$datasets[$ds]}++;
                        $contrib_clu{$g}++;
                    }
                }
            }
            
            # scoring method 1
            elsif ($scoremethod == 1) 
            {
                # only count if all query genes are present
                if ($numq == @$queries)
                {
                    for my $g (keys % {$$clusters[$ds]{$i}}) 
                    {
                        $$ccscore_g{$g}++;
                        $$ccscore_gd{$g}{$$datasets[$ds]}++;
                        $$numclu_gd{$g}{$$datasets[$ds]}++;
                    }
                }
            }
            
            # scoring methods 2 and 6
            elsif ($scoremethod == 2 || $scoremethod == 6)
            {
                # score based on percentage of query genes which are present
                if ($numq > 0)
                {
                    for my $g (keys % {$$clusters[$ds]{$i}}) 
                    {
                        if ($scoremethod == 6)
                        {
                            $$ccscore_g{$g} += ($numq/@$queries*$numq/@$queries);
                        }
                        else
                        {
                            # score method 2
                            $$ccscore_g{$g} += ($numq/@$queries);
                        }
                        $$ccscore_gd{$g}{$$datasets[$ds]} += ($numq/@$queries);
                        $$numclu_gd{$g}{$$datasets[$ds]}++;
                    }
                }
            }
            
            # invalid scoring method
            else
            {
                return $ERR_INVALIDSCOREMETHOD;
            }
        }
    }
    
    
    #------------------#
    # Normalize scores #
    #------------------#
    
    if ($scoremethod == 5 || $scoremethod == 7)
    {
        for my $g (keys %$ccscore_g)
        {
            $$ccscore_g{$g} = 0;
            
            # repeat for each dataset
            for (my $ds = 0; $ds < @$datasets; $ds++) 
            {
                if (exists $$ccscore_gd{$g}{$$datasets[$ds]})
                {
                    # dataset $ds contributes to gene $g's score
                    # normalize the score contribution of dataset $ds by the number of
                    # clusters within the dataset that contribute to the score
                    $$ccscore_g{$g} += $$ccscore_gd{$g}{$$datasets[$ds]} /                        
                            $$numclu_gd{$g}{$$datasets[$ds]};
                }
            }
        }
    }
    elsif ($scoremethod == 4)
    {
        # normalize scores by the number of clusters contributing to the score
        for my $g (keys %$ccscore_g)
        {
            $$ccscore_g{$g} = $$ccscore_g{$g}/$contrib_clu{$g};
        }
    }
    
    return $ERR_NOERROR;
}


###############################################
# sub cg_printRankFile                        #
# Print the rank file to the standard output. #
###############################################

sub cg_printRankFile
{
    # process parameters
    my $includeQueryGenes = shift;  # in: include query genes in results if true
    my $pathway_name = shift;       # in: pathway name
    my $genome_size = shift;        # in: genome size
    my $queries = shift;            # in: ref to hash of query genes
    my $expected = shift;           # in: ref to hash of expected genes
    my $ccscore_g = shift;          # in: ref to hash of gene co-clustering scores
    
    
    # print pathway name (field 1)
    print "$pathway_name";
    
    # print maximum possible rank (field 2)
    if (!$includeQueryGenes)
    {
        my $maxPossibleRank = $genome_size - (scalar keys %$queries);
        print "\t$maxPossibleRank";
    }
    else
    {
        print "\t$genome_size";
    }
    
    #if ($noavgrank)
    if (1)
    {
        #-------------------------------------------------------------#
        # do not compute average rank for genes with identical scores #
        #-------------------------------------------------------------#

        # number of genes processed
        my $numgenes = 0;
        
        # repeat for each gene in order of decreasing score
        for my $gene (sort {$$ccscore_g{$b} <=> $$ccscore_g{$a}} (keys %$ccscore_g)) 
        {
            # skip query genes if they are not to be included in the results
            next if (defined $$queries{$gene} && !$includeQueryGenes);
            
            # at this point we have a result gene to count
            $numgenes++;
            
            if (defined $$expected{$gene})
            {
                # this is a gene in the expected set
                print "\t$numgenes";
            }
        }
    }
    else
    {
        #------------------------------------------------------#
        # compute average rank for genes with identical scores #
        #------------------------------------------------------#
        
        # NOT YET IMPLEMENTED, CURRENTLY SAME AS NOAVGRANK CASE

        # number of genes processed
        my $numgenes = 0;
        
        # repeat for each gene in order of decreasing score
        for my $gene (sort {$$ccscore_g{$b} <=> $$ccscore_g{$a}} (keys %$ccscore_g)) 
        {
            # skip query genes if they are not to be included in the results
            next if (defined $$queries{$gene} && !$includeQueryGenes);
            
            # at this point we have a result gene to count
            $numgenes++;
            
            if (defined $$expected{$gene})
            {
                # this is a gene in the expected set
                print "\t$numgenes";
            }
        }
    }
    
    print "\n";
}


##############################################
# sub cg_auc                                 #
# Compute area under precision-recall curve. #
##############################################

sub cg_auc
{
    # process parameters
    my $includeQueryGenes = shift;  # in: include query genes in results if true
    my $queries = shift;            # in: ref to hash of query genes
    my $expected = shift;           # in: ref to hash of expected genes
    my $ccscore_g = shift;          # in: ref to hash of gene co-clustering scores
    my $pathway_size = shift;       # out: ref to scalar for pathway size
    

    # number of expected genes in the pathway
    $$pathway_size = scalar keys %$expected;
    
    if (!$includeQueryGenes)
    {
        # need to adjust pathway size to exclude query genes
        for my $qg (keys %$queries)
        {
            if (exists $$expected{$qg})
            {
                # found a query gene in the expected set
                $$pathway_size--;
            }
        }
    }
    
    # area under the precision/recall curve
    my $area = 0;
    
    if ($$pathway_size > 0)
    {
        # a non-empty expected set was specified, so a precision-recall plot
        # can be produced
    
        # number of Query and Expected genes that were identified
        my $num_QE = 0;
        
        # save the previously computed precision and recall (for computing the area)
        my $precision_prev;
        my $recall_prev;
        
        # number of genes processed
        my $numgenes = 0;
        
        # repeat for each gene in order of decreasing score
        for my $gene (sort {$$ccscore_g{$b} <=> $$ccscore_g{$a}} (keys %$ccscore_g)) 
        {
            if (defined $$queries{$gene} && defined $$expected{$gene})
            {
                # this is a gene in the query set, and it is in the expected set
                # skip if query genes are not to be included in the results
                next if !$includeQueryGenes;
                $num_QE++;
            }
            elsif (defined $$expected{$gene})
            {
                # this is a gene in the expected set
                $num_QE++;
            }
            
            # at this point we have a result gene to count
            $numgenes++;
            
            # compute recall and precision
            my $recall = $num_QE/$$pathway_size;
            my $precision = $num_QE/$numgenes;
            
            if ($numgenes > 1)
            {
                # update area using the trapezoidal rule
                $area += ($recall - $recall_prev) * ($precision + $precision_prev) / 2;
            }
            
            # save precision and recall for next iteration
            $precision_prev = $precision;
            $recall_prev = $recall;
        }
    }
    
    # normalize area by theoretical maximum (avoid division by zero)
    $area = $area / (1-(1/$$pathway_size)) if $$pathway_size > 1;
    
    return $area;
}


##########################################################
# sub cg_annotateGeneDefault                             #
# Return a string for the gene, annotated appropriately. #
##########################################################

sub cg_annotateGeneDefault
{
    # process parameters
    my $gene = shift;           # in: the gene id
    my $ccscore_g = shift;      # in: ref to hash of gene co-clustering scores
    my $queries = shift;        # in: ref to hash of query genes
    my $expected = shift;       # in: ref to hash of expected genes
    my $printScores = shift;    # in: if true, print scores and flags in the output
    my $sep = shift;            # in: subfield separator string
    
    my $annotation = $gene;
    
    # add optional information about the gene
    if ($printScores)
    {   
        $annotation .= "$sep";
    
        # append the Q/E/N flag
        if (defined $$queries{$gene} && defined $$expected{$gene}) 
        {
            $annotation .= "Q";
        } 
        elsif (defined $$expected{$gene}) 
        {
            $annotation .= "E";
        }
        else
        {
            $annotation .= "N";
        }
        
        # append the gene's score
        $annotation .= "$sep";
        $annotation .= int($$ccscore_g{$gene}*1000 + 0.5);
    }
    
    return $annotation;
}


##################################################
# sub cg_printHelpInfo                           #
# Print help information to the standard output. #
##################################################

sub cg_printHelpInfo
{
    # process parameters
    my $sepDefault = shift; 
    my $sep = shift;

    print "\nClueGene Help Information\n";
    print "=========================\n\n";
    print "Score and rank gene query sets read from the standard input.\n";
    print "cg.pl version $cgversion (a component of the ClueGene pipeline).\n\n";
    print "Input Format\n";
    print "------------\n";
    print "  1. Query sets are read from the standard input, one query set per line.\n";
    print "  2. Each line consists of tab-delimited fields.\n";
    print "  3. The first field is the query id, a name used to identify the query set.\n";
    print "  4. The remaining fields are gene ids.\n\n";
    print "Output Rank File Format\n";
    print "-----------------------\n";
    print "  1. The rank file is written to the standard output.\n";
    print "  2. Each non-comment line corresponds to one query set.\n";
    print "  3. Each non-comment line consists of tab-separated fields.\n";
    print "  4. The first field is the query id.\n";
    print "  5. The second field is the maximum possible rank.\n";
    print "  6. Subsequent fields are the ranks of the expected genes (in increasing order).\n";
    print "  7. The number of expected gene rank fields is the pathway size.\n\n";
    print "Output Score File Format\n";
    print "------------------------\n";
    print "  1. The optional score file is specified with the --scorefile option.\n";
    print "  2. Each output line corresponds to one query set.\n";
    print "  3. Each line consists of tab-delimited fields.\n";
    print "  4. The first field is the pathway field.\n";
    print "  5. The second field is the average precision of the query genes.\n";
    print "  6. The remaining fields are gene fields, one for each gene in the genome.\n";
    print "     The gene fields are ordered by ClueGene score, from the highest score\n";
    print "     (field 3) to the lowest (the last field).\n";
    print "  7. An output field may consist of multiple subfields, each separated by\n";
    print "     the subfield separator string. The subfield separator may be specified\n";
    print "     with the --sep option; if --sep is not specified, the default\n"; 
    print "     separator \"$sepDefault\" (without the quotes) will be used.\n";
    print "  8. The subfield specification options are -a, -f, -g, and -s.\n";      
    print "  9. If no subfield specification options are given, the pathway field\n";
    print "     consists of the pathway id, and each gene field consist of the gene\n";
    print "     id.\n";
    print " 10. If the --printscores option is specified, the pathway field consists\n";
    print "     of two subfields, the pathway id and the AUC; and each gene field\n";
    print "     consists of three subfields, the gene id, the Q/E/N flag, and the\n";
    print "     score.\n";
    print " 11. Otherwise, --printscores was not specified, and at least one of -a,\n";
    print "     -f, -g, or -s was specified.\n";
    print "     a. The -a option causes the AUC to appear in the pathway field, as the\n";
    print "        second subfield following the pathway id.\n";
    print "     b. The -f option causes the Q/E/N flag to appear as a subfield of the\n";
    print "        gene field.\n";
    print "     c. The -g option causes the gene id to appear as a subfield of the\n";
    print "        gene field.\n";
    print "     d. The -s option causes the score to appear as a subfield of the\n";
    print "        gene field.\n";
    print "     e. The relative order of the -f, -g, and -s options on the command\n";
    print "        line indicates the ordering of the gene field subfields.\n";
    print " 12. The Q/E/N flag is a single-letter flag indicating whether the gene is\n";
    print "     a query (and expected) gene, a (non-query) expected gene, or neither a\n";
    print "     query nor an expected gene.\n";
    print " 13. The AUC is printed as a percentage with one decimal place. A score is\n";
    print "     multiplied by 1000 and rounded to an integer.\n";
    print " 14. Only the first instance of each of -f, -g, and -s are recognized;\n";
    print "     any subsequent specifications of such options are ignored.\n";
    print " 15. The -a, -f, -g, and -s options are all overridden by --printscores.\n";
    print " 16. The -a, -f, -g, and -s options cannot be merged (e.g., -gfs will not\n";
    print "     be recognized).\n\n";
    print "Usage Notes\n";
    print "-----------\n";
    print "  1. Specify the --printscores option if a score file is being generated for\n";
    print "     input to the mergescores.pl program.\n\n";
    print "Command Line Options\n";
    print "--------------------\n";
    print "A command line option may be introduced with either a single dash or double\n"; 
    print "dash (i.e., \"-\" or \"--\").\n\n";
    print "--a (or -a)\n";
    print "  Print AUC as part of the pathway field.\n";
    print "--compendium <filename>\n";
    print "  Specifies the name of a cluster compendium file.\n";
    print "  If this option is specified more than once, the last occurrence silently\n";
    print "  takes precedence over the others.\n";
    print "--datalinecomments\n";
    print "  Specifies that the first \"#\" character in a data line introduces a comment\n";
    print "  that terminates at the end of the line.\n";
    print "  If not specified, a \"#\" character in a data line is not interpreted as\n";
    print "  introducing a comment.\n";
    print "--expected <filename>\n";
    print "  Specifies the name of a pathway compendium file.\n";
    print "  Each query has a query id. The pathway gene set in the pathway\n";
    print "  compendium file whose pathway id matches the query id is used as the\n";
    print "  expected set.\n";
    print "  If not specified: the query set is used as the expected set.\n";
    print "  If this option is specified more than once, the last occurrence silently\n";
    print "  takes precedence over the others.\n";
    print "--f (or -f)\n";
    print "  Print Q/E/N flag as part of the gene field.\n";
    print "  Position relative to --g and --s options specifies the position of the\n";
    print "  flag subfield within the gene field.\n";
    print "--fb_iterations <integer>\n";
    print "  Number of feedback iterations.\n";
    print "  If not specified, no feedback iterations are performed.\n";
    print "--fb_outfile <filename>\n";
    print "  Name of output file for relevance feedback output.\n";
    print "  If not specified, no relevance feedback output is generated.\n";
    print "  This option is not yet implemented.\n";
    print "--fb_pseudosize <integer>\n";
    print "  Indicates pseudo-relevance feedback, and the number of top scores to\n";
    print "  feed back.\n";
    print "  If not specified, pseudo-relevance feedback is not performed.\n";
    print "  This option is not yet implemented.\n";
    print "--g (or -g)\n";
    print "  Print gene id as part of the gene field.\n";
    print "  Position relative to --f and --s options specifies the position of the\n";
    print "  gene id subfield within the gene field.\n";
    print "--genome <filename>\n";
    print "  Specifies the name of a genome file.\n";
    print "  If specified, the genes listed in <filename> are used as the genome\n";
    print "  of the species.\n";
    print "  If not specified, the genome is derived from the cluster compendium\n";
    print "  (the union of all the gene ids in all the clusters is used as the genome).\n";
    print "--help (or -h)\n";
    print "  Print help information and exit.\n";
    print "--incquery\n";
    print "  If specified: query genes are included in the results.\n";
    print "  If not specified: query genes are not included in the results\n";
    print "  unless an expected file is not specified, in which case query genes\n";
    print "  are included in the results.\n";
    print "--noavgrank\n";
    print "  For genes with equal scores, do *not* assign all the average rank.\n";
    print "  Instead, assign each gene the next integer rank in an unspecified order.\n";
    print "  The purpose of this option is to preserve previous behavior for testing.\n";
    print "  and comparison purposes.\n";
    print "  This option is not yet implemented.\n";
    print "--noincludecomments\n";
    print "  Specifies that comment lines from input files are not to be copied to\n";
    print "  the output.\n";
    print "  If not specified, comments are copied from input to output.\n";
    print "--noidpound\n";
    print "  Specifies that pound characters in a gene id are to be processed\n";
    print "  as follows:\n";
    print "     id#...                      keep id only\n";
    print "     id, #...                    keep id only\n";
    print "     INTERGENIC CONTROL #...     delete entire id\n";
    print "     INTERGENIC_CONTROL #...     delete entire id\n";
    print "  If not specified, pound characters in a gene id are not processed.\n";
    print "--nocasenorm\n";
    print "  Specifies that case normalization (i.e., shifting all gene ids to upper case)\n";
    print "  is *not* performed.\n";
    print "  If not specified, case normalization (i.e., shifting all gene ids to upper case)\n";
    print "  is performed.\n";
    print "--printscores\n";
    print "  If the --printscores option is specified, the pathway field consists\n";
    print "  of two subfields, the pathway id and the AUC; and each gene field\n";
    print "  consists of three subfields, the gene id, the Q/E/N flag, and the\n";
    print "  score.\n";
    print "  If not specified: either default printing or user-specified formatting\n";
    print "  (controlled by -a, -f, -g, and -s) will be in effect.\n";
    print "  Specify the --printscores option if a score file is being generated for\n";
    print "  input to the mergescores.pl program.\n";
    print "--quiet (or -q)\n";
    print "  Specifies quiet mode for output.\n";
    print "  If specified, informational comments (such as version information and specified\n";
    print "  options) do not appear in the output.\n";
    print "  If not specified, informational comments do appear in the output.\n";
    print "--s (or -s)\n";
    print "  Print score as part of the gene field.\n";
    print "  Position relative to --f and --g options specifies the position of the\n";
    print "  score subfield within the gene field.\n";
    print "--scorefile <filename>\n";
    print "  Specifies the name for the output score file.\n";
    print "  If not specified, no score file is produced.\n";
    print "--scoremethod <integer>\n";
    print "  If specified: the specified scoring method is used.\n";
    print "  If not specified: method 0 (the default scoring method) is used.\n";
    print "  If this option is specified more than once, the last occurrence silently\n";
    print "  takes precedence over the others.\n";
    print "--sep <subfield separator>\n";
    print "  Specify the subfield separator string used to separate output subfields.\n";
    print "  If specified: use the specified subfield separator string as the\n";
    print "  subfield separator. The value can consist of zero or more characters (to\n";
    print "  specify zero characters, use adjacent quotation marks \"\" as the value).\n";
    print "  If not specified: use default subfield separator \"$sepDefault\".\n";
    print "  If this option is specified more than once, the last occurrence silently\n";
    print "  takes precedence over the others.\n";
    print "--testout <filename>\n";
    print "  Specifies the name of a test output file.\n";
    print "  If this option is specified more than once, the last occurrence silently\n";
    print "  takes precedence over the others.\n";
    print "--verbose (or -v)\n";
    print "  Print verbose information. Not currently used.\n\n";
    print "Please cite the following article when using ClueGene:\n";
    print "  Ng DM, Woehrmann MH, Stuart JM.\n";
    print "  Recommending Pathway Genes Using a Compendium of Clustering Solutions.\n";
    print "  Pacific Symposium on Biocomputing 12:379-390(2007).\n";
    print "  Article: http://psb.stanford.edu/psb-online/proceedings/psb07/ng.pdf\n";
    print "  Online Supplement: http://sysbio.soe.ucsc.edu/cluegene/psb07/\n\n";
    
    return $ERR_NOERROR;
}


######################
# Begin main program #
######################

# data structure that contains all of the clusters for all of the datasets
# an array of hashes of hashes:
#   for $clusters[<dataset>]{<cluster_id>}{<gene>}
#       <dataset> is an integer giving the dataset number; dataset numbers
#           are assigned sequentially starting from 0
#       <cluster_id> is a string specifying the cluster id
#       <gene> is a string specifying the gene id 
#   the value is 1; in general, this data structure is used by testing
#       for existence of the dataset, cluster, and gene
my @clusters;

# hash of the genome (i.e., union of the genes in all the datasets): 
# key is the gene name, value is 1
my %genome;

# hash of the expected sets: 
# key is the pathway id, value is a reference to a hash of the gene ids
my %expectedset;

# if true, include query genes in result output
my $includeQueryGenes = 0;

# if true, write verbose trace information to the standard error
my $verbose = 0;

# if true, help information requested
my $print_help = 0;

# if true, print scores, AUC, and flags in the output
my $printScores = 0;

# specifies the scoring method to use
my $scoremethod = 0;

# default scoring method
my $scoremethodDefault = 7;

# name of a compendium file
my $compendium_file = "";

# name of the score file
my $score_file = "";

# name of test output file
my $testout_file = "";

# assign average rank to genes with same scores, by default
my $noavgrank = 0;

# if true, allow an embedded "#" in a data line to introduce a comment
my $datalinecomments = 0; 

# if true, do not propagate comments from input to output
my $noincludecomments = 0; 

# if true, quiet mode printing (i.e., no informational comments)
my $quiet = 0;

# name of expected set file
my $expected_file = "";

# name of external genome file
my $genome_file = "";

# if true, do not normalize case (to upper) of gene ids
my $noCaseNorm = 0;

# if true, special handling of pound characters in gene ids
my $noidpound = 0;

# average precision of the query genes
my $avgPrec = 0;

#--------------------#
# relevance feedback #
#--------------------#

# output file for relevance feedback output; empty string => no output
my $fb_outfile = "";

# number of feedback iterations; 1 iteration means no feedback
my $fb_iterations = 1;

# pseudo-relevance feedback, number of results to feed back
my $fb_pseudosize = 0;
    

#---------------------------------------#
# gene subfield specification variables #
#---------------------------------------#

# subfield separator string
my $sep;

# default subfield separator string
my $sepDefault = "@";

# if true, at least one of -a, -f, -g, or -s was specified
my $fancyOutput = 0;

# if true, the -a option was specified
my $a_opt = 0;

# indicates relative position of -f, -g, and -s option on the command line.
# value 0 indicates flag was not specified.
# positive value 1, 2, or 3 indicates whether the flag was first, second,
# or third.
my $f_inx = 0;
my $g_inx = 0;
my $s_inx = 0;

# index of the most recently encountered -f, -g, or -s option
my $ss_inx = 0;


#==============================#
# Process command line options #
#==============================#

# repeat for each command line argument
for (my $i = 0; $i < @ARGV; $i++) {
    my $arg = @ARGV[$i];
    
    if ($arg eq "--compendium" || $arg eq "-compendium")
    {
        if ($i+1 >= @ARGV)
        {
            print STDERR "Warning: command line option \"$arg\" is missing its required argument.\n";
        }
        else
        {
            $compendium_file = @ARGV[++$i];
        }
    }
    elsif ($arg eq "--datalinecomments" || $arg eq "-datalinecomments")
    {
        $datalinecomments = 1;
    }
    elsif ($arg eq "--noincludecomments" || $arg eq "-noincludecomments")
    {
        $noincludecomments = 1;
    }
    elsif ($arg eq "--incquery" || $arg eq "-incquery")
    {
        $includeQueryGenes = 1;
    }
    elsif ($arg eq "--nocasenorm" || $arg eq "-nocasenorm")
    {
        $noCaseNorm = 1;
    }
    elsif ($arg eq "--noidpound" || $arg eq "-noidpound")
    {
        $noidpound = 1;
    }
    elsif ($arg eq "--fb_outfile" || $arg eq "-fb_outfile")
    {
        if ($i+1 >= @ARGV)
        {
            print STDERR "Warning: command line option \"$arg\" is missing its required argument.\n";
        }
        else
        {
            $fb_outfile = @ARGV[++$i];
        }
    }
    elsif ($arg eq "--fb_iterations" || $arg eq "-fb_iterations")
    {
        if ($i+1 >= @ARGV)
        {
            print STDERR "Warning: command line option \"$arg\" is missing its required argument.\n";
        }
        else
        {
            $fb_iterations = @ARGV[++$i];
        }
    }
    elsif ($arg eq "--fb_pseudosize" || $arg eq "-fb_pseudosize")
    {
        if ($i+1 >= @ARGV)
        {
            print STDERR "Warning: command line option \"$arg\" is missing its required argument.\n";
        }
        else
        {
            $fb_pseudosize = @ARGV[++$i];
        }
    }
    elsif ($arg eq "--testout" || $arg eq "-testout")
    {
        if ($i+1 >= @ARGV)
        {
            print STDERR "Warning: command line option \"$arg\" is missing its required argument.\n";
        }
        else
        {
            $testout_file = @ARGV[++$i];
        }
    }
    elsif ($arg eq "--scorefile" || $arg eq "-scorefile")
    {
        if ($i+1 >= @ARGV)
        {
            print STDERR "Warning: command line option \"$arg\" is missing its required argument.\n";
        }
        else
        {
            $score_file = @ARGV[++$i];
        }
    }
    elsif ($arg eq "--expected" || $arg eq "-expected")
    {
        if ($i+1 >= @ARGV)
        {
            print STDERR "Warning: command line option \"$arg\" is missing its required argument.\n";
        }
        else
        {
            $expected_file = @ARGV[++$i];
        }
    }
    elsif ($arg eq "--genome" || $arg eq "-genome")
    {
        if ($i+1 >= @ARGV)
        {
            print STDERR "Warning: command line option \"$arg\" is missing its required argument.\n";
        }
        else
        {
            $genome_file = @ARGV[++$i];
        }
    }
    elsif ($arg eq "--scoremethod" || $arg eq "-scoremethod")
    {
        if ($i+1 >= @ARGV)
        {
            print STDERR "Warning: command line option \"$arg\" is missing its required argument.\n";
        }
        else
        {
            $scoremethod = @ARGV[++$i];
        }
    }
    elsif ($arg eq "--sep" || $arg eq "-sep")
    {
        if ($i+1 >= @ARGV)
        {
            print STDERR "Warning: command line option \"$arg\" is missing its required argument.\n";
        }
        else
        {
            $sep = @ARGV[++$i];
        }
    }
    elsif ($arg eq "--a" || $arg eq "-a")
    {
        $a_opt = 1;
        $fancyOutput = 1;
    }
    elsif ($arg eq "--f" || $arg eq "-f")
    {
        if ($f_inx <= 0)
        {
            $f_inx = ++$ss_inx;
            $fancyOutput = 1;
        }
        else
        {
            print STDERR "Warning: command line option \"$arg\" was already specified.\n";
        }
    }
    elsif ($arg eq "--g" || $arg eq "-g")
    {
        if ($g_inx <= 0)
        {
            $g_inx = ++$ss_inx;
            $fancyOutput = 1;
        }
        else
        {
            print STDERR "Warning: command line option \"$arg\" was already specified.\n";
        }
    }
    elsif ($arg eq "--s" || $arg eq "-s")
    {
        if ($s_inx <= 0)
        {
            $s_inx = ++$ss_inx;
            $fancyOutput = 1;
        }
        else
        {
            print STDERR "Warning: command line option \"$arg\" was already specified.\n";
        }
    }
    elsif ($arg eq "--printscores" || $arg eq "-printscores")
    {
        $printScores = 1;
    }
    elsif ($arg eq "--noavgrank" || $arg eq "-noavgrank")
    {
        $noavgrank = 1;
    }
    elsif ($arg eq "--q" || $arg eq "-q" || $arg eq "--quiet" || $arg eq "-quiet")
    {
        $quiet = 1;
    }
    elsif ($arg eq "--v" || $arg eq "-v" || $arg eq "--verbose" || $arg eq "-verbose")
    {
        $verbose = 1;
    }
    elsif ($arg eq "--h" || $arg eq "-h" || $arg eq "--help" || $arg eq "-help")
    {
        $print_help = 1;
    }
    else
    {
        # unrecognized option
        print STDERR "Warning: command line option \"$arg\" is not recognized.\n";
    }
}


# use default separator character if no --sep option (or no argument) was specified
if (!defined $sep)
{
    $sep = $sepDefault;
}

if ($print_help)
{
    cg_printHelpInfo($sepDefault, $sep);
    exit;
}

# use default scoring method if scoring method specified as 0
$scoremethod = $scoremethodDefault if $scoremethod == 0;

# define separators for gene subfield printing
my ($sep1, $sep2) = ("", "");
$sep1 = $sep if $ss_inx >= 2;   # first separator needed for 2 or more subfields
$sep2 = $sep if $ss_inx >= 3;   # second separator needed for 3 or more subfields

# gene subfield strings (set later as appropriate)
my @g_subfield = ("", "", "", "");

# open score file for output if specified
if ($score_file ne "")
{
    if (!open(SCORE, ">$score_file"))
    {
        # an error was detected
        print STDERR "Warning: could not open score file \"$score_file\".\n";
        $score_file = "";
    }
}

# open test output file for output if specified
if ($testout_file ne "")
{
    if (!open(TESTOUT, ">$testout_file"))
    {
        # an error was detected
        print STDERR "Warning: could not open test output file \"$testout_file\".\n";
        $testout_file = "";
    }
}

if ($expected_file eq "")
{
    $includeQueryGenes = 1;
}


#-----------------------------------------#
# print version and execution information #
#-----------------------------------------#

if (!$quiet)
{
    # print version and execution information
    print "# ClueGene: cg.pl version $cgversion.\n";
    print strftime "# Generated on %a %Y-%m-%d %H:%M:%S %Z.\n", localtime;
    print "# Input: Query file version $queryfileversion.\n";
    print "# Input: Cluster compendium file version $ccfileversion.\n";
    print "# Input: Pathway compendium file version $pathwaycompendiumfileversion.\n";
    print "# Input: Genome file version $genomefileversion.\n";
    print "# Output: Rank file version $rankfileversion.\n";
    print "# Output: Score file version $scorefileversion.\n";
    print "# Options:\n";
    print "#   a=$a_opt.\n";
    print "#   compendium=$compendium_file.\n";
    print "#   datalinecomments=$datalinecomments.\n";
    print "#   expected=$expected_file.\n";
    print "#   f=$f_inx.\n";
    print "#   fb_iterations=$fb_iterations.\n";
    print "#   fb_outfile=$fb_outfile.\n";
    print "#   fb_pseudosize=$fb_pseudosize.\n";
    print "#   g=$g_inx.\n";
    print "#   genome=$genome_file.\n";
    print "#   incquery=$includeQueryGenes.\n";
    print "#   nocasenorm=$noCaseNorm.\n";
    print "#   noavgrank=$noavgrank.\n";
    print "#   noincludecomments=$noincludecomments.\n";
    print "#   noidpound=$noidpound.\n";
    print "#   printscores=$printScores.\n";
    print "#   quiet=$quiet.\n";
    print "#   s=$s_inx.\n";
    print "#   scorefile=$score_file.\n";
    print "#   scoremethod=$scoremethod.\n";
    print "#   sep=$sep.\n";
    print "#   testout=$testout_file.\n";
    print "#   verbose=$verbose.\n";
}


#========================================#
# Open feedback output file if specified #
#========================================#

if ($fb_outfile ne "")
{
    open(FB, ">$fb_outfile") ||
        die "Could not open feedback output file $fb_outfile\n";
}


#=============================================#
# Input genome from genome file, if specified #
#=============================================#

my $err;
if ($genome_file ne "")
{
    $err = read_genome(
                $genome_file,
                $noincludecomments,
                $datalinecomments,
                $noCaseNorm,
                \%genome,
                $noidpound);
    
    if ($err == $ERR_FILEOPEN)
    {
        die "Error: cannot open genome file \"$genome_file\"";
    }
}


#===========================================================#
# Input cluster data and dataset names from compendium file #
#===========================================================#
    
# directory names for the Saccharomyces cerevisiae datasets
my @datasets;

$err = read_compendium(
            $compendium_file,
            $noincludecomments,
            $datalinecomments,
            $noCaseNorm,
            $genome_file ne "", # true => externally defined genome
            \@clusters,
            \%genome,
            \@datasets,
            $noidpound);

if ($err == $ERR_FILEOPEN)
{
    die "Error: cannot open cluster compendium file \"$compendium_file\"";
}
elsif ($err == $ERR_DATAFORMAT)
{
    die "Error: unexpected input in cluster compendium file \"$compendium_file\": $_\n";
}
elsif ($err == $ERR_NODATASETS)
{
    die "Error: no datasets were specified in cluster compendium file \"$compendium_file\"";
}

# print dataset names
print "# dataset names (from compendium):\n#   @datasets\n" if (!$quiet);


#=====================================#
# read the expected set, if specified #
#=====================================#

if ($expected_file ne "")
{
    # read the expected set
    my $err = read_expected($expected_file,
                            $noincludecomments,
                            $datalinecomments,
                            $noCaseNorm,
                            \%expectedset,
                            $noidpound);
    
    if ($err == $ERR_FILEOPEN)
    {
        die "Error: cannot open expected set file \"$expected_file\"";
    }
    elsif ($err != $ERR_NOERROR)
    {
        die "Error: unexpected return code $err from read_expected";
    }
}


#========================#
# process each query set #
#========================#

# repeat for each query set
while (1)
{
    #-------------------#
    # Get the query set #
    #-------------------#
    
    my $queries;        # string representation of the genes of the query set
    my @queries;        # array representation of the genes of the query set
    my %queries;        # hash representation of the genes of the query set
    my $pathway_id;     # the pathway id of the query set
    
    # read the query set as a string, array, and hash
    my $err = cg_readQuerySet(\%genome,
                              $noincludecomments,
                              $datalinecomments,
                              $noCaseNorm,
                              \$queries,
                              \@queries,
                              \%queries,
                              \$pathway_id,
                              $noidpound);
    
    if ($err != $ERR_NOERROR)
    {
        last if ($err == $ERR_EOF);
        die "Error: unexpected return code $err from cg_readSimpleQuerySet";
    }


    #----------------------#
    # get the expected set #
    #----------------------#
    
    my $expected;
    my %expected;
    my $pwid;       # pathway id without query index
    if ($expected_file ne "")
    {
        # get the pathway id (i.e., remove the query index)
        if ($pathway_id =~ /$sep/)
        {
            # the pathway id contains a query index separator character
            $pathway_id =~ /^(.+)$sep/;
            $pwid = $1;
        }
        else
        {
            $pwid = $pathway_id;
        }
    
        # get the expected set from the expected set file
        if (defined $expectedset{$pwid})
        {
            %expected = %{$expectedset{$pwid}};
            my @expected = sort keys %expected;
            $expected = "@expected";
        }
        else
        {
            # pathway not found in the expected set file
            # use the query set as the expected set 
            $expected = $queries;
            %expected = %queries;
            print STDERR "Warning: pathway \"$pwid\" not found in expected set file, using query set as the expected set.\n";
        }
    }
    else
    {
        # the expected set is the same as the query set 
        $expected = $queries;
        %expected = %queries;
    }
    
    if(0)
    {
        # for testing
        foreach my $g (keys %expected)
        {
            if (defined $genome{$g})
            {
                print "$g is in the genome\n";
            }
            else
            {
                print "$g is not in the genome\n";
            }
        }
        print "queries=$queries\nexpected=$expected";
    }
    
    
    #--------------------------------------------------------#
    # Score the query genes and compute precision-recall AUC #
    #--------------------------------------------------------#
    
    my %ccscore_g;  # co-clustering score for each gene
    my %ccscore_gd; # co-clustering score for each gene, by dataset
    my %numclu_gd;  # number of clusters contributing to each gene's score, by dataset
    my $pathway_size;
    my $area;
    
    # initialize query set for feedback
    my @fbqueries = @queries;
    my %fbqueries;
    foreach my $fbq (@fbqueries)
    {
        $fbqueries{$fbq} = 1;
    }
    
    # repeat for feedback
    for (my $fb_i = 0; $fb_i < $fb_iterations; $fb_i++)
    {
        # score the query
        my $err = cg_score($scoremethod,
                           \@fbqueries,
                           \@datasets,
                           \@clusters,
                           \%genome,
                           \%ccscore_g,
                           \%ccscore_gd,
                           \%numclu_gd);
                           
        if ($err != $ERR_NOERROR)
        {
            if ($err == $ERR_INVALIDSCOREMETHOD)
            {
                die "Invalid score method $scoremethod";
            }
            else
            {
                die "Error: unexpected return code $err from cg_score";
            }
        }
        
        # compute average precision of the query genes
        my %rank_g = ();
        cg_assignRanks(\%ccscore_g, \%rank_g);
        my %rank_queries = ();
		foreach my $fbq (@fbqueries)
		{
			# only include a query gene if it has a rank
			$rank_queries{$fbq} = $rank_g{$fbq} if (defined $rank_g{$fbq});
		}
        $avgPrec = cg_averagePrecision(\%rank_queries);
        
        # compute AUC
        $area = cg_auc($includeQueryGenes,
                          \%fbqueries,
                          \%expected,
                          \%ccscore_g,
                          \$pathway_size);
                          
        if ($fb_outfile ne "")
        {
            print FB "\t" if ($fb_i > 0);
            print FB "$area";
        }
        
        # update query set for next iteration
        undef @fbqueries;
        undef %fbqueries;
        my @scored_order = (sort {$ccscore_g{$b} <=> $ccscore_g{$a}} (keys %ccscore_g));
        for (my $i = 0; $i < $fb_pseudosize; $i++)
        {
            # make sure have not exceeded number of genes
            last if (!defined $scored_order[$i]);
            
            $fbqueries[$i] = $scored_order[$i];
            $fbqueries{$fbqueries[$i]} = 1;
        }
        
    }
    if ($fb_outfile ne "")
    {
        print FB "\n";
    }
                      
                      
    #---------------------#
    # Print the rank file #
    #---------------------#

    cg_printRankFile($includeQueryGenes,
                     $pathway_id,
                     scalar keys %genome,   # genome size
                     \%queries,
                     \%expected,
                     \%ccscore_g);
    
    
    #------------------------#
    # Print the result genes #
    #------------------------#
    
    if ($score_file ne "")
    {
        if ($printScores)
        {
            # print: pathway id with AUC, and gene ids with flag and score
        
            # print pathway id and AUC (reported as a percentage of maximum)
            printf SCORE "$pathway_id$sep%04.1f", $area * 100 if ($printScores);
            print SCORE "\t$avgPrec" if ($printScores);
            
            # repeat for each gene in order of decreasing score
            for my $gene (sort {$ccscore_g{$b} <=> $ccscore_g{$a}} (keys %ccscore_g)) 
            {
                if (defined $queries{$gene} && defined $expected{$gene})
                {
                    # this is a gene in the query set, and it is in the expected set
                    # skip if query genes are not to be included in the results
                    next if !$includeQueryGenes;
                }
                
                # tab-separate from previous field, and print gene id and annotation
                print SCORE "\t", cg_annotateGeneDefault($gene, \%ccscore_g, \%queries, \%expected,
                                                   $printScores, $sep);
            }
            
            print SCORE "\n"; 
        }
        elsif (!$fancyOutput)
        {
            # print: pathway id and gene ids
            print SCORE "$pathway_id\t";
            print SCORE "$avgPrec\t" if ($printScores);
            print SCORE join "\t", (sort {$ccscore_g{$b} <=> $ccscore_g{$a}} (keys %ccscore_g));
            print SCORE "\n";
        }
        else
        {
            # print: user-specified format
            
            print SCORE "$pathway_id";
            
            # print AUC, reported as a percentage of maximum
            printf SCORE "$sep%04.1f", $area * 100 if $a_opt;
            
			print SCORE "\t$avgPrec" if ($printScores);      
			
            # print the gene fields if at least one subfield is non-empty
            if ($f_inx != 0 || $g_inx != 0 || $s_inx != 0)
            {
                # repeat for each gene in order of decreasing score
                for my $gene (sort {$ccscore_g{$b} <=> $ccscore_g{$a}} (keys %ccscore_g)) 
                {
                    if (defined $queries{$gene} && defined $expected{$gene})
                    {
                        # this is a gene in the query set, and it is in the expected set
                        # skip if query genes are not to be included in the results
                        next if !$includeQueryGenes;
                    }
                    
                    # An index value 0 indicates the subfield is not to be printed.
                    # Implementation: a subfield index of 0 assigns the corresponding
                    # value to $g_subfield[0], which is never printed.
                    
                    # set the gene and score subfields
                    $g_subfield[$g_inx] = $gene;
                    $g_subfield[$s_inx] = int($ccscore_g{$gene}*1000 + 0.5);
                    
                    # set the flag subfield
                    if (defined $queries{$gene} && defined $expected{$gene}) 
                    {
                        $g_subfield[$f_inx] = "Q";
                    } 
                    elsif (defined $expected{$gene}) 
                    {
                        $g_subfield[$f_inx] = "E";
                    }
                    else
                    {
                        $g_subfield[$f_inx] = "N";
                    }
                            
                    # tab-separate from previous field, and print gene field
                    print SCORE "\t", $g_subfield[1], $sep1, $g_subfield[2], $sep2, $g_subfield[3];
                }
            }
            
            print SCORE "\n";
        }
    }
}   # while(1) for each query set
