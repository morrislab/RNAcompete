#!/usr/bin/perl -w

use strict;
use Getopt::Long;

# Check the __DATA__ at the bottom of this source file for usage information!
# Alex Williams

sub printUsage {
    print STDERR <DATA>; # at the bottom of the file...
    exit(1);
}

my $key_col_1 = 1;
my $key_col_file_2  = 1;
my $value_col_file_2 = 2;

my $srcFilename = '-';
my $mappingFilename = '~/Map/Data/Gene/Description/Yeast/data.tab'; # default

GetOptions("help|?|man" => sub { printUsage(); }
	   , "s|source=s" => \$srcFilename
	   , "m|mapping=s" => \$mappingFilename
	   , "k1=i" => \$key_col_1  # Key 1
	   , "k2=i" => \$key_col_file_2   # Key 2 (second file)
	   , "v2=i" => \$value_col_file_2  # Value 2 (value in second file)
	   ) or printUsage();

# $(MAPDIR)/Data/Gene/Description/Yeast/data.tab \


system("join.pl -skip -1 $key_col_1 -2 $key_col_file_2 -ob -s1 -u $srcFilename $mappingFilename "
       . "| cut -f 1," . ($value_col_file_2 + 1)
       . "| awk '{ \$\$0 = \$\$0\"\t\"\$\$0 } {print}' "
       . "| sed 's/\t\t/\t/g' "
       . "| cut -f 2 ");

__DATA__
syntax: translate_column.pl [OPTIONS] SOURCE_FILE MAPPING_FILE

    This script is used for replacing ORFs with their corresponding
    gene names.  The inputs are:

    1. a SOURCE_FILE (which can also be '-' for STDIN). This is a
       tab-delimited file with the ORFs (or other data to translate)
       in a column. The column they are in is specified by -k1=NUMBER
       (k1 = "key 1").

    2. a MAPPING_FILE which has a list of ORFs and the genes they
       correspond to. The ORFs must be in one column, and
       correspondings genes in another column. For yeast, we have this
       data in $(MAPDIR)/Data/Gene/Description/Yeast/data.tab . Choose
       the column with the ORF in it with -k2=NUMBER (k2 = "key 2")
       and choose the column with the corresponding gene name with
       -v2=NUMBER (v2 = "value 2").

    The output is to STDOUT, and is a single-column file with the ORFs
    (or gene names, if a mapping was found) in a column. If an ORF had
    a gene name in the mapping file, then the gene name is printed
    out; otherwise, the original ORF name is printed out exactly as it
    was read in.

OPTIONS are:

--help: Displays this screen

-s = FILE Choose the source file. Can also be '-' or --source = FILE

-m = FILE Choose the mapping file (the file with ORF->gene mappings)
or --mapping = FILE

-k1 = COL_INDEX Choose the column that has the ORF name in the source
 file. Starts numbering at 1 (not zero).

-k2 = COL_INDEX Choose the column that has the ORF name in the mapping
 file. Starts numbering at 1 (not zero).

-v2 = COL_INDEX Choose the column that has the gene name in the
 mapping file. Starts numbering at 1 (not zero).


EXAMPLE:
    translate_column.pl -s=my_file -m=map_file -k1=2 -k2=3 -v2=4

You would see this if "my_file" were:

something <TAB> ORF_1 something <TAB> ORF_2 something <TAB> ORF_3

...and "map_file" were:

something <TAB> else <TAB> ORF_1 <TAB> GENE_NAME_1
something <TAB> else <TAB> ORF_2 <TAB> GENE_NAME_2

Note that in this example, the output will be:

GENE_NAME_1
GENE_NAME_2
ORF_3

///because ORF_3 doesn't have a corresponding mapping in the map_file.

