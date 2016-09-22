#!/usr/bin/perl

# mergescores: Generate a rank file from a weighted merge of two score files.

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
# Version History
# (Remember to update $mergescoresversion.)
#	v1.1	2007-08-09: Added option --scorefile. Updated help information to
#			note cg.pl --printscores is assumed. Modified code to allow a query
#			id to consist of a pathway name without "@queryindex".
#   v1.0    2007-03-06: Created from subsetqueries.pl version 1.0.

use strict;
use POSIX;      # for ceil, strftime
 
# version information
my $mergescoresversion = "1.1";
my $rankfileversion = "1.0";    # rank file version
my $scorefileversion = "1.0";   # score file version


##################################################
# sub cg_printHelpInfo                           #
# Print help information to the standard output. #
##################################################

sub cg_printHelpInfo
{
    print "\nMerge Score Files Help Information\n";
    print "==================================\n\n";
    print "Generate a rank file from a weighted merge of two score files.\n";
    print "mergescores.pl version $mergescoresversion (a component of the ClueGene pipeline).\n\n";
    print "The score filenames are specified with command line arguments,\n";
    print "and the rank file is written to the standard output.\n";
    print "This program assumes the score files are in the format of the cg.pl\n";
    print "--printscores option.\n\n";
    print "Command Line Options\n";
    print "--------------------\n";
    print "--help (-h)\n";
    print "  Print help information and exit.\n";
    print "--incquery\n";
    print "  If specified: query genes are included in the results.\n";
    print "  If not specified: query genes are not included in the results.\n";
    print "--noincludecomments\n";
    print "  Specifies that comment lines from input files are not to be copied to\n";
    print "  the output.\n";
    print "  If not specified, comments are copied from input to output.\n";
    print "--quiet (-q)\n";
    print "  Quiet mode: suppress generation of informational comments.\n";
    print "--score1 <filename>\n";
    print "  Specifies the name of the first score file.\n";
    print "  This argument is required.\n";
    print "--score2 <filename>\n";
    print "  Specifies the name of the second score file.\n";
    print "  This argument is required.\n";
    print "--scorefile <filename>\n";
    print "  Specifies the name for the output score file.\n";
    print "  If not specified, no score file is produced.\n";
    print "--verbose (-v)\n";
    print "  Print verbose information. Not currently used.\n";
    print "--weight1 <number>\n";
    print "  Specifies the weight of the first score file, a number between 0 and 1.\n";
    print "  This argument is required.\n";
    print "--weight2 <number>\n";
    print "  Specifies the weight of the second score file, a number between 0 and 1.\n";
    print "  If not specified, weight2 is given the value 1-weight1.\n\n";
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

# separator between pathway id and query index
my $sep = "@";

# if true, do not propagate comments from input to output
my $noincludecomments = 0; 

# if true, quiet mode printing (i.e., no informational comments)
my $quiet = 0;

# if true, write verbose trace information to the standard error
my $verbose = 0;

# score filenames and weights
my $score1;
my $score2;
my $weight1;
my $weight2;

# if true, include query genes in result output
my $incquery = 0;

# hashes keyed by gene id
my %flag;
my %score;

# name of the score file
my $scorefile = "";


#==============================#
# Process command line options #
#==============================#

#--------------------------------#
# get the command line arguments #
#--------------------------------#

# repeat for each command line argument
for (my $i = 0; $i < @ARGV; $i++) {
    my $arg = @ARGV[$i];
    
    if ($arg eq "--score1" || $arg eq "-score1")
    {
        if ($i+1 >= @ARGV)
        {
            print STDERR "Warning: command line option \"$arg\" is missing its required argument.\n";
        }
        else
        {
            $score1 = @ARGV[++$i];
        }
    }
    elsif ($arg eq "--score2" || $arg eq "-score2")
    {
        if ($i+1 >= @ARGV)
        {
            print STDERR "Warning: command line option \"$arg\" is missing its required argument.\n";
        }
        else
        {
            $score2 = @ARGV[++$i];
        }
    }
    elsif ($arg eq "--weight1" || $arg eq "-weight1")
    {
        if ($i+1 >= @ARGV)
        {
            print STDERR "Warning: command line option \"$arg\" is missing its required argument.\n";
        }
        else
        {
            $weight1 = @ARGV[++$i];
        }
    }
    elsif ($arg eq "--weight2" || $arg eq "-weight2")
    {
        if ($i+1 >= @ARGV)
        {
            print STDERR "Warning: command line option \"$arg\" is missing its required argument.\n";
        }
        else
        {
            $weight2 = @ARGV[++$i];
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
            $scorefile = @ARGV[++$i];
        }
    }
    elsif ($arg eq "--incquery" || $arg eq "-incquery")
    {
        $incquery = 1;
    }
    elsif ($arg eq "--noincludecomments" || $arg eq "-noincludecomments")
    {
        $noincludecomments = 1;
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

    
#------------------------------------#
# process the command line arguments #
#------------------------------------#

if ($print_help)
{
    cg_printHelpInfo();
    exit;
}

my $err = 0;

if (!defined $score1)
{
    print STDERR "Error: score1 filename not specified.\n";
    $score1 = "";
    $err = 1;
}
elsif (!open(SCORE1, "<$score1"))
{
    # could not open file
    print STDERR "Error: could not open score1 file \"$score1\".\n";
    $err = 1;
}

if (!defined $score2)
{
    print STDERR "Error: score2 filename not specified.\n";
    $score2 = "";
    $err = 1;
}
elsif (!open(SCORE2, "<$score2"))
{
    # could not open file
    print STDERR "Error: could not open score2 file \"$score2\".\n";
    $err = 1;
}

if (!defined $weight1)
{
    print STDERR "Error: weight1 not specified.\n";
    $weight1 = "";
    $err = 1;
}
elsif ($weight1 < 0 || $weight1 > 1)
{
    print STDERR "Error: weight1 out of range of [0,1].\n";
    $err = 1;
}
elsif (!defined $weight2)
{
    $weight2 = 1 - $weight1;
}


if (!$quiet)
{
    # print version and execution information
    print "# Merge Score Files: mergescores.pl version $mergescoresversion (a component of the ClueGene pipeline).\n";
    print strftime "# Executed on %a %Y-%m-%d %H:%M:%S %Z.\n", localtime;
    print "# Input: Score file version $scorefileversion.\n";
    print "# Output: Rank file version $rankfileversion.\n";
    print "# Options:\n";
    print "#   incquery=$incquery.\n";
    print "#   noincludecomments=$noincludecomments.\n";
    print "#   quiet=$quiet.\n";
    print "#   score1=$score1.\n";
    print "#   score2=$score2.\n";
    print "#   scorefile=$scorefile.\n";
    print "#   verbose=$verbose.\n";
    print "#   weight1=$weight1.\n";
    print "#   weight2=$weight2.\n";
}


die "Error: Fatal errors detected" if $err;


# open score file for output if specified
if ($scorefile ne "")
{
    if (!open(SCORE, ">$scorefile"))
    {
        # an error was detected
        print STDERR "Warning: could not open score file \"$scorefile\".\n";
        $scorefile = "";
    }
}


#========================#
# process each query set #
#========================#

# repeat for each query set
while(1)
{
    #------------------------------------------#
    # get the next data line from score file 1 #
    #------------------------------------------#
    
    my $eof = 1;    # assume guilty until proven innocent
    my $line1;
    while($line1 = <SCORE1>) 
    {   
        # handle non-data lines
        if ($line1 =~ /^\s*#/)
        {
            # a comment line, copy to output if appropriate and otherwise ignore
            print "#$line1" if !$noincludecomments;
            next;
        }
        elsif ($line1 =~ /^\s*$/)
        {
            # ignore a blank line
            next;
        }
        
        # read a line, so eof is false
        $eof = 0;
        last;
    }
    
    
    #------------------------------------------#
    # get the next data line from score file 2 #
    #------------------------------------------#
    
    my $line2;
    while($line2 = <SCORE2>) 
    {   
        # handle non-data lines
        if ($line2 =~ /^\s*#/)
        {
            # a comment line, copy to output if appropriate and otherwise ignore
            print "#$line2" if !$noincludecomments;
            next;
        }
        elsif ($line2 =~ /^\s*$/)
        {
            # ignore a blank line
            next;
        }
        
        # read a line, so eof is false
        $eof = 0;
        last;
    }
    last if $eof;
    
    
    #---------------------------------------#
    # separate the data fields of each line #
    #---------------------------------------#
    
    # store each data field into an array element
    my @data1 = split "\t", $line1;
    if (@data1 < 2)
    {
        # error: a line must have a query id and at least one gene
        chomp $line1;
        die "Error: Score file 1 format error, required fields missing: \"$line1\"";
    }
    
    my @data2 = split "\t", $line2;
    if (@data2 < 2)
    {
        # error: a line must have a query id and at least one gene
        chomp $line2;
        die "Error: Score file 2 format error, required fields missing: \"$line2\"";
    }
    
    # get the query names (assume the last "@xxx" is the AUC from --printscores)
    my $qid1 = shift @data1;
    if ($qid1 =~ /^(.+$sep.+)$sep.+$/)
    {
    	$qid1 = $1;
    }
    elsif ($qid1 =~ /^(.+)$sep.+$/)
    {
    	$qid1 = $1;
    }
    my $qid2 = shift @data2;
    if ($qid2 =~ /^(.+$sep.+)$sep.+$/)
    {
    	$qid2 = $1;
    }
    elsif ($qid2 =~ /^(.+)$sep.+$/)
    {
    	$qid2 = $1;
    }
    
    if ($qid1 ne $qid2)
    {
        die "Error: Corresponding lines have different query ids \"$qid1\" and \"$qid2\"";
    }
    #print "qid1=$qid1;qid2=$qid2.\n";
    
    
    #---------------------------------------#
    # process the data from the score files #
    #---------------------------------------#
    
    # reinitialize variables
    undef %flag;
    undef %score;
    
    my $num_query = 0;
    my $genome_size = @data1;
    #if ($genome_size != @data2)
    #{
    #    die "Query id \"$qid1\" has different genome sizes in score files 1 and 2";
    #}
    
    foreach my $ginfo1 (@data1)
    {
        $ginfo1 =~ /^(.+)$sep(.+)$sep(.+)$/;
        $flag{$1} = $2;
        ++$num_query if $2 eq "Q";
        $score{$1} = $3 * $weight1;
    }
    
    foreach my $ginfo2 (@data2)
    {
        $ginfo2 =~ /^(.+)$sep(.+)$sep(.+)$/;
        if (!defined $flag{$1})
        {
            #die "Error: Missing gene \"$1\" for query id \"$qid1\"";
            $flag{$1} = $2;
        }
        if ($flag{$1} ne $2)
        {
            die "Error: Inconsistent Q/E/N flags for query id \"$qid1\" and gene \"$1\"";
        }
        $score{$1} += $3 * $weight2;
    }
    
    # for testing
    if (0)
    {
        print $line1;
        print $line2;
        for my $g (sort keys %score)
        {
            print "$g:", $flag{$g}, ":", $score{$g}, "\n";
        }
    }

    
    #-------------------------------------------------#
    # output to the rank and (optionally) score files #
    #-------------------------------------------------#
    
    # rank file: print the query id
    print "$qid1\t";
	
	# score file: print query id and dummy AUC
	print SCORE "$qid1$sep", "00.0" if ($scorefile ne "");
    
    # rank file: print the maximum possible rank
    if ($incquery)
    {
        print $genome_size;
    }
    else
    {
        print $genome_size - $num_query;
    }
    
    # number of genes processed
    my $numgenes = 0;
        
    # repeat for each gene in order of decreasing score
    for my $gene (sort {$score{$b} <=> $score{$a}} (keys %score)) 
    {
        # skip query genes if they are not to be included in the results
        next if ($flag{$gene} eq "Q" && !$incquery);
        
        # at this point we have a result gene to count
        $numgenes++;
        
        if ($flag{$gene} eq "E" || $flag{$gene} eq "Q")
        {
            # rank file: this is a gene in the expected set
            print "\t$numgenes";
        }
        
        # score file: print gene id, flag, and score
		print SCORE "\t$gene$sep", $flag{$gene}, "$sep", int($score{$gene} + 0.5)
			 if ($scorefile ne "");
    }
    print "\n";
    print SCORE "\n" if ($scorefile ne "");
    
}   # while (1) for each query set

close(SCORE) if ($scorefile ne "");
