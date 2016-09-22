#!/usr/bin/perl -w

require "libfile.pl";
require "$ENV{MYPERLDIR}/lib/libstats.pl";
require "$ENV{MYPERLDIR}/lib/libstring.pl";

use POSIX qw(ceil floor); # import the ceil(ing) and floor functions for handling fractions/integers
use List::Util qw(max min); # import the max and min functions
use Term::ANSIColor;

use strict;
use warnings;
use diagnostics;

use File::Basename;
use Getopt::Long;

sub main();

sub printUsage() {
    print STDOUT <DATA>;
    exit(0);
}

# ==1==
sub main() { # Main program

	my ($numHeaderLinesToRead) = 1; # default: 1 header line to read from this file
	my ($headerFilename) = undef;
	my ($textToAdd) = undef;
	my ($readAllLines) = 0;
    GetOptions("help|?|man" => sub { printUsage(); }
			   , "file|f=s" => \$headerFilename
			   , "text|t=s" => \$textToAdd
			   , "h=i" => \$numHeaderLinesToRead
			   , "all!" => \$readAllLines
	       ) or printUsage();

	print STDERR "Unprocessed by Getopt::Long\n" if $ARGV[0];
	foreach (@ARGV) {
		print STDERR "$_\n";
	}

	if (!defined($headerFilename) && !defined($textToAdd)) {
	  die "You must either specify a header file name to read from, using --file=FILENAME, or specifiy text to add with --text='Your text'.\n";
	}
	if (defined($textToAdd) && defined($headerFilename)) {
	  die "Both the header filename (--file=...) and some literal text to add (--text='...') were specified. You must pick only one!\n";
	}

	if (defined($headerFilename)) {
	  if (not (-f $headerFilename)) {
		die "$headerFilename was specified as the file to read $numHeaderLinesToRead header lines from, but this file was not found (or could not be read.\n";
	  }
	  my $headerLinesPtr;
	  if ($readAllLines) { # read ALL the lines from the header file? (this is like using cat HEADER OTHERFILE)
		$headerLinesPtr = &readFileName($headerFilename);
	  } else {
		$headerLinesPtr = &readFileName($headerFilename, $numHeaderLinesToRead);
	  }
	  foreach my $line (@$headerLinesPtr) {
		chomp($line);
		print STDOUT $line . "\n";
	  }
	}

	if (defined($textToAdd)) {
	  $textToAdd =~ s/\\t/\t/g; # look for a literal \t and replace it with a tab
	  $textToAdd =~ s/\\n/\n/g; # look for a literal \n and replace it with a newline
	  print STDOUT $textToAdd . "\n";
	}

	while (my $fileLine = <STDIN>) {
	  print STDOUT $fileLine;
	}

} # end main()


main();


END {
  # Runs after everything else.
  # Makes sure that the terminal text is back to its normal color.
  resetColor();
}

exit(0);
# ====

__DATA__

header_add.pl --file=HEADERFILE [OPTIONS] < STDIN
or
header_add.pl --text="HEADER_TEXT" [OPTIONS] < STDIN

Alex Williams, 2008

This program appends a header from a file, to another file. It is a lot like using cat or head,
but without the aggravation of using a temp file or having to manually deal with gzipped files.

The header file (specified with -f FILENAME) can be read even if it is compressed.
(i.e., you can say --file=GZIPPED_FILE.gz without having to unzip it first.)

The output is *not* compressed, even if the -f HEADERFILE is.

Note that the STDIN data stream must be uncompressed,
so this will *NOT* work:
  cat GZIPPED_FILE.gz | header_add.pl -f SOMEHEADER  > OUTPUT
  (You would need to use "zcat" instead of "cat" in this case.)

CAVEATS:

* The STDIN input (i.e., "YOURFILE" in the command "cat YOURFILE | header_add.pl ...") cannot be
  compressed. Use "zcat" to read gzipped files into STDIN.

* The output file is NOT compressed.

* If you want to add a specific *string* of text to the top of the file, try using "cap.pl".
  (Or you could say 'echo "YOUR HEADER STRING" | cat - FILE_WITHOUT_HEADER > OUTPUT')

OPTIONS:

Mandatory:

Pick one option from -f or -t:

Either:   -f HEADER_FILENAME    or --file=HEADER_FILENAME
    Specify the filename to read the header info from.

or else:  -t 'LITERAL TEXT'     or --text='LITERAL TEXT'
    Specify literal header text in quotation marks. The special strings \t and \n are interpreted
    as a tab and newline, respectively. (Thus, you can add a multi-line header with \n).
 Note: Other backslashed escape-sequence strings are used literally, not interpreted.
    \t and \n are unique in being translated.

Optional:
  -h NUMBER (default 1)
    Number of header lines to read from the file. If you want to read ALL of them, omit this and use --all.
    -h=0 would have no effect at all.
  --all (default: OFF)
    If specified, we read the ENTIRE header file. This is the same as doing "cat HEADERFILE REST_OF_IT_FILE"

EXAMPLES:

header_add.pl is useful for adding headers *back* to files when we are using non-header-aware UNIX commands.
For example, if you want to sort a file, but keep the header line on top after the sort, you might do something
like this:

  tail +2 SOME_FILE | sort | header_add.pl -f SOME_FILE > OUTPUT

The above command is equivalent to this:
  head -n 1 SOME_FILE > head.tmp
  cat SOME_FILE | sort | cat head.tmp - > OUTPUT
But without the temporary file.

If you just want to add a header from an existing file:

  cat SOME_FILE | header_add.pl -f HEADER_FILE -h 2 > OUTPUT

That is identical to
  head -n 2 HEADER_FILE | cat - SOME_FILE > OUTPUT
So there is not much of a reason to use header_add.pl in such circumstances.

You can also add literal text in a manner similar to that of cap.pl with the --text option.

  cat SOME_FILE | header_add.pl --text="NewHeader\tIsHere"

KNOWN BUGS:

  None known.

TO DO:

--------------
