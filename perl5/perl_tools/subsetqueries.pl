#!/usr/bin/perl

# subsetqueries: Generate a subset of a set of query sets.

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
# (Remember to update $subsetqueriesversion.)
#	v1.2	2007-04-25: Added options --genome and --minqp.
#	v1.1	2007-04-13: Modified to allow processing of non-query files (i.e.,
#			pathway files) by ignoring a missing query index.
#   v1.0    2007-03-05: Created from makequeries.pl version 1.1.

use strict;
use POSIX;      # for ceil, strftime
 
# version information
my $subsetqueriesversion = "1.2";
my $queryfileversion = "1.0";               # query file version


##################################################
# sub cg_printHelpInfo                           #
# Print help information to the standard output. #
##################################################

sub cg_printHelpInfo
{
    print "\nSubset Query Sets Help Information\n";
    print "==================================\n\n";
    print "Generate a subset of a set of query sets created by makequeries.pl.\n";
    print "subsetqueries.pl version $subsetqueriesversion (a component of the ClueGene pipeline).\n\n";
    print "The initial query sets are read from the standard input, and the subsets\n";
    print "are written to the standard output.\n\n";
    print "Command Line Options\n";
    print "--------------------\n";
    print "--help (-h)\n";
    print "  Print help information and exit.\n";
    print "--genome <filename>\n";
    print "  Specifies the name of a genome file.\n";
    print "  Use in conjunction with the --mingp option.\n";
    print "--lb <integer>\n";
    print "  Specifies the lower bound of the query index to include in the subset.\n";
    print "  If not specified, value 0 is used.\n";
    print "--mingp <number>\n";
    print "  Specifies the minimum genome percentage, the percentage of genes in a\n";
	print "  pathway that must be found in the genome for the pathway to be included\n";
	print "  in the subset.\n";
    print "  If not specified, value 0 is used (i.e., no genome percentage\n";
	print "  restriction).\n";
    print "  Use in conjunction with the --genome option.\n";
    print "--minqsize <integer>\n";
    print "  Specifies the minimum query set size to include in the subset.\n";
    print "  If not specified, value 0 is used (i.e., no size restriction).\n";
    print "--noincludecomments\n";
    print "  Specifies that comment lines from input files are not to be copied to\n";
    print "  the output.\n";
    print "  If not specified, comments are copied from input to output.\n";
    print "--quiet (-q)\n";
    print "  Quiet mode: suppress generation of informational comments.\n";
    print "--ub <integer>\n";
    print "  Specifies the upper bound of the query index to include in the subset.\n";
    print "  If not specified, value 10000 is used.\n";
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

# separator between pathway id and query index
my $sep = "@";

# if true, do not propagate comments from input to output
my $noincludecomments = 0; 

# if true, quiet mode printing (i.e., no informational comments)
my $quiet = 0;

# if true, write verbose trace information to the standard error
my $verbose = 0;

# lower and upper bounds for query indices
my $lb = 0;
my $ub = 10000;

# minimum query set size (default: no size restriction)
my $minqsize = 0;

# name for input genome file
my $genome_file = "";

# minimum genome percentage
my $mingp = 0;

# each gene in the genome file exists as a key in this hash
my %genome;


#==============================#
# Process command line options #
#==============================#

#--------------------------------#
# get the command line arguments #
#--------------------------------#

# repeat for each command line argument
for (my $i = 0; $i < @ARGV; $i++) {
    my $arg = @ARGV[$i];
    
    if ($arg eq "--lb" || $arg eq "-lb")
    {
        if ($i+1 >= @ARGV)
        {
            print STDERR "Warning: command line option \"$arg\" is missing its required argument.\n";
        }
        else
        {
            $lb = @ARGV[++$i];
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
    elsif ($arg eq "--ub" || $arg eq "-ub")
    {
        if ($i+1 >= @ARGV)
        {
            print STDERR "Warning: command line option \"$arg\" is missing its required argument.\n";
        }
        else
        {
            $ub = @ARGV[++$i];
        }
    }
    elsif ($arg eq "--mingp" || $arg eq "-mingp")
    {
        if ($i+1 >= @ARGV)
        {
            print STDERR "Warning: command line option \"$arg\" is missing its required argument.\n";
        }
        else
        {
            $mingp = @ARGV[++$i];
        }
    }
    elsif ($arg eq "--minqsize" || $arg eq "-minqsize")
    {
        if ($i+1 >= @ARGV)
        {
            print STDERR "Warning: command line option \"$arg\" is missing its required argument.\n";
        }
        else
        {
            $minqsize = @ARGV[++$i];
        }
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


if (!$quiet)
{
    # print version and execution information
    print "# Subset Query Sets: subsetqueries.pl version $subsetqueriesversion (a component of the ClueGene pipeline).\n";
    print strftime "# Executed on %a %Y-%m-%d %H:%M:%S %Z.\n", localtime;
    print "# Input: Query file version $queryfileversion.\n";
    print "# Output: Query file version $queryfileversion.\n";
    print "# Options:\n";
    print "#   genome=$genome_file.\n";
    print "#   lb=$lb.\n";
    print "#   mingp=$mingp.\n";
    print "#   minqsize=$minqsize.\n";
    print "#   noincludecomments=$noincludecomments.\n";
    print "#   quiet=$quiet.\n";
    print "#   ub=$ub.\n";
    print "#   verbose=$verbose.\n";
}


#===================#
# input genome file #
#===================#

if ($genome_file ne "")
{
	# a genome file was specified
	
    # open the genome file
    if (!open(GENOME, "$genome_file"))
    {
        # an error was detected
        print STDERR "Warning: could not open genome file \"$genome_file\".\n";
    }
    else
    {
		# repeat for each line of the genome file (each line has one gene name)
		while(<GENOME>) 
		{
			# handle non-data lines
			if ($_ =~ /^\s*#/)
			{
				# ignore a comment line
				 next;
			}
			elsif ($_ =~ /^\s*$/)
			{
				# ignore a blank line
				next;
			}
		
			chomp;
						
			$genome{$_} = 1;
		}
    	
    	close GENOME;
	}
}


#========================#
# process each query set #
#========================#

# repeat for each query set
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
        
    # store each data field into an array element
    chomp $line;
    my @data = split "\t", $line;
    if (@data < 2)
    {
        # error: a line must have a query id and at least one gene
        print STDERR "Warning: data line format error, required fields missing.\n";
        next;
    }
    
    # skip this query set if its size (excluding the query id) is too small
    next if (@data-1 < $minqsize);
    
    # get the query index    
    my $qid = shift @data;
    if ($qid =~ /$sep/)
    {
        # the query id contains a query index separator character
        $qid =~ /^.*$sep(\d+)\s*$/;
        my $qindex = $1;

        # skip line if query index out of range
        if ($qindex < $lb || $qindex > $ub)
        {
            next;
        }
    }
    
    # skip line if pathway is empty
    next if @data <= 0;
    
    # repeat for each gene in the cluster
    my $num_in_genome = 0;
    for (my $i = 0; $i < @data; $i++)
    {
    	$num_in_genome += $genome{$data[$i]};
    }
    
    # skip if pathway contains too few of the genome genes
    next if ($num_in_genome*100/@data < $mingp);
    
    # include the query in the subset
    print "$line\n";
    
}   # while($line = <STDIN>) for each query set
