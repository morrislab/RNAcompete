#!/usr/bin/perl

# makedslist: Make dataset list.

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
#	v1.3	2007-08-18: For the --verbose option: print the contents of the
#			stats.tab file as a comment for each cluster file. Print a warning
#			comment for an empty cluster file. 
#   v1.2    2007-03-09: Fixed bug in printing execution time (added "use POSIX;").
#   v1.1    2007-03-03: Implemented --quiet option. Generate informational comments
#           in output. Updated and fixed comments and help information.
#   v1.0    2006-11-21: Initial version. Based on makecc.pl v1.0. (DMN)


use strict;
use warnings;
use Cwd;
use POSIX;      # for strftime

# version information
my $makedslistversion = "1.3";
my $datasetlistfileversion = "1.0"; # dataset list file version


##################################################
# sub cg_printHelpInfo                           #
# Print help information to the standard output. #
##################################################

sub cg_printHelpInfo
{
    print "\nMake Dataset List Help Information\n";
    print "==================================\n\n";
    print "Make a dataset list: a list of datasets is written to the standard output.\n";
    print "makedslist.pl version $makedslistversion (a component of the ClueGene pipeline).\n\n";
    print "This program is given a root directory (the \"dataroot\"). It checks each file\n";
    print "in the root to see if it is a dataset directory by checking whether the file\n";
    print "contains a cluster file. The names of the dataset directories are written to\n";
    print "the standard output, in sorted order.\n\n";
    print "Command Line Options\n";
    print "--------------------\n";
    print "--clufilename <filename>\n";
    print "  Specifies the name of the cluster file found in each dataset\n";
    print "  directory. This may be a pathname.\n";
    print "  If not specified: Network/Corr/Modes/data.tab is used.\n";
    print "  See also --dataroot.\n";
    print "--dataroot <dirname>\n";
    print "  Specifies the directory where the dataset data files are located.\n";
    print "  If not specified: /projects/sysbio/map/Data/Expression/Yeast is\n";
    print "  used (this is the S. cerevisiae dataset directory for UCSC SoE servers).\n";
    print "  See also --clufilename.\n";
    print "--help (-h)\n";
    print "  Print help information and exit.\n";
    print "--quiet (-q)\n";
    print "  Quiet mode: suppress generation of informational comments.\n";
    print "--verbose (-v)\n";
    print "  Print verbose information: Print clustering statistics as a comment\n";
	print "  for each cluster file, if available.\n\n";
    print "Please cite the following article when using ClueGene:\n";
    print "  Ng DM, Woehrmann MH, Stuart JM.\n";
    print "  Recommending Pathway Genes Using a Compendium of Clustering Solutions.\n";
    print "  Pacific Symposium on Biocomputing 12:379-390(2007).\n";
    print "  Article: http://psb.stanford.edu/psb-online/proceedings/psb07/ng.pdf\n";
    print "  Online Supplement: http://sysbio.soe.ucsc.edu/cluegene/psb07/\n\n";
}


# if true, write verbose trace information to the standard error
my $verbose = 0;

# if true, suppress generation of informational comments
my $quiet = 0;

# path to the Saccharomyces cerevisiae datasets
my $dir_prefix = "/projects/sysbio/map/Data/Expression/Yeast";

# if true, help information requested
my $print_help = 0;
        
# filename of the data file within the dataset directory (same for
# each dataset)
my $clufilename = "Network/Corr/Modes/data.tab";

# filename of the statistics file within the dataset directory (same for
# each dataset)
my $statsfilename = "Network/Corr/Modes/stats.tab";


#-----------------#
# Process options #
#-----------------#
    
use Getopt::Long;

GetOptions(
    'clufilename=s'     => \$clufilename,
    'dataroot=s'        => \$dir_prefix,
    'h|help'            => \$print_help,
    'q|quiet'           => \$quiet,
    'v|verbose'         => \$verbose);


if ($print_help)
{
    cg_printHelpInfo();
    exit;
}


if (!$quiet)
{   
    # print version and execution information
    print "# Make Dataset List: makedslist.pl version $makedslistversion (a component of the ClueGene pipeline).\n";
    print strftime "# Generated on %a %Y-%m-%d %H:%M:%S %Z.\n", localtime;
    print "# Output: Dataset list file version $datasetlistfileversion.\n";
    print "# Options:\n";
    print "#   clufilename=$clufilename.\n";
    print "#   dataroot=$dir_prefix.\n";
    print "#   quiet=$quiet.\n";
    print "#   verbose=$verbose.\n";
}
    
    
#-----------------------------------------------------#
# Identify dataset names and write to standard output #
#-----------------------------------------------------#

# change working directory to the dataroot, to help avoid problems in those
# operating systems that have a shorter maximum pathname length (i.e., Mac OS X)
my $save_cwd = getcwd();
chdir $dir_prefix;


# repeat for each file in the dataroot
my @allfiles = glob "*";
@allfiles = sort @allfiles;

foreach my $ds (@allfiles)
{
	if (-e "$ds/$clufilename")
	{
    	print "$ds\n" ;
    	
    	# check for zero length cluster file
    	print "# Warning: $ds/$clufilename has zero length.\n"
    		if (-z "$ds/$clufilename");
    		
    	# print clustering statistics
    	if ($verbose && (-e "$ds/$statsfilename"))
    	{
    		open STATS, "$ds/$statsfilename"
    			or die "Error: Could not open statistics file $ds/$statsfilename ($!)";
    		my @lines = <STATS>;
    		close STATS
    			or die "Error: Could not close statistics file $ds/$statsfilename ($!)";
    		my $linesPrinted = 0;
    		for (my $i = 1; $i < @lines; $i++)
    		{
    			print "#" if ($linesPrinted++ == 0);
    			my $line = $lines[$i];
    			chomp $line;
    			my ($statName, $statVal) = split "\t", $line, 2;
    			print " $statName=" if (defined $statName);
    			print "$statVal" if (defined $statVal);
    		}
    		print "\n";
    	}
    }
}


# restore working directory
chdir $save_cwd;
