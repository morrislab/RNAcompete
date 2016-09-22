#!/usr/bin/perl

# makequeries: Generate query sets.

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
# (Remember to update $cgversion.)
#   v1.3    2007-08-10: Updated help information to note options --genome and
#           --mingp are currently unimplemented.
#   v1.2    2007-04-24: Began implementing options --genome and --mingp.
#   v1.1    2007-03-03: Implemented correct help information. Updated printing
#           of informational comments. Implemented options --quiet, --verbose,
#           --datalinecomments, --noincludecomments. Shuffle the genes of a 
#           pathway rather than selecting genes at random without replacement
#           (to avoid numerous duplicate selections for large query percentage).
#   v1.0    2006-11-15: Created from cg_auc.pl version 1.0.

use strict;
use POSIX;      # for ceil, strftime
 
# version information
my $makequeriesversion = "1.3";
my $queryfileversion = "1.0";               # query file version
my $pathwaycompendiumfileversion = "1.0";   # pathway compendium file version


##################################################
# sub cg_printHelpInfo                           #
# Print help information to the standard output. #
##################################################

sub cg_printHelpInfo
{
    # process parameters
    my $defnumQ = shift;
    my $defqp = shift;
    my $defseed = shift;

    print "\nMake Query Sets Help Information\n";
    print "================================\n\n";
    print "Make query sets.\n";
    print "makequeries.pl version $makequeriesversion (a component of the ClueGene pipeline).\n\n";
    print "A pathway compendium is read from standard input.\n";
    print "The query sets are written to the standard output.\n\n";
    print "Command Line Options\n";
    print "--------------------\n";
    print "--datalinecomments\n";
    print "  Specifies that the first \"#\" character in a data line introduces a\n";
    print "  comment that terminates at the end of the line.\n";
    print "--genome <filename>\n";
    print "  Specifies the name of a genome file to be used with the --mingp option.\n";
    print "  If specified, the genes listed in <filename> are used as the genome\n";
    print "  of the species.\n";
    print "  Not yet implemented.\n";
    print "--help (-h)\n";
    print "  Print help information and exit.\n";
    print "--mingp <number>\n";
    print "  Specifies the minimum genome percentage to be used with the --genome option.\n";
    print "  Not yet implemented.\n";
    print "--noincludecomments\n";
    print "  Specifies that comment lines from input files are not to be copied to\n";
    print "  the output.\n";
    print "  If not specified, comments are copied from input to output.\n";
    print "--numq <integer>\n";
    print "  Specifies the number of query sets to generate from each pathway.\n";
    print "  If not specified: default value of $defnumQ is used.\n";
    print "--qp <number>\n";
    print "  Specifies the query percentage, the percentage of genes in a pathway to\n";
    print "  select for a query set.\n";
    print "  If not specified: default value of $defqp is used.\n";
    print "--quiet (-q)\n";
    print "  Quiet mode: suppress generation of informational comments.\n";
    print "--seed <filename>\n";
    print "  Specifies the random number seed.\n";
    print "  If not specified: default value of $defseed is used.\n";
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

# various default values
my $defnumQ = 30;
my $defqp = 50;
my $defseed = 0.0;

# if true, help information requested
my $print_help = 0;

# number of queries per pathway
my $numQ = $defnumQ;

# percentage of pathway genes to select for query
my $queryPercent = $defqp;

# random number seed
my $seed = $defseed;

# separator between pathway id and query index
my $sep = "@";

# if true, allow an embedded "#" in a data line to introduce a comment
my $datalinecomments = 0; 

# if true, do not propagate comments from input to output
my $noincludecomments = 0; 

# if true, quiet mode printing (i.e., no informational comments)
my $quiet = 0;

# if true, write verbose trace information to the standard error
my $verbose = 0;


#==============================#
# Process command line options #
#==============================#

#--------------------------------#
# get the command line arguments #
#--------------------------------#

# repeat for each command line argument
for (my $i = 0; $i < @ARGV; $i++) {
    my $arg = @ARGV[$i];
    
    if ($arg eq "--seed" || $arg eq "-seed")
    {
        if ($i+1 >= @ARGV)
        {
            print STDERR "Warning: command line option \"$arg\" is missing its required argument.\n";
        }
        else
        {
            $seed = @ARGV[++$i];
        }
    }
    elsif ($arg eq "--qp" || $arg eq "-qp")
    {
        if ($i+1 >= @ARGV)
        {
            print STDERR "Warning: command line option \"$arg\" is missing its required argument.\n";
        }
        else
        {
            $queryPercent = @ARGV[++$i];
        }
    }
    elsif ($arg eq "--numq" || $arg eq "-numq")
    {
        if ($i+1 >= @ARGV)
        {
            print STDERR "Warning: command line option \"$arg\" is missing its required argument.\n";
        }
        else
        {
            $numQ = @ARGV[++$i];
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
    cg_printHelpInfo($defnumQ, $defqp, $defseed);
    exit;
}


if (!$quiet)
{
    # print version and execution information
    print "# Make Query Sets: makequeries.pl version $makequeriesversion (a component of the ClueGene pipeline).\n";
    print strftime "# Executed on %a %Y-%m-%d %H:%M:%S %Z.\n", localtime;
    print "# Input: Pathway compendium file version $pathwaycompendiumfileversion.\n";
    print "# Output: Query file version $queryfileversion.\n";
    print "# Options:\n";
    print "#   datalinecomments=$datalinecomments.\n";
    print "#   noincludecomments=$noincludecomments.\n";
    print "#   numq=$numQ.\n";
    print "#   seed=$seed.\n";
    print "#   qp=$queryPercent.\n";
    print "#   quiet=$quiet.\n";
    print "#   verbose=$verbose.\n";
}

if ($queryPercent <= 0 || $queryPercent > 100)
{
    die "Error: Query percentage $queryPercent must be greater than 0 and less than or equal to 100.";
}

srand $seed;


#======================#
# process each pathway #
#======================#

# repeat for each pathway
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
        # error: a line must have a pathway id and at least one gene
        print STDERR "Warning: data line format error, required fields missing.\n";
        next;
    }
    
    my $pathway_id = shift @data;
    my $pathway_size = scalar @data;    # @data now contains only genes
    
    # the number of genes to select from the pathway
    my $numGenes = ceil($pathway_size * $queryPercent/100);
                
    
    #------------------------------------------#
    # generate the specified number of queries #
    #------------------------------------------#
    
    for (my $qindex = 0; $qindex < $numQ; $qindex++)
    {       
        # shuffle the genes
        my @shuffle = @data;
        for (my $i = 0; $i < $pathway_size; $i++)
        {
            my $r = int(rand $pathway_size);
            ($shuffle[$i], $shuffle[$r]) = ($shuffle[$r], $shuffle[$i]);
        }
        
        # print the pathway id with query index
        printf "$pathway_id$sep%0.2d", $qindex;
        
        # take the first $numGenes genes as the query set
        # sort and print the query set
        my @query = @shuffle[0..($numGenes-1)];
        foreach my $qgene (sort @query)
        {
            print "\t$qgene";
        }
        print "\n";
    }

}   # while($line = <STDIN>) for each pathway
