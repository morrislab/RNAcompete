#!/usr/bin/perl

# histogram R plot
# by Alex Williams
# March 2008


use warnings;
use strict;
use diagnostics;
use Getopt::Long;
use File::Basename;

my $rCommandFilename = "R-commands.R.tmp";
my $R_EXE            = "R ";
my $R_PARAMETERS     = " --quiet --vanilla ";

my $verbose = 0;
my $delim = q{\t};
my $missingValString = undef;
my $rCommands = '';
my $NO_COMMENTS = q{''};
my $additionalCommands = '';

sub printUsage() {
    print STDOUT <DATA>;
}

# ==1==
sub main() { # Main program
    my ($delim) = "\t";
    
    GetOptions("help|?|man"     => sub { printUsage(); exit(0); }
			   , "delim|d=s"    => \$delim
			   , "e=s"          => \$additionalCommands
			   , "R-EXE=s"      => \$R_EXE
			   , "v|verbose!"   => \$verbose
			   , "na|missing=s" => \$missingValString
	       ) or printUsage();
	
	my $naString = (defined($missingValString)) ? qq{"$missingValString"} : qq{c("NA", "ND")};
	
	$rCommands .= qq{
		x <- as.matrix(read.table(
						file = "/dev/stdin"
						, header = FALSE
						, row.names = NULL
						, fill = TRUE
						, sep="${delim}"
						, stringsAsFactors = FALSE
						, na.strings=$naString
						, blank.lines.skip = TRUE
                        , quote = ""
						, comment.char = $NO_COMMENTS
								  ));
		$additionalCommands
	};

	if (scalar(@ARGV) >= 1) {
		print "\nERROR: Some arguments were not understood:\n";
		foreach (@ARGV) {
			print "Not-understood argument: $_\n";
		}
		die "\nRemember that the syntax is: quick_r.pl -e 'YOUR_R_COMMANDS' < FILE\ncheck the examples with quick_r.pl --help.\n\n"
	}

	my $numLinesToNotDisplay = ($rCommands =~ tr/\n/\n/);;
	if ($verbose) {
		# Show the user which command were run, if it was run verbosely
		$numLinesToNotDisplay = 0;
	}

	open(FILE, "> $rCommandFilename"); {
		print FILE $rCommands;
	} close(FILE);
	
	my $R_COMMAND_LINE_RUN = $R_EXE . ' ' . $R_PARAMETERS;
	system("${R_COMMAND_LINE_RUN} --file=${rCommandFilename} | tail -n +$numLinesToNotDisplay");
	
} # end main()


main();

exit(0);
# ====

__DATA__

quick_r.pl -e "R COMMAND GOES HERE" < INPUTFILE
or
cat INPUTFILE | quick_r.pl -e "R COMMAND"

INPUTFILE must *NOT* have any column or row headers!

Reads the file into a matrix of numbers named "x".
Then runs the specified R command on "x".

x[N,] is the Nth horizontal row. Numbering starts at 1.
x[,N] is the Nth vertical column. Numbering starts at 1.

Example:
   cat MY_FILE | quick_r.pl -d ',' -e "summary(x[5,])"
 summarizes the 5th row out of MY_FILE.

It will not work on a file with a header line or row headers,
so you should use "cut -f 2-" and "tail +2" to remove
column and row headers from your file.

CAVEATS:

Non-numeric data can confuse R. R will think every number is a character string,
rather than a number. So if you want to operate on a mixed-data file,
you can either:

 1. Use cut -f ...  and head / tail to cut out the numeric data that you want
 2. Or use as.numeric(...) to make the data numeric ("your.function( as.numeric( x[R,C] ) )")

OPTIONS:

-d 'delimiter' (default: tab)

-v
	Verbose. Default: OFF. Prints the command that was just run,
	before it prints the results. Default only prints results.

--na="NA_STRING" (default: "NA")
	This is the field value used to specify missing values.

--R-EXE="path/to/other/R/exe" (default: "R")
	Lets you override the default R.

Examples:

If MY_FILE looks like:
1,2,3
4,5,6   <-- (comma-separated-value file: note that this is
7,8,9        not the default we expect)

Then:
   cat MY_FILE | quick_r.pl -d ',' -e "shapiro.test(x[1,])"
will test for normality of "1 2 3"

x[N,] is the Nth row (here x[1,] "1 2 3")
x[,N] is the Nth column (here x[,1] is "1 4 7")

Example #2:

cat MY_FILE | quick_r.pl -d ',' -e "summary(x)"

Example #3:

If HAS_HEADER_FILE (tab-delimited) looks like this:
GENES     TEST1     TEST2     TEST3
geneA     4.3       2.5       4.2
geneB     1.4       1.2       3.1
geneC     1.2       5.3       4.3

Then you will need to use cut and tail to get it into
the proper format, like this:

cat HAS_HEADER_FILE | tail +2 | cut -f 2- | quick_r.pl -e "summary(x)"

How to use sapply (R command):
   sapply (1:nrow(x),function(i) { c(rownames(x)[i], mean(x[i,])); } )

-- end of quick_r.pl help --
