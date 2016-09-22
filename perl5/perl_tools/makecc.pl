#!/usr/bin/perl

# makecc: Make cluster compendium.

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

# See sub cg_printHelpInfo for usage information.
#
# Version History
#   v1.2    2007-03-08: Implemented option --dssuffix. Fixed bug in printing 
#           execution time (added "use POSIX;").
#   v1.1    2007-03-03: Implemented options --datalinecomments, --noincludecomments,
#           and --quiet (-q). Updated and fixed comments and help information.
#           Fixed file version information. Updated informational comments.
#   v1.0    2006-11-21: Print version and execution information to compendium file
#           instead of STDERR under control of --verbose; the --verbose option no
#           longer has any effect. 
#           Fixed a bug in recognizing comment lines (any line containing # was
#           considered a comment line).
#           Copy comment lines from input files to compendium file with a prepended
#           # character.
#           Other minor code changes. (DMN)
#   v0.4    2006-10-18: Support comments in cluster files. (DMN)
#   v0.3    2006-10-09: Fixed a bug in processing dataset names. (DMN)
#   v0.2    2006-10-04: Major cleanup. (DMN)
#   v0.1    2006-10-04: Initial version. Based on cluegene.pl v1.1. (DMN)


use strict;
use Cwd;
use POSIX;      # for strftime
 

# version information
my $makeccversion = "1.2";
my $datasetlistfileversion = "1.0"; # dataset list file version
my $clusterfileversion = "1.0"; # cluster file version
my $ccfileversion = "1.0";      # cluster compendium file version


##################################################
# sub cg_printHelpInfo                           #
# Print help information to the standard output. #
##################################################

sub cg_printHelpInfo
{
    print "\nMake Cluster Compendium Help Information\n";
    print "========================================\n\n";
    print "Make a cluster compendium.\n";
    print "makecc.pl version $makeccversion (a component of the ClueGene pipeline).\n\n";
    print "The cluster compendium is written to the standard output.\n\n";
    print "Command Line Options\n";
    print "--------------------\n";
    print "--clufilename <filename>\n";
    print "  Specifies the name of the cluster file found in each dataset\n";
    print "  directory. This may be a pathname.\n";
    print "  If not specified: Network/Corr/Modes/data.tab is used.\n";
    print "  See also --dataroot and --datasets.\n";
    print "--datalinecomments\n";
    print "  Specifies that the first \"#\" character in a data line introduces a\n";
    print "  comment that terminates at the end of the line.\n";
    print "--dataroot <dirname>\n";
    print "  Specifies the directory where the dataset data files are located.\n";
    print "  If not specified: /projects/sysbio/map/Data/Expression/Yeast is\n";
    print "  used (this is the S. cerevisiae dataset directory for UCSC SoE servers).\n";
    print "  See also --clufilename and --datasets.\n";
    print "--datasets <filename>\n";
    print "  Specifies the name of a file containing the dataset names. If this\n";
    print "  option is not supplied, the datasets default to the 44 used for the\n";
    print "  PSB 2007 paper.\n";
    print "  A dataset name is a directory name found in the dataroot.\n";
    print "  See also --clufilename, and --dataroot.\n";
    print "--dssuffix <string>\n";
    print "  Specifies a suffix appended to the end of the dataset name, for a\n";
    print "  user-specified data set qualifier.\n";
    print "--help (-h)\n";
    print "  Print help information and exit.\n";
    print "--noincludecomments\n";
    print "  Specifies that comment lines from input files are not to be copied to\n";
    print "  the output.\n";
    print "  If not specified, comments are copied from input to output.\n";
    print "--quiet (-q)\n";
    print "  Quiet mode: suppress generation of informational comments.\n";
    print "--verbose (-v)\n";
    print "  Print verbose information. Not currently used.\n\n";
    print "Please cite the following article when using ClueGene:\n";
    print "  Ng DM, Woehrmann MH, Stuart JM.\n";
    print "  Recommending Pathway Genes Using a Compendium of Clustering Solutions.\n";
    print "  Pacific Symposium on Biocomputing 12:379-390(2007).\n";
    print "  Article: http://psb.stanford.edu/psb-online/proceedings/psb07/ng.pdf\n";
    print "  Online Supplement: http://sysbio.soe.ucsc.edu/cluegene/psb07/\n\n";
}


# if true, write verbose trace information to the standard error
my $verbose = 0;

# name of file containing dataset names
my $dataset_filename = "";

# path to the Saccharomyces cerevisiae datasets
my $dir_prefix = "/projects/sysbio/map/Data/Expression/Yeast";

# if true, help information requested
my $print_help = 0;
        
# filename of the data file within the dataset directory (same for
# each dataset)
my $clufilename = "Network/Corr/Modes/data.tab";

# string to separate cluster id and dataset name in qualified cluster id
my $cluid_dataset_sep = "@";

# if true, allow an embedded "#" in a data line to introduce a comment
my $datalinecomments = 0; 

# if true, do not propagate comments from input to output
my $noincludecomments = 0; 

# if true, quiet mode printing (i.e., no informational comments)
my $quiet = 0;

# dataset suffix
my $dssuffix = "";


#-----------------#
# Process options #
#-----------------#
    
use Getopt::Long;

GetOptions(
    'clufilename=s'     => \$clufilename,
    'datalinecomments'  => \$datalinecomments,
    'dataroot=s'        => \$dir_prefix,
    'datasets=s'        => \$dataset_filename,
    'dssuffix=s'        => \$dssuffix,
    'h|help'            => \$print_help,
    'noincludecomments' => \$noincludecomments,
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
    print "# Make Cluster Compendium: makecc.pl version $makeccversion (a component of the ClueGene pipeline).\n";
    print strftime "# Generated on %a %Y-%m-%d %H:%M:%S %Z.\n", localtime;
    print "# Input: Dataset list file version $datasetlistfileversion.\n";
    print "# Input: Cluster file version $clusterfileversion.\n";
    print "# Output: Cluster compendium file version $ccfileversion.\n";
    print "# Options:\n";
    print "#   clufilename=$clufilename.\n";
    print "#   datalinecomments=$datalinecomments.\n";
    print "#   dataroot=$dir_prefix.\n";
    print "#   datasets=$dataset_filename.\n";
    print "#   dssuffix=$dssuffix.\n";
    print "#   noincludecomments=$noincludecomments.\n";
    print "#   quiet=$quiet.\n";
    print "#   sep=$cluid_dataset_sep.\n";
    print "#   verbose=$verbose.\n";
}
    
    
#-------------------#
# Get dataset names #
#-------------------#

# directory names for the Saccharomyces cerevisiae datasets
my @datasets;

if ($dataset_filename eq "")
{
    # dataset filename not specified, use default datasets  
    # the current 44 datasets (used for PSB 2007 paper)
    @datasets=(
        "Belli04", "Boer05", "Brem02", "Brem02b", "Brem05", 
        "Bro03", "Bulik03", "Caba05", "Chu98", "DeRisi97", 
        "Eriksson05", "Ferea99", "Fry03", "Gasch00", "Gasch01", 
        "Gross00", "Hughes00", "Iyer01", "Jin04", "Jones03", 
        "Lee05", "Lieb01", "Martin04", "Miyake04", "Ogawa00", 
        "Orlandi04", "Pitkanen04", "Prinz04", "Rodriguez-Navarro04", "Rudra05", 
        "Sabet04", "Sapra04", "Schawalder04", "Segal03", "Segal03b", 
        "Segal03c", "Spellman98", "Sudarsanam00", "Tai05", "Takagi05", 
        "Wang02", "Yamamoto05", "Yvert03", "Zhu00");
    
    if (0)
    {
        # the original 12 datasets (used for CSB 2006 extended abstract)
        @datasets=("Zhu00","Wang02","Sudarsanam00","Spellman98","Lieb01","Iyer01",
                   "Hughes00","Gross00","Gasch01","Gasch00","DeRisi97","Chu98");
    }
}
else
{
    # get dataset names from the specified file
    
    open(DS, $dataset_filename)
        || die "Error: could not open dataset file \"$dataset_filename\": $!";
        
    # repeat for each line of the dataset names file (each line has data for one cluster)
    my $numds = 0;
    while (my $line = <DS>) 
    {
        #------------------------#
        # handle a non-data line #
        #------------------------#
        
        if ($line =~ /^\s*#/)
        {
            # a comment line, copy to output and otherwise ignore
            print "#$line" if !$noincludecomments;
            next;
        }
        elsif ($line =~ /^\s*$/)
        {
            # ignore a blank line
            next;
        }
        
        #----------------------------#
        # handle a dataset name line #
        #----------------------------#
    
        if ($datalinecomments && $line =~ /#/)
        {
            # data line comments are enabled, and data line contains an embedded "#"
            # remove the comment
            $line =~ /(^.*?)#/;     # minimal match (?) to find first #
            $line = $1;
        }
        
        chomp $line;
        $line =~ /^\s*(\S+)/;
        $datasets[$numds++] = $1;
    }       
    
    close(DS);
}

@datasets = sort @datasets;
    
my $num_data_sets = scalar(@datasets);
if ($num_data_sets <= 0)
{
    die "Error: no datasets were specified";
}

# print dataset names
print "# Dataset names:@datasets.\n" if (!$quiet);


#----------------------------------------------------------------------#
# Read pre-clustered gene sets and write compendium to standard output #
#----------------------------------------------------------------------#

# change working directory to the dataroot, to help avoid problems in those
# operating systems that have a shorter maximum pathname length (i.e., Mac OS X)
my $save_cwd = getcwd();
chdir $dir_prefix;

# repeat for each dataset directory
for (my $d = 0; $d < @datasets; $d++) 
{
    my $ds = $datasets[$d];
    
    if (!open(D, "$dir_prefix/$ds/$clufilename"))
    {
        # an error was detected
        die "Error: cannot open file $dir_prefix/$ds/$clufilename\n";
    }
    
    # repeat for each line of the dataset file (each line has data for one cluster)
    while (my $line = <D>) 
    {
        #------------------------#
        # handle a non-data line #
        #------------------------#
        
        if ($line =~ /^\s*#/)
        {
            # a comment line, copy to output and otherwise ignore
            print "#$line" if !$noincludecomments;
            next;
        }
        elsif ($line =~ /^\s*$/)
        {
            # ignore a blank line
            next;
        }
        
        #--------------------#
        # handle a data line #
        #--------------------#
    
        if ($datalinecomments && $line =~ /#/)
        {
            # data line comments are enabled, and data line contains an embedded "#"
            # remove the comment
            $line =~ /(^.*?)#/;     # minimal match (?) to find first #
            $line = $1;
        }
    
        # qualify the cluster id with the dataset name and an optional suffix
        # (with a separator) and write to compendium file (i.e., standard output)
        $line =~ s/\t/$cluid_dataset_sep$ds$dssuffix\t/;
        print $line;
    }
    
    close(D);
}

# restore working directory
chdir $save_cwd;
