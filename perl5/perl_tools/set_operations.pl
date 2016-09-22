#!/usr/bin/perl -w

# By Alex Williams, July 2006
# alexgw@soe.ucsc.edu

use strict;
use Getopt::Long;

require "$ENV{MYPERLDIR}/lib/libset.pl";
require "libfile.pl";

sub printUsage() {
    print STDOUT <DATA>;
    exit(0);
}

my $delimiter = "\t"; # not actually used right now <--
my $operation = undef;
my $includeBlanks = 0; # whether or not to include blank lines (do NOT include, by default)

if (scalar(@ARGV) == 0) {
    printUsage();
}

GetOptions("help|?|man" => sub { printUsage(); }
	   , "delim|d:s" => \$delimiter
	   , "union|u" => sub { $operation = 'u'; }
	   , "wb|withblanks" => sub { $includeBlanks = 1; }
	   , "intersect|intersection|n" => sub { $operation = 'n'; }
	   , "subtract|sub|s" => sub { $operation = 's'; }
	   ) or printUsage(); 

# Remaining arguments are FILE1 and FILE2

# my $sorted = "set_operations.sorted.tmp";
# my $prevFilename = undef;
# my $accum = "set_operations.accumulation";
# system("rm -f $accum");

# for (my $i = 0; $i < scalar(@ARGV); $i++) {
#     my $filename = $ARGV[$i];
    
#     if ($operation = 'n') {
# 	system("sort -u $filename > $filename.$sorted");
# 	if (defined($prevFilename)) {
# 	    system("join $prevFilename.sorted $filename.$sorted > $accum");
# 	    system("mv -f $accum $filename.$sorted");
# 	}
# 	$prevFilename = $filename;
#     } elsif ($operation = 'u') {
# 	system("cat $filename >> $accum");
# 	system("uniq $accum > $sorted");
# 	system("mv -f $sorted $accum");
#     }
# }

if (not defined($operation)) {
    print STDOUT "Bad command line arguments: The set operation type (union / intersection / subtraction) must be specified on the command line.\n";
    die "See the usage for more information.\n"
}

if (scalar(@ARGV) < 2) {
    print STDOUT "We require at least two files (as arguments) to perform any meaningful set operations.\n";
    die "See the usage for more information.\n"
}

#if ($operation == 'u') {
#    my $argStr = join(' ', @ARGV);
#    system("cat $argStr | uniq");
#    exit(0);
#}


my $finalSetPtr = undef;
my $readFromSTDIN = 0;
for (my $i = 0; $i < scalar(@ARGV); $i++) {
    my $filename = $ARGV[$i];

    my $dataPtr = undef;

    if ($filename eq '-') {
	# read from STDIN
	$dataPtr = readFile("STDIN");
	$readFromSTDIN++;
	if ($readFromSTDIN > 1) {
	    die "ERROR! You cannot read from STDIN more than one time! In other words, you can only use the - (hyphen) once on the command line.\n";
	}
    } else {
	$dataPtr = readFileName($filename);
    }

    my %thisSet = ();
    foreach my $item (@{$dataPtr}) {
	$thisSet{$item} = 1;
    }
    
    if ($i == 0) {
	$finalSetPtr = setCopy(\%thisSet); # initialize the "final set" to start out as this set
    } else {
	if ($operation eq 's') {
	    $finalSetPtr = setDifference($finalSetPtr, \%thisSet); # (final minus this)
	} elsif ($operation eq 'u') {
	    $finalSetPtr = setUnion($finalSetPtr, \%thisSet);
	} elsif ($operation eq 'n') {
	    $finalSetPtr = setIntersection($finalSetPtr, \%thisSet);
	} else {
	    die "Problem: invalid operation.\n";
	}

    }
}

if (not $includeBlanks) {
    delete($$finalSetPtr{''}); # delete the empty/blank line (which may or may not actually exist)    
}

foreach my $item (keys(%$finalSetPtr)) {
    print STDOUT $item;
    print STDOUT "\n";
}

exit(0);



__DATA__
Description:
    Performs some common set operations on .lst files (lists with no other data)

Syntax: set_operations.pl TYPE [OPTIONS] file1 file2 file3...

TYPE choices:
    -s (or -sub, or -subtract) : set subtraction
    -u (or -union): set union
    -n (or -intersect): set intersection

Additional Options:
    -withblanks or -wb:
        include blank lines as set elements (default is NOT including blanks)

    One file can also be a hyphen (-), which indicates that it is to be
    read from STDIN.

Examples of Usage:
    set_operations.pl -sub START_FILE TO_REMOVE_FILE
        This would subtract the elements found in TOREMOVE_FILE from START_FILE.
        The result would be (START_FILE - TO_REMOVE_FILE)
    
    set_operations.pl -union - FILE_B FILE_C FILE_D
        This would union the input from STDIN (the '-') with files FILE_B through FILE_D.

    set_operations.pl -intersect -withblanks A B C D E
    
You can input as many files names as you want.

For union and intersect, all the files will be unioned or intersected.

For subtraction, the FIRST file will be the base list of set elements, and
every subsequent file's elements will be subtracted out (set subtraction).

Alternative ways to do set operations:
    A two-file INTERSECT can be mimicked with 'join' on the two SORTED files.
    A common pitfall is forgetting to sort the two files. Files must also
    end in a newline.

    UNION can be accomplished by appending all the files to a temporary file,
    and then running "uniq" on that file. Note that this requires that
    each files ends in a newline, or else it will also break.
