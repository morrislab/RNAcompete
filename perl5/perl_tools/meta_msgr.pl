#!/usr/bin/perl

# Gene scoring system using both positive and negative input gene sets.  
# Determines the overlap of the positive and negative input gene sets with known pathways.  
# Rewards genes for overlap with pathways enriched in the positive gene set, and penalizes genes 
# for overlap with pathways enriched in the negative gene set.  
# Returns gene scores and the Wilcoxon rank-sum statistic measuring the separation of the positive and negative gene scores.

use strict;
use Getopt::Long;
use Pod::Usage;

require "$ENV{MYPERLDIR}/lib/libstats.pl";

# file linking locus links with gene name and description.  used when reporting scores
my $gene_info_file = "LL_gene_desc.hs";

# cutoff is the minimum z-score used to determine if a pathway has a significant enrichment for either the pos or neg pathway.
my $cutoff = 3;
# filtered cores file.
my $matrix = "cores_filtered_75%query.nonneg.tab";

# w: output wilcoxon statistic.  optional, but at least one of w and l must be selected
# l: output list of scored genes.  optional, but at least one of w and l must be selected
# o: prefix of file for output.  ".wilcoxon" added for wilcoxon information, ".scores" added for scored genes
my $wilcoxon;
my $scores;
my $out;

# positive and negative pathways (if not running in batch)
my $pos;
my $neg;

# run in batch mode
my $batch;

# compact results for batch mode
my $compact;

# database with pathways
# format: pathwayName \t gene1 \t gene2 \t ..., etc.
my $database = "/projects/sysbio/map/Data/GeneSets/Go/Human/lists_t.tab";

# flag for independent mode: use only the positive pathway as basis for scoring genes
my $independent;

GetOptions
(
    "m=s" => \$matrix,
    "b=s" => \$batch,
    "p=s" => \$pos,
    "n=s" => \$neg,
    "o=s" => \$out,
    "g=s" => \$gene_info_file,
    "w" => \$wilcoxon,
    "s" => \$scores,
    "d=s" => \$database,
    "c" => \$compact,
    "i" => \$independent,
    "help" => sub {pod2usage("verbose" => 1);},
    "man" => sub {pod2usage("verbose" => 2);},
) or pod2usage("verbose" => 0);
pod2usage("verbose" => 0) if (!(defined($out)));

##########
#
# deal with flags
#
##########

unless (($batch && !($pos) && !($neg)) || (($pos) && ($neg) && !($batch)))
{
    die ("Either run in batch (-b) or indicate positive (-p) and negative (-n) sets\n");
}

if ($batch)
{
    unless ($database)
    {
	die("Input a pathway database file with -d\n");
    }
}

if ($independent)
{
    print STDERR "Running in independent mode (only positive gene set used in scoring)...\n";
}

if ($wilcoxon)
{
    print STDERR "Returning wilcoxon statistic\n";
}
if ($scores)
{
    print STDERR "Returning all gene scores\n";
}
if ($compact)
{
    print STDERR "Returning compact output\n";
}
if (!($wilcoxon) && !($scores) && !($compact))
{
    die("Use \"w\" and\/or \"s\" flag to indicate output type.  OR, use \"c\" flag for compact output.\n");
}
unless ($out)
{
    die("Need a prefix for the output files\n");
}

print STDERR "Scores sorted in descending order\n";

##########
#
# write all wilcoxon statistics to one file.
#
##########
my $wOut = $out . ".wilcoxon";
if ($wilcoxon)
{
    open (WOUT, ">$wOut") or die ("Can't create $wOut\n");
}

#########
#
# open file for compact output
#
#########
if ($compact)
{
    my $cOut = $out;
    open (COUT, ">$cOut") or die ("Can't create $cOut\n");
}


##########
#
# get gene information for score output
#
##########
my (%LL2gene, %LL2desc);
if ($scores)
{
    my ($LL, $gene, $desc);
    open (GENEINFOFILE, $gene_info_file) or die ("Can't open $gene_info_file\n");
    while (<GENEINFOFILE>)
    {
	chomp;
	($LL, $gene, $desc) = split(/\t/, $_);
	$LL2gene{$LL} = $gene;
	$LL2desc{$LL} = $desc;
    }
    close GENEINFOFILE;
}

##########
#
# get data from matrix file
#
##########
my (@pathways, @pathSizes, @line, $LL, %LLtoPathData, $line);
my $totalGenes = 0;
my @allGenes;
my $allGenes=";";
my ($maxInput, $minInput);
print STDERR "Reading in matrix $matrix...\n";
open (MATRIX, $matrix) or die ("Can't open $matrix\n");
while (<MATRIX>)
{
    chomp;
    if (/^Gene/)
    {
	(undef, @pathways) = split(/\t/, $_);
	# initialize pathSizes array
	for (my $l=0; $l<=$#pathways; $l++)
	{
	    $pathSizes[$l] = 0;
	}
    }
    else
    {
	$totalGenes++;
	($LL, $line) = split(/\t/, $_, 2);
	push(@allGenes, $LL);
	$allGenes .= "$LL;";
	$LLtoPathData{$LL} = $line;
	@line = split(/\t/, $line);
	if (defined($maxInput))
	{
	    push(@line, $maxInput);
	}
	if (defined($minInput))
	{
	    push(@line, $minInput);
        }
	# print STDERR join(";", @line), "\n";
	$maxInput = arraymax(\@line);
	$minInput = arraymin(\@line);
    }
}
close MATRIX;


##########
#
# Convert data from matrix file so all data values are between 0 and 1
# Also get  data for pathway sizes:
# **anything with converted value of 0 IS NOT in the pathway
# **anything with with a positive converted value IS in the pathway
# 
##########
print STDERR "min matrix value: $minInput\n";
print STDERR "max matrix value: $maxInput\n";
print STDERR "converting matrix...\n";

my (%convertedData, @converted);
foreach my $LL (sort(keys(%LLtoPathData)))
{
    my @data = split(/\t/, $LLtoPathData{$LL});
    {  
	for (my $i=0; $i<=$#pathways; $i++)
	{
	    $converted[$i] = ($data[$i] - $minInput)/($maxInput-$minInput);
	    unless ($converted[$i] == 0)
	    {
		$pathSizes[$i]++;
	    }
	}
	$convertedData{$LL} = join("\t", @converted);
    }
}

##########
#
# get the positive and negative sets
#
##########
my @sets_pos;
my @sets_neg;
my %dbPathToGenes;
my $batchPaths = ";";
if ($batch)
{
    ###
    # read in the positive and negative pathways
    ###
    open (BATCH, $batch) or die ("Can't open $batch\n");
    while (<BATCH>)
    {
	chomp;
	(my $posPathway, my $negPathway) = split(/\t/, $_);
	push(@sets_pos, $posPathway);
	push(@sets_neg, $negPathway);
	$batchPaths .= "$posPathway;$negPathway;";
    }
    close BATCH;

    ###
    # get the necessary pathways from the database file
    ###
    open (DATABASE, $database) or die ("Can't open $database\n");
    my ($pathway, $genes, @match_pathway, $match_pathway);
    while (<DATABASE>)
    {
	chomp;
	($pathway, $genes) = split(/\t/, $_, 2);
	my @pathway = split(//, $pathway);
	###
	# there are some "[" and "]" in /projects/sysbio/map/Data/GeneSets/GO/Human/lists_t.tab.
	# add a \ in front so perl won't freak out.
	###
	undef @match_pathway;
	foreach my $char (@pathway)
	{
	    if ($char eq "\[")
	    {
		push(@match_pathway, "\\\[");
	    }
	    elsif ($char eq "\]")
	    {
		push(@match_pathway, "\\\]");
	    }
	    else
	    {
		push(@match_pathway, $char);
	    }
	}
	$match_pathway = join("", @match_pathway);
	if ($batchPaths =~ m/;$match_pathway;/)
	{
	    $dbPathToGenes{$pathway} = $genes;
	}
    }
    close DATABASE;
}
else
{
    ###
    # get positive genes
    ###
    open (POS, $pos) or die ("Can't open $pos\n");
    my @posfile;
    while (<POS>)
    {
	chomp;
	unless (/^>/)
	{
	    push(@posfile, $_);
	}
	$dbPathToGenes{$pos} = join("\t", @posfile);
    }
    close POS;

    ###
    # get negative genes
    ###
    open (NEG, $neg) or die ("Can't open $neg\n");
    my @negfile;
    while (<NEG>)
    {
	chomp;
	unless (/^>/)
	{
	    push(@negfile, $_);
	}
	$dbPathToGenes{$neg} = join("\t", @negfile);
    }
    close NEG;

    ###
    # add pathways to @sets_pos and @sets_neg
    ###
    push(@sets_pos, $pos);
    push(@sets_neg, $neg);
}

##########
#
# get score/wilcoxon information for each set of positive and negative pathways!
#
##########
for (my $t=0; $t<=$#sets_pos; $t++)
{
    my $currentPos = $sets_pos[$t];
    my $currentNeg = $sets_neg[$t];
    print STDERR "**Working on pathways: $currentPos\t$currentNeg\n";
    
    ###
    # open score file for writing
    ###
    my $sOut;
    if ($scores)
    {
	$sOut = $out . "." . $currentPos . "_" . $currentNeg . ".scores";
	open (SOUT, ">$sOut") or die ("Can't create $sOut\n");
    }

    #####
    #
    # get positive and negative genes from the database and remove any overlap from the larger set
    #
    #####

    ###
    # get positive genes
    ###
    if (!(defined($dbPathToGenes{$currentPos})))
    {
	print STDERR "Can't find $currentPos in database!\n";
	print STDERR "Skipping pair: $currentPos\t$currentNeg\n";
	next;
    }    
    my $posGenes = ";";
    my @posGenes = split(/\t/, $dbPathToGenes{$currentPos});
    $posGenes .= join(";", @posGenes);
    $posGenes .= ";";
    print STDERR "$currentPos\t$posGenes\n";

    ###
    # get negative genes
    ###
    if (!(defined($dbPathToGenes{$currentNeg})))
    {
	print STDERR "Can't find $currentNeg in database!\n";
	print STDERR "Skipping pair: $currentPos\t$currentNeg\n";
	next;
    }
    my $negGenes = ";";
    my @negGenes = split(/\t/, $dbPathToGenes{$currentNeg});
    $negGenes .= join(";", @negGenes);
    $negGenes .= ";";
    print STDERR "$currentNeg\t$negGenes\n";
    
    ###
    # find any overlapping genes and remove them from the larger set
    ###
    my ($largerSet_pathwayName, $largerSet, $smallerSet, @smallerSet, $overlap);
    $overlap= 0;
    print STDERR "$currentPos has $#posGenes+1 genes\n";
    print STDERR "$currentNeg has $#negGenes+1 genes\n";
    if ($#posGenes > $#negGenes)
    {
	print STDERR "$currentPos has more genes than $currentNeg\n";
	$largerSet = $posGenes;
	$largerSet_pathwayName = $currentPos;
	$smallerSet = $negGenes;
	@smallerSet = @negGenes;
    }
    elsif ($#negGenes > $#posGenes)
    {
	print STDERR "$currentNeg has more genes than $currentPos\n";
	$largerSet = $negGenes;
	$largerSet_pathwayName = $currentNeg;
	$smallerSet = $posGenes;
	@smallerSet = @posGenes;
    }
    else
    {
	print STDERR "$currentPos and $currentNeg are the same size!\n";
	$largerSet = $negGenes;
	$largerSet_pathwayName = $currentNeg;
	$smallerSet = $posGenes;
	@smallerSet = @posGenes;
    }
    foreach my $smaller_set_gene (@smallerSet)
    {
	if ($largerSet =~ m/;$smaller_set_gene;/)
	{
	    $overlap++;
	    $largerSet =~ s/;$smaller_set_gene;/;/;
	}
    }
    # skip this set of positive and negative genes if the two gene sets are identical
    if (($overlap == $#posGenes) && ($overlap == $negGenes))
    {
	print STDERR "$currentPos and $currentNeg have identical gene lists!  Skipping...";
	next;
    }
    print STDERR "$overlap genes in common\n";
    print STDERR "Removing overlapping genes from $largerSet_pathwayName...\n";
    my @largerSet = split(/;/, $largerSet);
    if ($#posGenes > $#negGenes)
    {
	@posGenes = @largerSet;
	$posGenes = $largerSet;
    }
    else
    {
	@negGenes = @largerSet;
	$negGenes = $largerSet;
    }
    print STDERR "$currentPos (filtered): $posGenes\n";
    print STDERR "$currentNeg (filtered): $negGenes\n";

    #####
    #
    # get pathway counts for currentPos and currentNeg
    #
    #####
    
    ###
    # positive genes
    ###
    my @returnedPosGenes;
    # initialize @posPathCounts
    my @posPathCounts;
    for (my $i=0; $i<=$#pathways; $i++)
    {
	$posPathCounts[$i]=0;
    }
    foreach my $gene (@posGenes)
    {
	if ($allGenes =~ m/;$gene;/)
	{
	    push(@returnedPosGenes, $gene);
	    my @data = split(/\t/, $convertedData{$gene});
	    for (my $i=0; $i<=$#pathways; $i++)
	    {
		if ($data[$i] != 0)
		{
		    $posPathCounts[$i]++;
		}
	    }
	}
    }
    #my $numPosGenes = $#posGenes + 1;
    my $numPosGenes = $#returnedPosGenes + 1;
    print STDERR "num returned pos genes: $numPosGenes\n";
    if ($numPosGenes == 0)
    {
	print STDERR "No returned genes for $currentPos!\n";
	print STDERR "Skipping pair: $currentPos\t$currentNeg\n";
	next;
    }
 
    ###
    # negative genes
    ###
    my @returnedNegGenes;
    # initialize @negPathCounts
    my @negPathCounts;
    for (my $i=0; $i<=$#pathways; $i++)
    {
	$negPathCounts[$i]=0;
    }
    foreach my $gene (@negGenes)
    {
	if ($allGenes =~ m/;$gene;/)
	{
	    push(@returnedNegGenes, $_);
	    my @data = split(/\t/, $convertedData{$gene});
	    for (my $i=0; $i<=$#pathways; $i++)
	    {
		if ($data[$i] != 0)
		{
		    $negPathCounts[$i]++;
		}
	    }
	}
    }
    #my $numNegGenes = $#negGenes + 1;
    my $numNegGenes = $#returnedNegGenes + 1;
    print STDERR "num returned neg genes: $numNegGenes\n";
    if ($numNegGenes == 0)
    {
	print STDERR "No returned genes for $currentNeg!\n";
	print STDERR "Skipping pair: $currentPos\t$currentNeg\n";
	next;
    }

    
    ###
    # get binomial score information for pathways
    ###
    my ($z_pos, $mean_pos, $mean_neg, $stddev_pos, $stddev_neg, %z_pos, %z_neg, $z_neg, $score, %score);
    my (%sigPosPathway, %sigNegPathway, @weight);
    for (my $j=0; $j<=$#pathways; $j++)
    {
	$mean_pos = ($pathSizes[$j]/$totalGenes)*$numPosGenes;
	$mean_neg = ($pathSizes[$j]/$totalGenes)*$numNegGenes;
	$stddev_pos = sqrt(($pathSizes[$j]/$totalGenes)*(1-($pathSizes[$j]/$totalGenes))*$numPosGenes);
	$stddev_neg = sqrt(($pathSizes[$j]/$totalGenes)*(1-($pathSizes[$j]/$totalGenes))*$numNegGenes); 
	$z_pos = ($posPathCounts[$j]-$mean_pos)/$stddev_pos;
	$z_neg = ($negPathCounts[$j]-$mean_neg)/$stddev_neg;
	if ($independent)
	{
	    if ($z_pos >= $cutoff)
	    {
		$weight[$j] = 1;
	    }
	    elsif ($z_pos <= -$cutoff)
	    {
		$weight[$j] = -1;
	    }
	}
	else
	{
	    if (($z_pos >= $cutoff) || ($z_pos <= -$cutoff))
	    {
		if (($z_neg >= $cutoff) || ($z_neg <= -$cutoff))
		{
		    print STDERR "normalizing pathway: $pathways[$j]\n";
		    $sigPosPathway{$j} =$z_pos;
		    $sigNegPathway{$j} = $z_neg;
		}
		else
		{
		    $weight[$j] = 1;
		}
	    }
	    else
	    {
		if (($z_neg >= $cutoff) || ($z_neg <= -$cutoff))
		{
		    $weight[$j] = -1;
		}
		else
		{
		    $weight[$j] = 0;
		}
	    }
	}
    }
    
    #####
    #
    # normalized log-ratio stuff for pathways having significant z-scores for both positive and negative input sets
    #
    #####

    unless ($independent)
    {
	###
	# get logratio of overlap for pathways which are significant for both the pos and neg sets.
	###
	my (%logratio, @logratio);
	foreach my $pathwayIndex (sort(keys(%sigPosPathway)))
	{
	    my $logratio = log(($sigPosPathway{$pathwayIndex}/$numPosGenes)/($sigNegPathway{$pathwayIndex}/$numNegGenes))/log(2);
	    push(@logratio, $logratio);
	    $logratio{$pathwayIndex} = $logratio;
	}
	###
	# normalize the log ratios so they fall between -1 and 1.
	###
	my $min = arraymin(\@logratio);
	print STDERR "log ratio min: $min\n";
	my $max = arraymax(\@logratio);
	print STDERR "log ratio max: $max\n";
	my ($normalized);
	###
	# if min=max, give pathways weight of 0.
	# ??? fix this later
	###
	if ($min == $max)
	{
	    foreach my $pathwayIndex (sort(keys(%sigPosPathway)))
	    {
		$weight[$pathwayIndex] = 0;
	    }
	}
	else
	{
	    foreach my $pathwayIndex (sort(keys(%sigPosPathway)))
	    {
		$normalized = 2*(($logratio{$pathwayIndex} - $min)/($max-$min))-1;
		$weight[$pathwayIndex] = $normalized;
	    }
	}
    }

    ###
    #
    # score genes
    #
    ###
    print STDERR "scoring genes...\n";
    my ($LLscore, %LLtoScore, %wScoreCount, @wTies);
    foreach my $LL (@allGenes)
    {
	undef $LLscore;
	my @pathData = split(/\t/, $convertedData{$LL});
	for(my $k=0; $k<=$#pathways; $k++)
	{
	    my $convert;
	    if ($pathData[$k] == 0)
	    {
		$convert = -1;
	    }
	    else 
	    {
		$convert = 1;
	    }
	    $LLscore += $convert*$weight[$k];
	}
	# truncate score after 5 decimal places to avoid floating-point errors
	$LLscore = sprintf("%.5f", $LLscore);
	$LLtoScore{$LL} = $LLscore;
	if (($wilcoxon) || ($compact))
	{
	    if (($posGenes =~ m/;$LL;/) || ($negGenes =~ m/;$LL;/))
	    {
		if (defined($wScoreCount{$LLscore}))
		{
		    $wScoreCount{$LLscore}++;
		}
		else
		{
		    $wScoreCount{$LLscore} = 1;
		}
	    }
	}
    }
    print STDERR "finished scoring genes\n";
    
    ###
    # get wilcoxon ranks for the pos and neg sets of genes
    # print genes in order of descending score.
    ###
    my @sortedLLs = (sort{$LLtoScore{$b} <=> $LLtoScore{$a}} keys(%LLtoScore));

    # count keeps track of the number of genes seen so far
    my $count = 0;
    # wCount keeps track of the number of positive and negative genes seen so far
    my $wCount = 0;
    # wRank is the wilcoxon rank for the positive and negative genes
    my $wRank;
    # rank is the rank reported for the scored genes
    my $rank;

    # save top 100 results for compact results
    my @top100Genes;

    ###
    # get ranking information
    ###
    print STDERR "getting rank information...\n";
    my (%rank, @posRanks, @negRanks, $posRankSum, $negRankSum, $prevScore, %tiedWRanks, $wTies);
    foreach my $sortedLL (@sortedLLs)
    {
	$count++;
	if ($compact)
	{
	    if ($count <= 100)
	    {
		push(@top100Genes, $sortedLL);
	    }
	}
	if (($count == 1) || (($LLtoScore{$sortedLL} != $prevScore)))
	{
	    $rank = $count;
	}
	$rank{$sortedLL} = $rank;
	if ($scores)
	{
	    print SOUT "$rank\t$sortedLL\t$LLtoScore{$sortedLL}\t$LL2gene{$sortedLL}\t$LL2desc{$sortedLL}\n";
	}
	if (($posGenes =~ m/;$sortedLL;/) || ($negGenes =~ m/;$sortedLL;/))
	{
	    # need a wilcoxon rank
	    $wCount++;
	    if ($wScoreCount{$LLtoScore{$sortedLL}} == 1)
	    {
		# there are no other genes with this same score
		$wRank = $wCount;
	    }
	    else
	    {
		# there are other genes with this same score, so we need a compromise for the wRank
		if (defined($tiedWRanks{$LLtoScore{$sortedLL}}))
		{
		    # the compromise wRank has already been calculated
		    $wRank = $tiedWRanks{$LLtoScore{$sortedLL}};
		    unless ($wTies[-1] == $LLtoScore{$sortedLL})
		    {
			push(@wTies, $LLtoScore{$sortedLL});
		    }
		}
		else
		{
		    # calculate a compromise for the wRank
		    $wRank = ($wCount*2+$wScoreCount{$LLtoScore{$sortedLL}}-1)/2;
		    $tiedWRanks{$LLtoScore{$sortedLL}} = $wRank;
		}
	    }
	    # rankSum calculations
	    if ($posGenes =~ m/;$sortedLL;/)
	    {
		$posRankSum += $wRank;
	    }
	    else
	    {
		$negRankSum += $wRank;
	    }
	}
	$prevScore = $LLtoScore{$sortedLL};
    }

    print STDERR "pos rank sum = $posRankSum\n";
    print STDERR "neg rank sum = $negRankSum\n";
    
    my $zscore;
    ###
    # compute wilcoxon statistic
    ###
    if (($wilcoxon) || ($compact))
    {
	print STDERR "Calculating wilcoxon statistic...\n";
	my $mean;
	my $stddev;
	
	my $m = $#returnedPosGenes + 1;
	print STDERR "m=$m\n";
	my $n = $#returnedNegGenes + 1;
	print STDERR "n=$n\n";
	
	my $mean = $m*($m+$n+1)/2;
	print STDERR "mean: $mean\n";
	
	my $correction=0;
	foreach my $LLscore (@wTies)
	{
	    $correction += ($wScoreCount{$LLscore} - 1)*($wScoreCount{$LLscore})*($wScoreCount{$LLscore} + 1);
	}
	print STDERR "correction: $correction\n";
	my $stddev = sqrt(($m*$n*($m+$n+1)/12) - $m*$n*$correction/(12*($m+$n)*($m+$n-1)));
	print STDERR "stddev: $stddev\n";
	$zscore = ($posRankSum - $mean)/$stddev;
	
	if ($wilcoxon)
	{
	    print WOUT "$currentPos\t$currentNeg\t$zscore\n";
	}
    }
    
    ###
    # print compact results
    ###
    if ($compact)
    {
	print COUT "$currentPos\t$currentNeg\t$zscore";
	for (my $i=0; $i<100; $i++)
	{
	    my $type;
	    # determine if this gene is a positive gene (p), a negative gene (n), or unknown (u)
	    if ($posGenes =~ m/;$top100Genes[$i];/)
	    {
		$type = "p";
	    }
	    elsif ($negGenes =~ m/;$top100Genes[$i];/)
	    {
		$type = "n";
	    }
	    else
	    {
		$type = "u";
	    }
	    print COUT "\t$top100Genes[$i] ($type, $LLtoScore{$top100Genes[$i]})";
	}
	print COUT "\n";
    }
}


=pod

=head1 NAME

meta_msgr.pl

=head1 SYNOPSIS

meta_msgr.pl -m <matrix> [-i] [-p] <positive> [-n] <negative> [-b] <batch file> [-d] <pathway database file> [-w|-s|-c] -o <prefix for output> -g <gene info file>  

=head1 OPTIONS

=over 4

=item B<-help>

Prints a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<-m> string

Optional parameter.  Matrix file with pathway/msgr hit information.  Pathways are in first row and human locus links are in the first column of each subsequent row.

=item B<-i>

Optional parameter.  Indicates meta_msgr should be run in independent mode: only the positive input pathway will be used as a basis for scoring genes.  Wilcoxon statistics will still be returned in independent mode, so negative pathways must still be provided.

=item B<-p> string

Semi-required parameter.  Indicates file with positive gene set.  Use with -n flag.  Do not use with -b flag.

=item B<-n> string

Semi-required parameter.  Indicates file with negative gene set.  Use with -p flag.  Do not use with -b flag.

=item B<-b>
 
Semi-required parameter.  Use for batch mode.  Indicates file with positive and negative pathways separated by a tab.  Each run is on a new line.  Use with the -d flag.  Do not use with -p or -n flags.

=item B<-d> string

Semi-required paramter.  Use in batch mode.  Indicates a pathway database file; pathway names should be in the first column and the genes in the pathways should be separated by tabs.  Use with the -b flag.  Do not use with the -p or -n flags.

=item B<-w> 

Semi-required parameter.  Indicates wilcoxon statistic should be returned.  At least of the -w and -s flags should be used unless the -c flag is used.  Does not accept input.

=item B<-s>

Semi-required parameter.  Indicates gene scores should be returned.  At least one of the -w and -s flags should be used unless the -c flag is used.  Does not accept input.

=item B<-c>

Semi-required parameter.  Indicates output should be returned in compact format.  If the -c flag is not used, at least one of the -w and -s flags should be used.  Does not accept input.

=item B<-o> string

Required parameter.  Indicates the prefix for the output file(s).

=item B<-g> string

Optional parameter.  Indicates file mapping locus link to gene name and gene description.

=back

=head1 DESCRIPTION

Gene scoring system using both positive and negative input gene sets.  Determines the overlap of the positive and negative input gene sets with known pathways.  Rewards genes for overlap with pathways enriched in the positive gene set, and penalizes genes for overlap with pathways enriched in the negative gene set.  Returns gene scores and the Wilcoxon rank-sum statistic measuring the separation of the positive and negative gene scores.  May also be run in independent mode, which scores genes based only on the positive input gene set.  Wilcoxon statistics are still returned in independent mode.

=cut
