#!/usr/bin/perl

# auc: Compute area under curve (AUC) for a rank file read from the standard input.

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

# See sub printHelpInfo for usage information.
#
# Version History
# (Remember to update $aucversion.)
#   v1.9    2008-02-19: If the third value on a data line is negative, the
#           absolute value is taken as the test set size. This allows for
#           recall values of less than 100%. Reworded some help information.
#           2008-02-08: Compute standard deviation for each group and output
#           in group auc file. New $groupaucfileversion = "1.1".
#   v1.8    2007-06-25: Implemented additional error checking. Completed help
#           information for --groupauc and --mingroupauc.
#   v1.7    2007-06-25: Implemented duplicate ranks.
#   v1.6    2007-03-07: Added --groupauc and --mingroupauc options.
#   v1.5    2007-03-03: Implemented --verbose option. Updated comments and help
#           information. Updated informational comments. Compute and print
#           average AUC. Changed --includecomments to --noincludecomments. Changed
#           default method to method 1 (from method 0).
#   v1.4    2006-12-15: Implemented --method, --quiet, --pr, --prfmt, and --areafmt.
#           Updated auc file version to 1.1. (DMN)
#   v1.3    2006-11-21: Implemented --includecomments. Generalized terminology from
#           queries and genes to tests and elements. (DMN)
#   v1.2    2006-11-20: Added file version numbers. (DMN)
#   v1.1    2006-11-16: Removed references to ClueGene (except in GPL and citation
#           information). Implemented data line comments with --datalinecomments
#           option. Copy comment lines from rank file to output. Other minor code
#           changes. (DMN)
#   v1.0    2006-11-15: Created from cg.pl version 3.0. (DMN)

use strict;
use POSIX;      # for strftime
 
my $aucversion = "1.9";             # AUC version
my $rankfileversion = "1.0";        # rank file version
my $aucfileversion = "1.1";         # auc file version
my $groupaucfileversion = "1.1";    # group auc file version


##################################################
# sub printHelpInfo                              #
# Print help information to the standard output. #
##################################################

sub printHelpInfo
{
    print "\nAUC Help Information\n";
    print "====================\n\n";
    print "Compute areas under curve (AUC) for a rank file read from the standard input.\n";
    print "The AUCs are written to the standard output.\n";
    print "auc.pl version $aucversion (a component of the ClueGene pipeline).\n\n";
    print "Input Format\n";
    print "------------\n";
    print "  1. Input is read from the standard input.\n";
    print "  2. Each non-comment input line corresponds to one test set.\n";
    print "  3. Each non-comment line consists of tab-separated fields.\n";
    print "  4. The first field is the test id.\n";
    print "  5. The second field is the maximum possible rank (not used in this\n";
    print "     application except for error checking).\n";
    print "  6. If the third field is negative, the absolute value is taken as\n";
    print "     the test set size; otherwise, the third field is the first rank and\n";
    print "     the test set size is given by the number of rank values. This allows\n";
    print "     for less than 100% recall.\n";
    print "  7. Subsequent fields are the ranks of the expected elements (in increasing order).\n\n";
    print "Output Format\n";
    print "-------------\n";
    print "  1. Output is written to the standard output.\n";
    print "  2. Each non-comment output line corresponds to one test set.\n";
    print "  3. Each non-comment line consists of tab-separated fields.\n";
    print "  4. The first field is the test id.\n";
    print "  5. The second field is the area (by default, normalized by the theoretical\n";
    print "     maximum area; see the nonormalize option below).\n";
    print "     See the --areafmt option for formatting the area.\n";
    print "  6. If the --pr option was specified, subsequent fields are precision/recall\n";
    print "     pairs. Each field consists of two comma-separated subfields. The first\n";
    print "     subfield is the precision; the second subfield is the recall.\n";
    print "     See the --prfmt option for formatting the precision and recall values.\n";
    print "  7. The number of AUCs and average AUC is printed as a comment at the end\n";
    print "     of the output, unless the --quiet option was specified.\n\n";
    print "Grouped AUC Output Format\n";
    print "-------------------------\n";
    print "  1. Output is written to the file specified with the --groupauc option.\n";
    print "  2. Each non-comment output line corresponds to one query name.\n";
    print "  3. Each non-comment line consists of tab-separated fields.\n";
    print "  4. The first field is the query name.\n";
    print "  5. The second field is the average area for all queries with the given name\n";
    print "     (by default, normalized by the theoretical maximum area; see the\n";
    print "     nonormalize option below).\n";
    print "     See the --areafmt option for formatting the area.\n";
    print "  6. The third field is the number of queries with the given name.\n";
    print "  7. The fourth field is the standard deviation of the queries with the given name.\n";
    print "  8. The number of AUCs and average AUC is printed as a comment at the end\n";
    print "     of the output, unless the --quiet option was specified.\n\n";
    print "Command Line Options\n";
    print "--------------------\n";
    print "A command line option may be introduced with either a single dash or double\n"; 
    print "dash (i.e., \"-\" or \"--\").\n\n";
    print "--areafmt <format string>\n";
    print "  Specifies the sprintf format specifier for printing area values.\n";
    print "  If not specified, areas are printed in an unspecified default manner.\n";
    print "--datalinecomments\n";
    print "  Specifies that the first \"#\" character in a data line introduces a comment\n";
    print "  that terminates at the end of the line.\n";
    print "  If not specified, a \"#\" character in a data line is not interpreted as\n";
    print "  introducing a comment.\n";
    print "--help (-h)\n";
    print "  Print help information and exit.\n";
    print "--groupauc <filename>\n";
    print "  Specifies the name of the grouped AUC file (average AUCs by query name).\n";
    print "  If not specified, grouped AUCs are not produced.\n";
    print "--method <integer>\n";
    print "  Specifies the method to use for computing the AUC.\n";
    print "  Method 0: Compute area under the curve defined by successive (recall, precision)\n";
    print "    pairs, sweeping over every element in the (implicit) result list.\n";
    print "  Method 1: Compute area under the curve defined by successive (recall, precision)\n";
    print "    pairs, sweeping over every recall level (i.e., sweeping over every *expected*\n";
    print "    element in the result list).\n";
    print "  Method 2: Same as method 1, but duplicate ranks are allowed.\n";
    print "  If not specified, method 2 is used.\n";
    print "--mingroupauc <number>\n";
    print "  Specifies the minimum group average AUC to be included in the thresholded\n";
    print "  average AUC.\n";
    print "  If not specified, the value 0.2 is used.\n";
    print "--noincludecomments\n";
    print "  Specifies that comment lines from input files are not to be copied to\n";
    print "  the output.\n";
    print "--nonormalize\n";
    print "  Specifies that the areas are *not* normalized by dividing by the theoretical\n";
    print "  maximum area.\n";
    print "  If not specified, the areas are normalized.\n";
    print "--pr\n";
    print "  Print precision/recall pairs. See the section \"Output Format\" for details.\n";
    print "--prfmt <format string>\n";
    print "  Specifies the sprintf format specifier for printing precision and recall values.\n";
    print "  If not specified, the precision and recall values are printed in an unspecified\n";
    print "  default manner.\n";
    print "--quiet (-q)\n";
    print "  Specifies quiet mode for output.\n";
    print "  If specified, informational comments (such as version information and specified\n";
    print "  options) do not appear in the output.\n";
    print "  If not specified, informational comments do appear in the output.\n";
    print "--verbose (-v)\n";
    print "  Print verbose information. Not currently used.\n\n";
    print "Please cite the following article when using ClueGene:\n";
    print "  Ng DM, Woehrmann MH, Stuart JM.\n";
    print "  Recommending Pathway Genes Using a Compendium of Clustering Solutions.\n";
    print "  Pacific Symposium on Biocomputing 12:379-390(2007).\n";
    print "  Article: http://psb.stanford.edu/psb-online/proceedings/psb07/ng.pdf\n";
    print "  Online Supplement: http://sysbio.soe.ucsc.edu/cluegene/psb07/\n\n";
}


######################
# Begin main program #
######################

# if true, help information requested
my $print_help = 0;

# if true, do not normalize areas by theoretical maximum
my $nonormalize = 0;

# if true, allow an embedded "#" in a data line to introduce a comment
my $datalinecomments = 0; 

# if true, do not propagate comments from input to output
my $noincludecomments = 0; 

# if true, print precision/recall pairs
my $print_pr = 0;

# if true, quiet mode printing (i.e., no informational comments)
my $quiet = 0;

# if true (i.e., not an empty string), specifies the sprintf format for 
# printing each subfield of the precision/recall pairs
my $pr_fmt = "";

# if true (i.e., not an empty string), specifies the sprintf format for 
# printing the area
my $area_fmt = "";

# method for computing AUC
use constant METHOD_SWEEP_RESULTS => 0;
use constant METHOD_SWEEP_RECALL => 1;
use constant METHOD_DUPLICATE_RANKS => 2;
my $method = METHOD_DUPLICATE_RANKS;

# if true, write verbose trace information to the standard error
my $verbose = 0;

# file for auc grouped by query name
my $groupauc = "";

# for computing average AUC and thresholded average AUC
my $total_area = 0;
my $num_auc = 0;
my $total_area_thresholded = 0;
my $num_auc_thresholded = 0;

# threshold for thresholded average AUC
my $mingroupauc = 0.2;

# subfield separator
my $sep = "@";


#==============================#
# Process command line options #
#==============================#

# repeat for each command line argument
for (my $i = 0; $i < @ARGV; $i++)
{
    my $arg = @ARGV[$i];
    
    if ($arg eq "--nonormalize" || $arg eq "-nonormalize")
    {
        $nonormalize = 1;
    }
    elsif ($arg eq "--datalinecomments" || $arg eq "-datalinecomments")
    {
        $datalinecomments = 1;
    }
    elsif ($arg eq "--noincludecomments" || $arg eq "-noincludecomments")
    {
        $noincludecomments = 1;
    }
    elsif ($arg eq "--pr" || $arg eq "-pr")
    {
        $print_pr = 1;
    }
    elsif  ($arg eq "--method" || $arg eq "-method")
    {
        if ($i+1 >= @ARGV)
        {
            print STDERR "Warning: command line option \"$arg\" is missing its required argument.\n";
        }
        else
        {
            my $m = @ARGV[++$i];
            if ($m < METHOD_SWEEP_RESULTS || $m > METHOD_DUPLICATE_RANKS)
            {
                print STDERR "Warning: Value $m for option --method is out of range [", 
                             METHOD_SWEEP_RESULTS, "..", METHOD_DUPLICATE_RANKS,
                             "], option ignored.\n";
            }
            else
            {
                $method = $m;
            }
        }
    }
    elsif  ($arg eq "--groupauc" || $arg eq "-groupauc")
    {
        if ($i+1 >= @ARGV)
        {
            print STDERR "Warning: command line option \"$arg\" is missing its required argument.\n";
        }
        else
        {
            $groupauc = @ARGV[++$i];
        }
    }
    elsif  ($arg eq "--mingroupauc" || $arg eq "-mingroupauc")
    {
        if ($i+1 >= @ARGV)
        {
            print STDERR "Warning: command line option \"$arg\" is missing its required argument.\n";
        }
        else
        {
            $mingroupauc = @ARGV[++$i];
        }
    }
    elsif  ($arg eq "--areafmt" || $arg eq "-areafmt")
    {
        if ($i+1 >= @ARGV)
        {
            print STDERR "Warning: command line option \"$arg\" is missing its required argument.\n";
        }
        else
        {
            $area_fmt = @ARGV[++$i];
        }
    }
    elsif  ($arg eq "--prfmt" || $arg eq "-prfmt")
    {
        if ($i+1 >= @ARGV)
        {
            print STDERR "Warning: command line option \"$arg\" is missing its required argument.\n";
        }
        else
        {
            $pr_fmt = @ARGV[++$i];
        }
    }
    elsif ($arg eq "--q" || $arg eq "-q" || $arg eq "--quiet" || $arg eq "-quiet")
    {
        $quiet = 1;
    }
    elsif ($arg eq "--h" || $arg eq "-h" || $arg eq "--help" || $arg eq "-help")
    {
        $print_help = 1;
    }
    elsif ($arg eq "--v" || $arg eq "-v" || $arg eq "--verbose" || $arg eq "-verbose")
    {
        $verbose = 1;
    }
    else
    {
        # unrecognized option
        print STDERR "Warning: command line option \"$arg\" is not recognized.\n";
    }
}

    
if ($print_help)
{
    printHelpInfo();
    exit;
}


my @ltime = localtime;
if (!$quiet)
{
    # print version and execution information
    print "# AUC: auc.pl version $aucversion (a component of the ClueGene pipeline).\n";
    print strftime "# Generated on %a %Y-%m-%d %H:%M:%S %Z.\n", @ltime;
    print "# Input: Rank file version $rankfileversion.\n";
    print "# Output: AUC file version $aucfileversion.\n";
    print "# Output: Group AUC file version $groupaucfileversion.\n";
    print "# Options:\n";
    print "#   areafmt=$area_fmt.\n";
    print "#   datalinecomments=$datalinecomments.\n";
    print "#   groupauc=$groupauc.\n";
    print "#   method=$method.\n";
    print "#   mingroupauc=$mingroupauc.\n";
    print "#   noincludecomments=$noincludecomments.\n";
    print "#   nonormalize=$nonormalize.\n";
    print "#   pr=$print_pr.\n";
    print "#   prfmt=$pr_fmt.\n";
    print "#   quiet=$quiet.\n";
    print "#   verbose=$verbose.\n";
}


#=======================#
# process each test set #
#=======================#

# hashes keyed by query name
my %group_auc;      # total auc for the query
my %group_num;      # number of instances of the query
my %group_sumsq;    # sum of squares of the aucs for the query

# repeat for each test set
my $line;
while($line = <STDIN>) 
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
    
    # store each data field into an array element
    my @data = split "\t", $line;
    if (@data < 2)
    {
        # error: a line must have a test id and maximum possible rank
        print STDERR "Warning: data line format error, required fields missing.\n";
        next;
    }
    
    my $test_id = shift @data;
    my $maxPossibleRank = shift @data;
    my $pathway_size = scalar @data;    # @data now contains only ranks
    my $num_ranks = $pathway_size;
    
    if ($data[0] < 0)
    {
        # the number of pathways is specified as the absolute value of
        # the third field
        $num_ranks--;
        $pathway_size = -(shift @data);
    }
                
    
    #------------------------------#
    # Compute precision-recall AUC #
    #------------------------------#
    
    # area under the precision/recall curve
    my $area = 0;
    
    # variables to save the previously computed precision and recall
    my $precision_prev;
    my $recall_prev;
    my $pr = "";
    
    # number of elements and precision/recall pairs processed
    my $numelements = 0;
    my $num_pr_pairs = 0;
    
    # repeat for each element in order of increasing rank
    my $exp = 0;    # number of expected elements processed (minus 1)
    while ($exp < $num_ranks) 
    {
        if ($numelements++ > $maxPossibleRank)
        {
            die "auc.pl: Fatal error: Maximum possible rank exceeded.\n";
        }
    
        if ($method == METHOD_DUPLICATE_RANKS)
        {
            # count number of duplicate ranks, and advance $exp to first
            # non-duplicate rank
            my $currentRank = $data[$exp++];
            my $numDup = 1;
            while ($exp < $num_ranks)
            {
                if ($currentRank == $data[$exp])
                {
                    $numDup++;
                    $exp++;
                }
                else
                {
                    last;
                }
            }
            
            $numelements = $currentRank + ($numDup-1)/2;
        }
        elsif ($numelements == $data[$exp])
        {
            # found an expected element
            $exp++;
        }
        elsif ($method == METHOD_SWEEP_RECALL)
        {
            # not a new recall value, so skip it
            next;
        }
        
        # compute and print recall and precision
        my $recall = $exp/$pathway_size;
        my $precision = $exp/$numelements;
        $num_pr_pairs++;
        
        if ($num_pr_pairs > 1)
        {
            # update area using the trapezoidal rule
            $area += ($recall - $recall_prev) * ($precision + $precision_prev) / 2;
        }
        
        # if --pr option specified, save the precision/recall pair
        if ($print_pr)
        {
            if ($pr_fmt)
            {
                $pr .= sprintf "\t$pr_fmt,$pr_fmt", $precision, $recall;
            }
            else
            {
                $pr .= "\t$precision,$recall";
            }
        }
        
        # save precision and recall for next iteration
        $precision_prev = $precision;
        $recall_prev = $recall;
    }
    
    if ($num_ranks < $pathway_size)
    {
        # by convention, zero precision at the next recall level
        # update area using the trapezoidal rule
        $area += ((($exp+1)/$pathway_size) - $recall_prev) * ($precision_prev) / 2;
    }
    
    if (!$nonormalize)
    {
        # normalize area by theoretical maximum (avoid division by zero)
        $area = $area / (1-(1/$pathway_size)) if $pathway_size > 1;
    }
    
    if ($area_fmt)
    {
        printf "%s\t$area_fmt%s\n", $test_id, $area, $pr;
    }
    else
    {
        print "$test_id\t$area$pr\n";
    }
    
    # accumulate for total average AUC
    $total_area += $area;
    $num_auc++;
    
    # accumulate for grouped average AUC
    if ($test_id =~ /$sep/)
    {
        # remove the query index
        $test_id =~ /^(.+)$sep.+$/;
        $test_id = $1;
    }
    $group_auc{$test_id} += $area;
    $group_num{$test_id}++;
    $group_sumsq{$test_id} += ($area ** 2);
    
}   # while($line = <STDIN>) for each test set


if (!$quiet)
{
    print "# Number of AUCs: $num_auc\n";
    if ($num_auc > 0)
    {
        print "# Average AUC: ", $total_area/$num_auc, "\n";        
    }
    else
    {
        print "# Average AUC: undefined\n";
    }    
}


#------------------------#
# print grouped averages #
#------------------------#

if ($groupauc ne "")
{
    # open the group file
    if (!open(GROUP, ">$groupauc"))
    {
        # an error was detected
        print STDERR "Warning: could not open group file \"$groupauc\".\n";
    }
    else
    {
        # print header
        print GROUP "# Grouped average AUC\n";
        print GROUP "# AUC: auc.pl version $aucversion (a component of the ClueGene pipeline).\n";
        print GROUP strftime "# Generated on %a %Y-%m-%d %H:%M:%S %Z.\n", @ltime;
        print GROUP "# Input: Rank file version $rankfileversion.\n";
        print GROUP "# Output: AUC file version $aucfileversion.\n";
        print GROUP "# Output: Group AUC file version $groupaucfileversion.\n";

        # repeat for each query in alphabetical order
        # for my $qid (sort {$group_auc{$b}/$group_num{$b} <=> $group_auc{$a}/$group_num{$a}} (keys %group_auc)) 
        for my $qid (sort keys %group_auc)
        {
            my $n = $group_num{$qid};
            my $avg = $group_auc{$qid}/$n;
            
            my $sd = 0;
            $sd = sqrt(($group_sumsq{$qid} - (($group_auc{$qid}**2)/$n)) / ($n-1))
                if ($n > 1);
            if ($avg >= $mingroupauc)
            {
                $total_area_thresholded += $avg;
                $num_auc_thresholded++;
            }
            print GROUP "$qid\t$avg\t", $group_num{$qid}, "\t$sd\n";
        }
    
        # print total average AUC
        print GROUP "# Number of AUCs: $num_auc\n";
        if ($num_auc > 0)
        {
            print GROUP "# Average AUC: ", $total_area/$num_auc, "\n";        
        }
        else
        {
            print GROUP "# Average AUC: undefined\n";
        }
        
        # print thresholded total average AUC
        print "# Number of AUCs meeting minimum threshold $mingroupauc: $num_auc_thresholded\n";
        print GROUP "# Number of AUCs meeting minimum threshold $mingroupauc: $num_auc_thresholded\n";
        if ($num_auc_thresholded > 0)
        {
            print "# Thresholded average AUC: ", $total_area_thresholded/$num_auc_thresholded, "\n";        
            print GROUP "# Thresholded average AUC: ", $total_area_thresholded/$num_auc_thresholded, "\n";        
        }
        else
        {
            print "# Thresholded average AUC: undefined\n";
            print GROUP "# Thresholded average AUC: undefined\n";
        }
    }
}
