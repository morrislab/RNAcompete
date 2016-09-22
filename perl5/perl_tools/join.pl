#!/usr/bin/perl

require "libfile.pl";

use strict;

use Getopt::Long;

# Flush output to STDOUT immediately.
$| = 1;

################# BEGIN MAIN ###########################

my $arg                                   =  '';
my (@key1)                                = (1);
my (@key2)                                = (1);
my ($beg,$end)                            = (0,0);
my ($i,$j)                                = (0,0);
my ($file1,$file2)                        = ('','');
my ($key)                                 = '';
my (%values)                              = {};
my (%exists)                              = {};
my $delim                                 = "\t";
my ($delim_in1, $delim_in2)               = ("\t","\t");
my ($delim_out)                           = ("\t");
my $delim_syn                             = "\t";
my (@tmp)                                 = ();
my ($value1, $value2)                     = ('','');
my ($printable, $printable1, $printable2) = ('','','');
my ($suppress1, $suppress2, $suppressk) = (0,0,0);
my $negate=0;
my ($numeric) = 0;
my $empty = '';
my $max_tuple_size = undef;
my $skip_empty_lines = 0;
my $fill = '';
my $empty_placeholder = '___@@@_THIS_IS_A_BLANK_VALUE_@@@___';
my ($outer) = 0;
my ($reverse) = 0;
my ($uppercase) = 0;
my $hit = 0;
my $tmp;
my @fill_lines;
my $merge=0;
my $syn_file = "$ENV{JOIN_SYNONYMS}";
my %syn_pairs;
my $syn_pair;
my @syns_remaining;
my @syn_list;
my %syn_seen;
my $verbose=1;
my $header=0;


while(@ARGV)
{
    $arg = shift @ARGV;
    if($arg eq '--help')
    {
		print STDOUT <DATA>;
		exit(0);
    }
    elsif($arg eq '-q')
    {
		$verbose = 0;
    }
    elsif($arg eq '-f')
    {
		$arg = shift @ARGV;
		@key1 = &parseRanges($arg);
		@key2 = @key1;
    }
    elsif($arg eq '-1')
	{
        $arg = shift @ARGV;
        @key1 = &parseRanges($arg);
	}
    elsif($arg eq '-2')
	{
        $arg = shift @ARGV;
        @key2 = &parseRanges($arg);
	}
    elsif($arg eq '-o' or $arg eq '-of')
    {
		$arg = shift @ARGV;
		if(-f $arg)
		{
			if(not(open(FILE, $arg)))
			{
				print STDERR "join.pl: WARNING: Could not open file '$arg' to find outer text, skipping.\n";
			}
			else
			{
				while(<FILE>)
				{
					if(/\S/)
					{
						chomp;
						push(@fill_lines, $_);
					}
				}
				$outer = 1;
			}
		}
		else
		{
			$fill = $arg;
			$outer = 1;
		}
    }
    elsif($arg eq '-ob' or $arg eq '--outer_blank')
    {
		$fill  = undef;
		$outer = 1;
    }
    elsif($arg eq '-h1')
    {
		$header = 1;
    }
    elsif($arg eq '-h2')
    {
		$header = 2;
    }
    elsif($arg eq '-e' or $arg eq '--empty')
    {
		$empty = shift @ARGV;
    }
    elsif($arg eq '-skip')
    {
		$skip_empty_lines = 1;
    }
    elsif($arg eq '-m')
    {
		$merge = 1;
    }
    elsif($arg eq '-num')
	{
        $numeric = 1;
	}
    elsif($arg eq '-neg')
	{
        $negate = 1;
	}
    elsif($arg eq '-t' or $arg eq '-d')
	{
        $arg = shift @ARGV;
        $delim_in1 = $delim_in2 = $arg;
	}
    elsif($arg eq '-di1')
	{
        $delim_in1 = shift @ARGV;
	}
    elsif($arg eq '-di2')
	{
        $delim_in2 = shift @ARGV;
	}
    elsif($arg eq '-di')
	{
        $delim_in1 = shift @ARGV;
        $delim_in2 = $delim_in1;
	}
    elsif($arg eq '-do')
	{
        $delim_out = shift @ARGV;
	}
    elsif($arg eq '-ds')
    {
		$delim_syn = shift @ARGV;
    }
    elsif($arg eq '-syn')
    {
		$syn_file = shift @ARGV;
    }
    elsif($arg eq '-nosyn')
    {
		$syn_file = '';
    }
    # Suppress printing of values from table 1 (key will be printed however).
    elsif($arg eq '-s1')
    {
        $suppress1 = 1;
    }
    # Suppress printing of values from table 2 (key will be printed however).
    elsif($arg eq '-s2')
	{
        $suppress2 = 1;
	}
    elsif($arg eq '-sk')
	{
        $suppressk = 1;
	}
    elsif($arg eq '-r' or $arg eq '--reverse' or $arg eq '-rev')
	{
        $reverse = 1;
	}
    elsif($arg eq '-u')
	{ $uppercase = 1; }

    elsif(length($file1)<1)
	{
        $file1 = $arg;
	}
    elsif(length($file2)<1)
	{
        $file2 = $arg;
	}
}

# open(SYN,">/tmp/syns");

if(defined(@fill_lines) and $#fill_lines>=0)
{
	if(not(defined($fill)) or length($fill) == 0)
	{
		$fill = join($delim_out, @fill_lines);
	}
	else
	{
		$fill .= $delim_out . join($delim_out, @fill_lines);
	}
}

if($reverse)
{
	$tmp       = $suppress1;
	$suppress1 = $suppress2;
	$suppress2 = $tmp;
}

# See if the user supplied a synonyms file.  If so, extract synonyms for
# keys from the file and load it into a hash.
my %syns;
my $syn;
if(length($syn_file)>0)
{
	if(not(open(FILE, $syn_file)))
	{
		$verbose and print STDERR "join.pl: WARNING: Could not open the synonyms file, '$syn_file'. Skipping...\n";
	}
	else
	{
		$verbose and print STDERR "join.pl: Reading in synonyms from '$syn_file'...";
		while(<FILE>)
		{
			@tmp = split($delim_syn,$_);
			chomp($tmp[$#tmp]);
			if($uppercase)
			{
				for($i=0; $i<=$#tmp; $i++)
				{
					$tmp[$i] =~ tr/a-z/A-Z/;
				}
			}
			if($numeric)
			{ 
				for($i=0; $i<=$#tmp; $i++)
				{
					$tmp[$i] =~ int($tmp[$i]);
				}
			}
			for($i=0; $i<=$#tmp; $i++)
			{
				if($tmp[$i] =~ /\S/)
				{
					for($j=0; $j<=$#tmp; $j++)
					{
						if($tmp[$j] =~ /\S/)
						{
							$syns{$tmp[$i]} .= $tmp[$j] . $delim_syn;
							$syn_pairs{$tmp[$i] . $delim_syn . $tmp[$j]} = 1;
						}
					}
				}
			}
		}
		# Post-process the synonyms: If there are synonyms of synonyms, then make
		# sure these are united etc..
		foreach $syn_pair (keys(%syn_pairs))
		{
			(@syns_remaining) = split($delim_syn,$syn_pair);
			@syn_list=();
			# print SYN '[', join($delim_syn, @syns_remaining), "]: ";
			while(@syns_remaining)
			{
				$syn = shift @syns_remaining;
				if(not($syn_seen{$syn}))
				{
					$syn_seen{$syn} = 1;
					push(@syn_list,$syn);
					# print SYN "$syn ";
					@tmp = split($delim_syn, $syns{$syn});
					# Add new synonyms to the list to be processed.
					for($j=0; $j<=$#tmp; $j++)
					{
						push(@syns_remaining, $tmp[$j]);
					}
				}
			}
			# print SYN "]\n";
			for($i=0; $i<=$#syn_list; $i++)
			{
				$syns{$syn_list[$i]} = '';
				for($j=0; $j<=$#syn_list; $j++)
				{
					$syns{$syn_list[$i]} .= $syn_list[$j];
					if($j<$#syn_list)
					{
						$syns{$syn_list[$i]} .= $delim_syn;
					}
				}
				# print SYN "[$syn_list[$i]] <=> [$syns{$syn_list[$i]}]\n";
			}
		}

		close(FILE);
		$verbose and print STDERR " done.\n";
	}
}

# $arg = $syns{'F27B3.1'};
# print "[$arg]\n";

if ( (length($file1) < 1) or (length($file2) < 1) ) {
  print STDERR "join.pl: ERROR: Two input files must be specified on the command line!\n\n";
  print STDERR <DATA>;
  exit(1);
}

for($i=0; $i<=$#key1; $i++)
{ $key1[$i]--; }

for($i=0; $i<=$#key2; $i++)
{ $key2[$i]--; }

@key1 = sort {$a <=> $b} @key1; # sorts @key1 alphabetically
@key2 = sort {$a <=> $b} @key2; # sorts @key2 alphabetically

# print STDERR "Key 1: [", join(',', @key1), "]\n",
#         "Key 2: [", join(',', @key2), "]\n",
#         "Input delimiter 1: [$delim_in1]\n",
#         "Input delimiter 2: [$delim_in2]\n",
#         "Output delimiter 1: [$delim_out1]\n",
#         "Output delimiter 2: [$delim_out2]\n",
#         "\n",
#         ;

# Read in the key-printable pairs from the second file:
my ($loops) = 0;
my ($passify) = 10000; # <-- this means "print out a dot to STDERR every *this* many iterations"
my $fileRef2;
if($file2 =~ /\.gz$/) {  # note: here is where we transparently handle gzipped files!
	open(FILE, "zcat < $file2 |") or die("join.pl: Could not open file <$file2>.");
	$fileRef2 = \*FILE;

} elsif($file2 eq '-') {
	$fileRef2 = \*STDIN;

} else {
	open(FILE, $file2) or die("join.pl: Could not open file <$file2>.");
	$fileRef2 = \*FILE;
}

if($verbose) {
	print STDERR "join.pl: Reading relations from ", ($file2 eq '-') ? "standard input" 
		: "file <$file2>";
}

my $commentChar = '#';

my $numDuplicateKeysRead = 0; # how many duplicate keys were read from $file2?
my $maxDuplicateKeyWarnings = 10; # how many times to nag the user about multiple keys?

my $header_data='';
my $line=0;
while(<$fileRef2>) {
    if((not($skip_empty_lines) or /\S/) and not(/^\s*$commentChar/))
	{
		$line++;
		if($line==1 and $header==2)
		{ $header_data = $_; }
		@tmp = split($delim_in2);
		chomp($tmp[$#tmp]);

# print STDERR "\n2: tmp: [", join('|',@tmp), "]\n";
# print STDERR "2: key cols: [", join('|',@key2), "]\n";
		$key='';
		for($i=$#key2; $i>=0; $i--)
		{
			my $key_part = splice(@tmp,$key2[$i], 1);
			# $key .= length($key)>0 ? ($delim_out . $key_part) : $key_part;
			$key = length($key)>0 ? ($key_part . $delim_out . $key) : $key_part;
# print STDERR "1: key: [$key]\n";
# print STDERR "Before splice: [", join('|',@tmp), "] [$key]\n";
# print STDERR "After splice: [", join('|',@tmp), "] [$key]\n";
			# $key .= splice(@tmp, $i-1, 1) . $delim_out;
		}
		# Get rid of the last delimiter we added:
		if($numeric)
		{ $key = int($key); }
		if($uppercase)
		{ $key =~ tr/a-z/A-Z/; }
# print STDERR "2: tmp: [", join('|',@tmp), "]\n";
# print STDERR "2: key: [$key]\n";
		# $tmp = join($delim_out, @tmp);
		$tmp = &myJoin($delim_out, \@tmp, $empty_placeholder);

		if (defined($key) && (length($key) > 0) && defined($exists{$key})) {
		  $numDuplicateKeysRead++;
		  if ($verbose && ($numDuplicateKeysRead <= $maxDuplicateKeyWarnings)) {
			# only print this error if we are in VERBOSE mode.
			print STDERR
			  "\n"
			  . "join.pl: WARNING: More than one line with the key \"$key\" was found in file <$file2>.\n"
			  . "         We will only use the LAST row with this key.\n";
		  }
		}
		$values{$key} = $tmp;
		$exists{$key} = 1;

		my $tuple_size = scalar(@tmp);

		if(not(defined($max_tuple_size)) or $tuple_size > $max_tuple_size) {
			$max_tuple_size = $tuple_size;
		}

		# Record this value with all the synonym keys as well.

		@tmp = split($delim_syn, $syns{$key});
		# foreach $key (@tmp)
		for($j=0; $j<=$#tmp; $j++)
		{
			if($numeric)
			{ $key = int($key); }
			if($uppercase)
			{ $key =~ tr/a-z/A-Z/; }
			$values{$key} = $tmp;
			$exists{$key} = 1;
		}

		$loops++;
		if($verbose and (($loops % $passify) == ($passify-1)))
		{
			print STDERR '.';
		}
	}
}
if($verbose) { print STDERR " done.\n"; }
close($fileRef2);

if($outer and not(defined($fill))) {
	$fill = &replicate($max_tuple_size, $empty_placeholder, $delim);
}

# $arg = $syn{'F15G10.1'};
# print STDERR "[$arg]\n";

# Read in the key-printable pairs from the first file and print out
# the joined key:
my $fileRef;
if($file1 =~ /\.gz$/) {
	open(FILE, "zcat < $file1 |") or die("Could not open file '$file1'.\n");
	$fileRef = \*FILE;
}
elsif($file1 eq '-') {
	$fileRef = \*STDIN;
}
else {
	open(FILE, $file1) or die("join.pl: Could not open file '$file1'.\n");
	$fileRef = \*FILE;
}

if($verbose) { print STDERR "join.pl: Joining on file <$file1>\n"; }
$loops = 0;
my $found;
while(<$fileRef>)
{
    if((not($skip_empty_lines) or /\S/) and not(/^\s*${commentChar}/))
	{
		@tmp = split($delim_in1);
		chomp($tmp[$#tmp]);
		$key='';
# print STDERR "1: tmp: [", join('|',@tmp), "]\n";
		for($i = $#key1; $i >= 0; $i--) {
			my $key_part = splice(@tmp,$key1[$i], 1);
			# $key .= length($key)>0 ? ($delim_out . $key_part) : $key_part;
			$key = length($key)>0 ? ($key_part . $delim_out . $key) : $key_part;
# print STDERR "1: key: [$key]\n";
		}
		# Get rid of the last delimiter we added:
		if($numeric)   { $key = int($key); }
		if($uppercase) { $key = uc($key); }  # uppercase-ify it

		$value1 = &myJoin($delim_out, \@tmp, $empty_placeholder);
		$value2 = $values{$key};
		$found = $exists{$key};

# print STDERR "1: key: [$key]\n";
# print STDERR "1: value1: [$value1]\n";
# print STDERR "1: value2: [$value2]\n";
# print STDERR "1: found: [$found]\n";

		# See if this key matches any of the key's synonyms
		if(not($found)) {
			@tmp = split($delim_syn, $syns{$key});
			while(@tmp and not($found)) {
				$tmp = shift @tmp;
				$found = $exists{$tmp};
				if($found) {
					$value2 = $values{$tmp};
				}
			}
		}

		if((not($negate) and $found) or ($negate and not($found))) {
			$hit = 1;
		} elsif($outer) {
			$value2 = $fill;
			$hit = 1;
		} else {
			$hit = 0;
		}

		if($merge and $hit) {
			$value1 = $value2;
			$value2 = $empty;
		} elsif($merge and not($hit)) {
			$hit = 1;
			$value2 = $empty;
		}

		if($hit) {
			if($reverse) {
				$tmp = $value1;    # Swap the two values if we're
				$value1 = $value2; # supposed to print the second value
				$value2 = $tmp;    # before the first one.
			}
			$printable  = $suppressk ? '' : $key;
			$printable1 = ($suppress1 or length($value1)<1) ? '' : $value1;
			$printable2 = ($suppress2 or length($value2)<1) ? '' : $value2;

			if(length($printable1) > 0) {
				$printable = (length($printable) > 0)
					? ($printable . $delim . $printable1)
					: $printable1;
			}
			if(length($printable2) > 0) {
				$printable = (length($printable) > 0)
					? ($printable . $delim . $printable2)
					: $printable2;
			}
			$printable =~ s/$empty_placeholder/$empty/g;
			print $printable, "\n";
		}
		$loops++;
		if ($verbose and (($loops % $passify)==($passify-1)) ) {
			print STDERR '.';
		}
	}
}
if ($verbose) { print STDERR "join.pl finished. (Joined <$file1> with <$file2>)\n"; }
if ($verbose && ($numDuplicateKeysRead > 0)) {
  print STDERR "join.pl: WARNING: Read $numDuplicateKeysRead lines with identical keys in <$file2>.\n";
  print STDERR "         Only the *last* line in a file with a redundant key is actually used.\n"
}
close(FILE);

exit(0);

################# END MAIN #############################

__DATA__
syntax: join.pl [OPTIONS] LOOKUP_FILE  DICTIONARY_FILE

join.pl goes through each line/key in the LOOKUP_FILE, and finds the *first* matching
key in the DICTIONARY_FILE. The data from those corresponding rows is then
printed out. It does not handle cross-products.

Unlike the UNIX "join", join.pl does NOT require sorted keys.

DESCRIPTION:

This script takes two tables, contained in delimited files, as input and
produces a new table that is a join of FILE1 and FILE2.

By default, files are assumed to be tab-delimited with the keys in the first column.
(See the options to change these defaults.)

If FILE1 contains the tuple (VOWELS, A, O, A) and FILE2 contains the
tuple (VOWELS, I, U, U) then the joined output will be (VOWELS, A, O, A, I, U, U)

CAVEATS:

Every line of the LOOKUP_FILE is processed in the
order that it appears in the file.

The DICTIONARY_FILE is only for handling join operations.

If the DICTIONARY_FILE contains several lines with the same key,
only the *LAST* key read will actually ever be used.

Because of this, join.pl does NOT exactly duplicate the function of
GNU "join"--in particular it does not output the cross-product
in multiple-key situations.

*** NOTE: If you are trying to merge two files, or you are joining ***
*** multiple times with multiple files, try "join_multi.pl" .      ***

OPTIONS are:

-m: Merge - if key exists in file 2, use value from file 2 else
    use the value from file 1.

-q: Quiet mode: turn verbosity off (default is verbose)
    Quiet mode also removes the "more than one line with the key..." warnings.

-1 COL: Include column COL from FILE1 as part of the key (default is 1).
         Multiple columns may be specified in which case keys are constructed
         by concaternating each column in NUMERICAL order (NOT the order specified,
         where the delimiter used is equal to the output delimiter, see -do flag).
 CAVEAT: Multiple join fields do NOT respect the order on the command line
         -1 1,2,3,4,5  is exactly the same as -1 4,3,5,1,2. Therefore you cannot
         join files with out-of-order keys in this manner!

-2 COL: Include column COL from FILE2 as part of the key (default is 1).
         See -1 option for discussion of multiple columns.

-o FILLER: Do a left outer join.  If a key in FILE1 is not in FILE2, then the
          tuple from FILE1 is printed along with the text in FILLER in place of
          a tuple from FILE2 (by default these tuples are not reported in the
          result).  See -of option also to supply FILLER from a file.
          (See below for an example of usage.)

-ob: Same as -o but fill with blanks.

-of FILE: Same as -o, but use the text in FILE as the text for FILLER.

-e EMPTY: Set the empty string to EMPTY (default is blank).  If both keys
           exist in FILE1 and FILE2 but one tuple is blank, then the empty
           character EMPTY will be printed.

-num: Treat the keys as numeric quantities (default is off: treat keys as
        strings).  If this is turned on, each key will be forced into an
        integer quantity.

-neg: Negative output -- print keys that are in FILE1 but not in FILE2.
        These keys are the same ones that would be left out of the join,
        or those that would have a FILL tuple in a left outer join (see -o
        option).

-di1 DELIM: Set the input delimiter for FILE1 to DELIM (default is tab).

-di2 DELIM: Set the input delimiter for FILE2 to DELIM (default is tab).

-di DELIM: Set the input delimiters for both FILE1 and FILE2 to DELIM (default
        is tab).  Equivalent to using both the -di1 and -di2 options.

-do DELIM: Set the output file delimiter to DELIM. (default is tab)

-ds DELIM: Set the delimiter for synonyms to DELIM.  This is used for reading
        synonyms for keys (see the -syn option) (default is tab).

-syn FILE: Specify that synonyms for keys can be found in the file FILE.
        Each line in FILE should contain synonyms for only one key, separated
        by the delimiter specified with the -ds option).
     Example:      theKey  <tab>   synonymOne  <tab>   synonymTwo

-nosyn: Ignore synonym file in the JOIN_SYNONYMS environment variable if it
        exists.

-s1: Suppress printing of tuples from FILE1.  The key is printed, followed by
        the tuple found in FILE2.

-s2: Suppress printing of tuples from FILE2.

-sk: Suppress printing of keys.

-r: Reverse
     Instead of printing: <key> <tuple_from_FILE1> <tuple_from_FILE2>,
                    print <key> <tuple_from_FILE2> <tuple_from_FILE1>

-u: Uppercase.  (Case-insensitive join)
     Converts non-numeric keys to uppercase, resulting in a case-insensitive join.
     Keys from both FILE1 and FILE2 will be uppercased before attempting the join.

-skip: Skip empty lines (default processes them).


Example:

If you have the following two files:

File 1: (tab-delimited)
 AAA   avar    aard
 ZZZ   zebra
 BBB   beta    bead    been
 MMM   man     most

File 2: (tab-delimited)
 AAA   111
 BBB   222
 CCC   333

Then the result of a regular join.pl invocation...
   join.pl File1 File2
...is:
 AAA   avar    aard    111             <-- Note: 4 columns in all
 BBB   beta    bead    been    222     <-- Note: 5 columns in all

The result of an outer join (i.e., use File1 as the "master" file)...
   join.pl -o "NONE!" File1 File2
...is:
 AAA    avar     aard      111
 ZZZ    zebra    NONE!
 BBB    beta     bead      been      222
 MMM    man      mouse     NONE!

Note that if you switch the order of File1 and File2 for an outer join...
   join.pl -o "NOPE!" File2 File1
...you get a different result (the first file specifies the keys):
 AAA    111       avar      aard
 BBB    222       beta      bead       been
 CCC    333       NOPE!

----------
Note that UNIX join will behave differently from
join.pl on the input FILE1 and FILE2 given below:

FILE1: (tab-delimited)
Alpha   1   2
Alpha   3   4

FILE2: (tab-delimited)
Alpha   a   first
Alpha   b   middle
Alpha   c   last

----------
