#!/usr/bin/perl

# By Alex Williams, November 2007.

use warnings;
use strict;

use File::Basename;
use Getopt::Long;

use POSIX qw(ceil floor); # import the ceil(ing) and floor functions for handling fractions/integers
use List::Util qw(max min); # import the max and min functions

use Term::ANSIColor;

use constant LEFT_ALIGN   => 1;
use constant RIGHT_ALIGN  => 2;
use constant CENTER_ALIGN => 3;
use constant AUTO_ALIGN   => 4;

my $outputIsColorTerminal = (-t STDOUT);

my @maxLen = (); # max length we've seen so far in this column

my $truncLen = undef; # <-- columns can be no longer than this length

my ($truncationIndicationSuffix) = "..."; # Goes on the end of truncated text.


my $terminal_height_in_lines = `tput lines`; # <-- not portable to non-UNIX
#my $terminal_width = `tput cols`; # <-- not portable to non-UNIX

my $headerReprintInterval = undef; # <-- print out the buffer, and reprint the header every so often, as specified here. Cell widths are recalculated at this frequency as well.

my $highlightThreshold = undef; # <-- highlight anything that meets this cutoff


my $printHeaderOnlyOnce = 0;

my $previousLineAlignment = RIGHT_ALIGN; # how was the *previous* line aligned? This is used so that "NA" and "ND" get aligned like numbers when they are in number columns. Note that this will mistakenly align the top line to the right even if all subsequent items are text (and thus, left-aligned)

my @buffer = (); # <-- a 2d array of all the tab-delimited items we read in

my @header = (); # <-- the header line is special, because it can be printed over and over

my $HORIZONTAL_DELIMITER = " | ";

my $neverColorNoMatterWhat = 0;

sub printUsage() {
    print STDOUT <DATA>;
    exit(0);
}

sub isNonNegativeInt($) {
  return ($_[0] =~ /[0-9]+/);
}


sub readInputFile($$$) {
	# Note: reads GZipped and regular files
	# transparently (based on file extension)
	my ($filename) = @_;
	my $reader = undef;
	if ($filename =~ /\.gz$/) {
		$reader = 'zcat';
	} else {
		$reader = 'cat';
	}
	my $dat = `$reader $filename`; # <-- might be gzipped, hence $reader
	my @arr = split(/\n/, $dat);
	my @matrix = [];
	for (my $i = 0; $i < scalar(@arr); $i++) {
		my $lineStr = $arr[$i];
		chomp($lineStr);
	}
}


sub printColorIfOutputIsTerminal($) {
	my ($theColor) = @_;
	if (!$neverColorNoMatterWhat && $outputIsColorTerminal) {  #   -t STDOUT
		print color($theColor);
	}
}

sub truncatedVersion($) { # returns a COPY of the truncated-length item
  # Parameter "item": a string to truncate to fewer characters, based on
  # the global variable $truncLen. This is used to fit text inside properly-sized boxes.
  my ($item) = @_;
  my ($ret);

  if (defined($truncLen)) {
	if (($truncLen - length($truncationIndicationSuffix) > 0) && (length($item) >= $truncLen)) {
	  my $lenWithSuffix = $truncLen - length($truncationIndicationSuffix);
	  $ret = substr($item, 0, $lenWithSuffix) . $truncationIndicationSuffix;
	} else {
	  $ret = substr($item, 0, $truncLen);
	}
  } else {
	$ret = $item;
  }

  if (defined($highlightThreshold)) {
	if (isNumeric($item)) {
	  my $x = sub($$) { my ($val, $thresh) = @_; return ($val >= $thresh); };
	  if ($x->($item, $highlightThreshold)) { # show things greater than or equal to a certain amount as "interesting"
		$ret = "** " . $item . " **";
	  }
	}
  }
  return $ret;
}


sub isNumeric($) {
  my ($x) = @_;
  return (($x =~ /^-?[0-9.,eE^]+$/) && ($x =~ /[0-9]/)); #item has at least one number, and only has numeric-related items, OR the star, which we use to mark interesting items
}

sub isStarred($) {
  my ($x) = @_;
  return ($x =~ /^[*]/);
}

sub printSingleArrayLine($$$$) {
  my ($ptrToSingleDimentionalArray, $ptrToMaxLenArray, $alignment, $colorToPrint) = @_;
  for (my $col = 0; $col < scalar(@$ptrToMaxLenArray); $col++) {
	my $item = (defined(${$ptrToSingleDimentionalArray}[$col])) ?    ${$ptrToSingleDimentionalArray}[$col]   : '';
	if (defined($truncLen)) { $item = truncatedVersion($item); }

	my $howToAlign;
	if (AUTO_ALIGN == $alignment) {
	  if (isNumeric($item) || isStarred($item)) {
		$howToAlign = RIGHT_ALIGN; # it's a number! let's right-align it
	  } elsif ($item =~ /^N[DA]/i) {
		$howToAlign = $previousLineAlignment; # align NA and ND like the previous line--this way we take care of NA values (except at the very top)
	  } else {
		$howToAlign = LEFT_ALIGN; # not a number, and not ND or NA! let's left-align it
	  }
	} else {
	  $howToAlign = $alignment;
	}
		
	$previousLineAlignment = $howToAlign;


	my $lengthOfThisItem = (defined($item)) ?   length($item)   :   0;
	my $maxLengthThisColumn = (defined(${$ptrToMaxLenArray}[$col])) ?   ${$ptrToMaxLenArray}[$col]   :   $lengthOfThisItem;
	my $numSpacesToPad = $maxLengthThisColumn - $lengthOfThisItem;
	#print "Need to pad with $numSpacesToPad spaces for column $col.\n";

	if (defined($colorToPrint) && $colorToPrint) {
	  printColorIfOutputIsTerminal($colorToPrint);
	}

	if (LEFT_ALIGN == $howToAlign) {
	  print ("$item" . (' ' x $numSpacesToPad));
	} elsif (RIGHT_ALIGN == $howToAlign) {
	  print ((' ' x $numSpacesToPad) . "$item");
	} elsif (CENTER_ALIGN == $howToAlign) {
	  my $beforeSpaces = floor($numSpacesToPad / 2);
	  my $afterSpaces  = $numSpacesToPad - $beforeSpaces;
	  print ((' ' x $beforeSpaces) . $item . (' ' x $afterSpaces));
	} else {
	  die "Invalid howToAlign parameter passed into printBuffer!\n";
	}
	print $HORIZONTAL_DELIMITER;

	if (defined($colorToPrint) && $colorToPrint) {
	  printColorIfOutputIsTerminal("reset");
	}

  }
  print STDOUT "\n";
}

# Prints this "buffer"--prints the current table.
sub printBuffer($$$) {
	my ($bufferArrayPtr, $ptrToMaxLenArray, $alignment) = @_;
	for (my $row = 0; $row < scalar(@{$bufferArrayPtr}); $row++) {
		printSingleArrayLine(\@{${$bufferArrayPtr}[$row]}, $ptrToMaxLenArray, $alignment, "reset");
	}
}

sub printHorizontalLine($$) {
  my ($char, $lineLength) = @_;
  print(($char x $lineLength) . "\n");
}

sub printHeader {
  # headerPtr: pointer to an array (@) of header values
  # maxLenPtr: pointer to an array of the maximum allowed lengths for this column
  my ($headerPtr, $maxLenPtr) = @_;

  my $headerLen = 0;
  foreach my $len (@$maxLenPtr) {
    $headerLen += $len;
    $headerLen += length($HORIZONTAL_DELIMITER);
  }

  if (!$outputIsColorTerminal || $neverColorNoMatterWhat) {
	# If we can't color the header output, then at least draw a line to distinguish it
	printHorizontalLine("=", $headerLen);
  }

  # Print the header text here
  printSingleArrayLine($headerPtr, $maxLenPtr, AUTO_ALIGN, "white on_blue underline");
  
  if (!$outputIsColorTerminal || $neverColorNoMatterWhat) {
	printHorizontalLine("=", $headerLen);
  }
}

sub printAndClearOutputSoFar($$$) {
	my ($headerPtr, $bufferPtr, $maxLenPtr) = @_;
	# Every so often, print a new header, then whatever we've read into the buffer

	if (defined($headerPtr) && defined(@$headerPtr) && (scalar(@$headerPtr) > 0)) {
	  printHeader($headerPtr, $maxLenPtr);
	}
	printBuffer($bufferPtr, $maxLenPtr, AUTO_ALIGN);
	@$bufferPtr = ();
	@$maxLenPtr = (); # clear out the maximum lengths
	for (my $col = 0; $col < scalar(@$headerPtr); $col++) {
		# now set the maximum lengths to whatever was in the header (to start with)
		$$maxLenPtr[$col] = defined($$headerPtr[$col]) ? length($$headerPtr[$col])  :  0;
	}
}

sub main() {
	my $inputDelim = "\t";
	my $hasHeader = 1; # by default, we expect a header line
	my $printStartupMessage = 0;
    GetOptions("help|?|man" => sub { printUsage(); }
			   , "ht=f"    => \$highlightThreshold
			   , "input_delim|d=s" => \$inputDelim
			   , "no_color|nc" => sub { $neverColorNoMatterWhat = 1; }
			   , "no_header|nh" => sub { $hasHeader = 0; }
			   , "n=i" => \$headerReprintInterval
			   , "all|a!" => \$printHeaderOnlyOnce
			   , "trunc|t=i" => \$truncLen
			   , "notify!" => \$printStartupMessage
			   ) or printUsage();
	
	if (defined($headerReprintInterval)) {
	  if ($headerReprintInterval < 1 || !isNonNegativeInt($headerReprintInterval)) {
		die "Error! You cannot specify printing the header more frequently than once every line! (i.e., 1 is the minimum). The value you passed in was \"$headerReprintInterval\".\n";
	  }
	} else {
	  # If the reprint interval wasn't explicitly set, then we set it here
	  # Print the header again every THIS many lines. The -7 is because we want to show the header at both the bottom and the top. (if it's less than 7, then the whole header won't show up at the bottom)
	  $headerReprintInterval = max(1, $terminal_height_in_lines - 7);
	}

	if (defined($truncLen) && ($truncLen <= 0 || !isNonNegativeInt($truncLen))) {
	  die "Error! Max column length to display must be at least 1, and it must be an integer. You specified it to be $truncLen.\n";
	}

	if ($printStartupMessage) {
	  # Just so people know they are not looking at the original file! sheet can do some weird things, like truncating output and aligning columns.
	  print "(This file has been processed by sheet.pl)" . "\n";
	}

	#print "Unprocessed by Getopt::Long\n" if $ARGV[0];
	#foreach (@ARGV) {
	#	print "$_\n";
	#}

	my $linesRead = 0;
	my $numNonHeaderLinesPrinted = 0;
	while (my $line = <>) {
		chomp($line);
		my @thisLine = split($inputDelim, $line);
		
		my $thisIsTheHeaderLine = $hasHeader && (0 == $linesRead);
		if ($thisIsTheHeaderLine) {
			for (my $i = 0; $i < scalar(@thisLine); $i++) {
			  $thisLine[$i] = ($i+1) . ": " . truncatedVersion($thisLine[$i]);
			}
			@header = @thisLine;
		}

		# Figure out how long the MAXIMUM line length is
		for (my $c = 0; $c < scalar(@thisLine); $c++) {
			if (!$thisIsTheHeaderLine && @header && $c >= scalar(@header)) {
				# This row has more columns than the header did,
				# so we need to add some column headers to the header...
				$header[$c] = ($c+1) . ": ";
			}

			my $item;
			if ($thisIsTheHeaderLine || !defined($truncLen)) {
			  $item = $thisLine[$c];  # <-- don't truncate this, it is handled specially for the header!
			} else {
			  $item = truncatedVersion($thisLine[$c]); # Truncate regular data items if necessary
			}
			
			
			if (!defined($maxLen[$c]) || length($item) > $maxLen[$c]) {
				my $itemLen = (defined($item)) ? length($item) : 0;
				my $headerLen = (defined($c) && defined($header[$c])) ? length($header[$c]) : 0;
				$maxLen[$c] = max($itemLen, $headerLen);
				#print "Max length of column $c is " . $maxLen[$c] . "\n";
			}
			if (!$thisIsTheHeaderLine) {
				# The header was already initialized, so this is a regular data line.
				my $r = ($printHeaderOnlyOnce) ? $numNonHeaderLinesPrinted : ($numNonHeaderLinesPrinted % $headerReprintInterval);
				$buffer[$r][$c] = $item;
			}
		}
		
		if (not $thisIsTheHeaderLine) {
			$numNonHeaderLinesPrinted++;		# Ok, so we've read in the header line already
			
			if (!$printHeaderOnlyOnce
				&& (0 == ($numNonHeaderLinesPrinted % $headerReprintInterval))) {
				printAndClearOutputSoFar(\@header, \@buffer, \@maxLen);
			}
		}

		$linesRead++;
	}

	# Print whatever remains that we haven't printed yet
	printAndClearOutputSoFar(\@header, \@buffer, \@maxLen);

} # end main;


main();

END {
	printColorIfOutputIsTerminal("reset");
}

exit(0);
# ====

__DATA__

sheet.pl: Spreadsheet-like formatting program.

Treats the first line as a header line by default.
(This header line gets repeated every 80 or so lines.)

Pipe your input into sheet.pl, then view the output in "less";

Try it like this:
  less tab_delimited_file.tab  | sheet.pl | less -S

	Note that you can also use "cat" instead of less at the beginning,
	but less has the advantage of transparently handling both gzipped
	files and regular files.


Outputting to a file:
	If you want to output to a file, just redirect.
    Example:   less myFile | sheet.pl -n 14 > file

Options:

-n=NUMBER (default: re-print the header every 40 lines)
	Recalculate the width of each column and reprint the header line
	(if there is one) every NUMBER lines. The best value for this is
	probably the exact height of your terminal window.
	You can suppress the header being reprinted with -nh (no header).

-a or --all
	Print the header ONLY at the top, and then print ALL of
    the file with columns widths not changing from the top of the file
	to the bottom. (Slower, since now we have to read through the
	entire file to find the lengths of each column, before
    we can start printing at all.) This is often ugly to view, because
	a *single* very wide item in a cell now makes the entire column
	that wide for the *whole* file.

-d DELIM or --input_delim=DELIM  (default: tab)
	Set the input file delimiter. Default: tab

-nc or --no_color  (default: print in color when outputting to the terminal)
	Do not color the output. By default, we only print color output
	when the output is a terminal. If you redirect the output to "less"
	or to a file, then there is no color output. Color output is done with
	invisible markup characters, and "less" does not handle them elegantly.

-nh or --no_header  (default: DO expect a header)
	Do not treat the header line specially. If this is *NOT* expect a header line.
	We highlight the header line separately,
	and print it out each time a group of lines is printed out.

-t INTEGER or --trunc=INTEGER
    Truncates all the columns to this many characters (or fewer).

--ht = NUMBER
    Highlight any numeric item >= this cutoff value. Default is 2.
    Highlight in this case means "put asterisks around it."

=================

This is the sheet.pl help page. Pipe this page into LESS for more info
Like this:
    sheet.pl --help | less

Check the top for more usage examples. Here is a simple one below:
	less MYFILE_TO_LOOK_AT  | sheet.pl | less -S

How can I make this program easier to run?

    You can integrate sheet.pl with "less" by defining a custom file for $LESSOPEN.
    The shell script indicated by $LESSOPEN is run before anything goes to "less".
    
    There is a valid shell script for $LESSOPEN in our CVS repository.
    Try putting this in your .cshrc file, to integrate *less* and sheet.pl.
    This assumes that ${MYSRC} is defined, and is set to the location of your
    local cvs repository (and that you have the lab_apps/shell_scripts directory).

alias ss "env LESSOPEN='|${MYSRC}/lab_apps/shell_scripts/lesspipe_advanced.sh %s' less -S --LINE-NUMBERS --status-column --ignore-case -R -f \!*"

    If that does not work, make sure that there is in fact a file in
        ${MYSRC}/lab_apps/shell_scripts/lesspipe_advanced.sh
    and that you are using tcsh / csh and not the bash shell.

	A slightly easier, but less powerful (it does not allow you to view multiple
    files using less''s shortcuts) ou can put this command into your ~/.cshrc:
	  alias vv "less \!* | sheet.pl | less -S"
	or if you use bash, your ~/.bashrc:
	  function vv {
	    less $* | sheet.pl | less
	  }

	Then you can use sheet.pl like this:
	    vv  FILE_TO_LOOK_AT
	or  vv  GZIPPED_FILE_TO_LOOK_AT.gz
	or  sort -u SOME_FILE | vv

	Note that the "vv" alias does not properly accept arguments
	(the arguments go to the first invocation of "less" instead).

================

Known bugs:

	None that I know of!

=================
