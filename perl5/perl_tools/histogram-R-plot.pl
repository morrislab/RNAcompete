#!/usr/bin/perl

# histogram R plot
# by Alex Williams
# March 2008


use warnings;
use strict;
use Getopt::Long;
use File::Basename;

my $dataColumn       = 1;
my $NO_COMMENTS      = q{""};
my $rCommandFilename = "RCMD.R.tmp";
my $inputFilename    = undef;
my $fillColors       = "#FF000088 #00FF0088 #0000FF88 #FFFF0088 #FF00FF88 #00FFFF88 #88888888";
my $R_EXE            = "R ";
my $R_PARAMETERS     = " --quiet --vanilla ";
my $R_COMMAND_LINE_RUN = $R_EXE . ' ' . $R_PARAMETERS;

my $xLabel = undef;
my $yLabel = undef;
my $xLim = undef;
my $yLim = undef;
my $title = undef;
my $outputFilename = undef;
my $delim = q{\t};
my $missingValString = "NA";
my $logNData = undef;
my $breaksValue = undef;
my $onlyHist = 0; # should we ONLY print the histogram and no other information?
my $hasHeader = "FALSE";

my $pdf = 1; # default
my $png = 0;

my $rCommands = '';

my $plotProbabilityDensityRatherThanCounts = undef;
my $histAdditionalOptions = '';

sub printUsage() {
    print STDOUT <DATA>;
}



# ==1==
sub main() { # Main program
    my ($delim) = "\t";
    
    GetOptions("help|?|man" => sub { printUsage(); exit(0); }
			   , "nh|noheader|no-header" => sub { $hasHeader = "FALSE"; }
			   , "header" => sub { $hasHeader = "TRUE"; }
			   , "k=i" => \$dataColumn
			   , "delim|d=s" => \$delim
			   , "log=f"  => \$logNData
			   , "log10"  => sub { $logNData = 10; }
			   , "log2"   => sub { $logNData = 2; }
			   , "xlab=s" => \$xLabel
			   , "ylab=s" => \$yLabel
			   , "xlim=s" => \$xLim
			   , "ylim=s" => \$yLim
			   , "title=s" => \$title
			   , "PDF|pdf"     => sub { $pdf = 1; $png = 0; }
			   , "PNG|png"     => sub { $png = 1; $pdf = 0; }
			   , "b|breaks=s" => \$breaksValue
			   , "p|probability" => sub { $plotProbabilityDensityRatherThanCounts = 1; $histAdditionalOptions .= ", freq = FALSE"; }
			   , "i|input=s" => \$inputFilename      # <-- may be multiple files (separated by SPACES)
			   , "o|output=s" => \$outputFilename
			   , "R-EXE=s" => \$R_EXE
			   , "d|delim=s" => \$delim
			   , "c|color|colors=s" => \$fillColors
			   , "na|missing=s"  => \$missingValString
			   , "onlyhist!"      => \$onlyHist   # <-- don't print the "rug" or the lines--good for very large datasets
	       ) or printUsage();

	print "Unprocessed by Getopt::Long\n" if $ARGV[0];
	foreach (@ARGV) {
		print "$_\n";
	}

	if (!defined($outputFilename) || (length($outputFilename) == 0)) {
		if ($pdf) {
			$outputFilename = "histogram.pdf";
		} elsif ($png) {
			$outputFilename = "histogram.png";
		} else {
			die "No output format (PNG / PDF) specified.\n";
		}
	}

	if (defined($breaksValue) && $breaksValue) {
		$histAdditionalOptions .= ", breaks = $breaksValue";
	}

	if (!$inputFilename) {
		my $errorMsg = "Error in arguments to histogram-R-plot.pl! You must specify at least one input file with --input=FILENAME.\n\n";
		print $errorMsg; printUsage(); die $errorMsg;
	}

	my @inputDataFiles = split(/ /, $inputFilename);
	my @graphColors    = split(/ /, $fillColors);
	
	print STDERR "Status message from histogram-R-plot.pl: Outputting the histogram to the file $outputFilename.\n";

	if (!defined($title) && defined($inputFilename)) { $title = "Data from: $inputFilename"; }

# ====================================

	if ($pdf) {
		$rCommands .= qq{ pdf("$outputFilename"); };
	} elsif ($png) {
		$rCommands .= qq{ bitmap("$outputFilename", width=8, height=8, res=150); };
	}


$rCommands .= <<INITIAL_COMMAND_LIST_END

INITIAL_COMMAND_LIST_END
	; # ====================================

for (my $i = 0; $i < scalar(@inputDataFiles); $i++) {
	my $adding = (0 == $i) ? "FALSE" : "TRUE";

	my $thisGraphColor = ($i < scalar(@graphColors) && defined( $graphColors[$i] ) && uc($graphColors[$i]) ne "NULL" )
		? "\"$graphColors[$i]\""
		: "NULL"; # NULL means no fill / wireframe only
	
	my $xLimStr = ($xLim) ? ", xlim = $xLim" : '';
	my $yLimStr = ($yLim) ? ", ylim = $yLim" : '';

	my $dataStr = qq{data${i}[,$dataColumn]};

	if (!defined($xLabel)) {
		if (defined($logNData) && $logNData) {
			$xLabel = "log_$logNData(X)";
		} else {
			$xLabel = "X";
		}
	}
	if (!defined($yLabel)) {
		if (defined($plotProbabilityDensityRatherThanCounts) && $plotProbabilityDensityRatherThanCounts) {
			$yLabel = "Probability Density";
		} else {
			$yLabel = "Raw Counts";
		}
	}

	if (defined($logNData) && $logNData) {
		$dataStr = "logb($dataStr, base = $logNData)"; # log-transform the data
	}

# ====================================
	$rCommands .= <<COMMAND_LIST_END

data${i} <- read.table(
				     file = "$inputDataFiles[$i]"
				   , header = $hasHeader
				   , row.names = NULL
				   , fill = TRUE
				   , sep="${delim}"
				   , na.strings="$missingValString"
				   , blank.lines.skip = TRUE
				   , comment.char = $NO_COMMENTS
				   );

#data${i};
#summary(data${i}[,$dataColumn]);
#data${i}[,$dataColumn];

hist($dataStr,
	 main = "$title"
	 , xlab = "$xLabel"
	 , ylab = "$yLabel"
	 $xLimStr
	 $yLimStr
	 , col = $thisGraphColor
	 , border = "black"
	 , add = $adding
	 , include.lowest = TRUE
	 $histAdditionalOptions
	 );

COMMAND_LIST_END
; # ===============================

if (not $onlyHist) {
	
	$rCommands .= <<COMMAND_LIST_END

lines(density(
			    $dataStr
			  , bw=0.1
			  , na.rm = TRUE)
	  , col = "black"
	  );

rug($dataStr
	, side=1
	, col = $thisGraphColor
	);
# for "rug", side = 3 means "top"

COMMAND_LIST_END
; # ====================================

} # end of "if not $onlyHist"


} # end of "for each data file"

# ====================================
$rCommands .= <<FINAL_COMMANDS_LIST_END

dev.off();

FINAL_COMMANDS_LIST_END
	; # ====================================







	open(FILE, "> $rCommandFilename"); {
		print FILE $rCommands;
	} close(FILE);
	
	
	system("${R_COMMAND_LINE_RUN} --file=${rCommandFilename}");
	
	
} # end main()


main();

exit(0);
# ====

__DATA__

histogram-R-plot.pl --input=FILENAME --output=OUTNAME [OPTIONS}

Takes a list of data points from FILENAME and plots it as a histogram in R.
By default, it saves the resulting histogram as a PDF, unless you
specify --png to save it as a PNG-format image.

INPUT OPTIONS:

-i <FILENAME(S)> or --input=<FILENAME(S)>
	What are the file(s) we want to plot?
    Note: multiple files are space-delimited, so filenames cannot contain spaces.
    Example:
	--input="file1 file2 file3 anotherfile"
	or --input=onlyfile
	If you just specify a single file, then it will plot that file.
	If you specify multiple files, they will be plotted over
	the first histogram (the first file is the one that determines the scale of the graph).

-k <COLUMN WITH DATA>
	Specify the column with data in it. Default is 1.

--delim=<DELIMITER>   or  -d <DELIMITER>   (Default: tab)
	Set the delimiter between columns in the input data file.

--na="STRING" or --missing="STRING"  (default: NA)
	Set the missing value string for the input file (skip over anything with this value).
	For example, --na=NONE or --na=NaN.

--header (default: no header)
	Indicate that this file DOES have a single header line. By default we assume no header lines.
	If you have multiple files, they must either all have a header, or all have no header!

OUTPUT OPTIONS:

-o <FILENAME> or --output=<FILENAME>
	What should our output filename be?
	Default is "histogram.pdf"

--pdf: Output to PDF format (default)
	PDF is vector-based, and is good for high-resolution figures. You can zoom in as much as you want.

--png: Output in PNG image format
	PNG is an image, and is good for the web. PNGs will become pixelated when you zoom in.

--onlyhist  (Default: OFF)
	Plot ONLY the histogram, and not the "rug" or lines. Useful for very large data sets, where plotting
	every data point would take too long (and make a PDF file that was too large).

-b <BREAK_VALUE>  or --breaks=<BREAK_VALUE>
	(From the R docs) A break value can be either:
        1. a vector giving the breakpoints between histogram cells (in R format)
                      Example: --breaks="c(-10,0,10,20,30)"
	    Note that in this case, you MUST span every data point, or else
	    you get an error (and no plot).
	Or: 2. a single number giving the number of cells for the histogram,
                      Example: --breaks=25
	    Note that this number is treated as a *suggestion* only by R.

--xlab=CUSTOM_X_AXIS_LABEL
	Set a custom X-axis label. Use "\n" to include newlines.

--ylab=CUSTOM_Y_AXIS_LABEL
	Set a custom Y-axis label. Use "\n" to include newlines.

--title=CUSTOM_HISTOGRAM_TITLE
	Set a custom title for the graph.

--log=<NUMBER>   (shorthand: --log10  --log2)
	Log-transform the data before plotting it to the histogram.
    Examples:  --log=2.71828 (ln)   --log2 (shorthand for --log=2)

--xlim="c(lower_limit, upper_limit)" and   (Default: R automatically chooses
--ylim="c(lower_limit, upper_limit)"          bounds based on the first histogram data)
	Set the X-axis and Y-axis bounds. To specify that the X-axis goes from -10 to +20,
	you say:  --xlim="c(-10,20)"

-c "String of colors"  or  --colors="String of colors"
	Color of the graph. Default: colors chosen automatically.
	Set --colors="NULL" to disable colors completely.
    Examples:
	--colors="red"
      will make the first histogram red. Any remaining histograms will be uncolored.
	--colors="#FF000022 #00FF0055 #0000FFFF"
      will make the first histogram a very transparent red, the second one
      a transparent green, and the last one an opaque blue.
	--colors="red blue green purple"
	  will specify the colors for the first four histograms.
	  The hexadecimal color format for the colors is: #RRGGBBAA,
	  where RR is the red value from 00 to FF in hex, GG is the green value,
	  BB is the blue value, and AA is the transparency ("alpha"), with 00 being
	  completely transparent and FF being completely opaque.
	  The hex scale is like this: 0-1-2-3-4-5-6-7-8-9-A-B-C-D-E-F (F is "15" in decimal)

-p or --probability   (Default: OFF (plot counts instead) )
	Plot the probability density rather than the raw counts. Results in a graph
	where the area under the histogram sums to 1.0.

R-SPECIFIC OPTIONS:

--R-EXE=<LOCATION_OF_CUSTOM_R_EXECUTABLE>
	Override the default location of R.

OTHER OPTIONS:

--help
	Prints this page


EXAMPLE USAGE:

You have two data files that look like:

First file (r.tab)   Second file (s.tab)
 |                     | (this file has no header!)
 v                     v
Growth_Rates         34.1
42.2                 21.7
41.1                 11.1
1.23                 10.5
4.52
NO_GROWTH
4.21
2.1
NO_GROWTH

Now if you want to just plot the first file, without any color, you say:

histogram-R-plot.pl --input=r.tab --xlab="Growth Rate" --na="NO_GROWTH" --header \
                    --colors="NULL" --output=TEST_OUTPUT_1.pdf

If you want to plot the first and second file on the same histogram, but with
the first file as blue and the second file plotted as red, you have a slight 
problem--the first file has a header, but the second file does not.
So remove the string "Growth_Rates" from the first file, and then type:

histogram-R-plot.pl --input="r.tab s.tab" --na="NO_GROWTH" --no-header \
                    --colors="#0000FF77 #FF000077" --output=TEST_OUT_2.pdf

(The "77" at the end of the color strings means we are making the bars partially transparent.
If you did not care about transparency, you could just say --colors="blue red" to make it more concise.)

-- End of examples

Note: If you want other plotting options besides the histogram, check out "plot.R,"
which is located in CVS_ROOT/lab_apps/R_shell/plot.R . It handles scatterplots and other plots.
