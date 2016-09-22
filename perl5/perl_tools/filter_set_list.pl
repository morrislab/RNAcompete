#!/usr/bin/perl

##################################################
##################################################
##
## filter_set_list.pl
##
##################################################
##################################################
##
## Written by Charlie Vaske in the lab of Josh Suart, UC Santa Cruz
##
## email: cvaske@soe.ucsc.edu
##
##################################################
##################################################

require "libfile.pl";
require "$ENV{MYPERLDIR}/lib/libset.pl";

use strict;
use warnings;

use Getopt::Long;

sub usage;
sub percentageOverlaps;

# Algorithmic options
my $max_overlap = 0.25;

# File parsing options
my $key_col_list = 1;
my $key_col_comp = 1;
my $delim_list = "\t";
my $delim_comp = "\t";
my $headers_list = 0;
my $headers_comp = 0;

GetOptions("m|max-overlap=f" , \$max_overlap,
	   "kl=i" , \$key_col_list,
	   "kc=i" , \$key_col_comp,
	   "dl=s" , \$delim_list,
	   "dc=s" , \$delim_comp,
	   "hl=i" , \$headers_list,
	   "hc=i" , \$headers_comp,
	   "h|help|man" , sub {usage(0)});

usage(1, "max-overlap should be between 0 and 1") if ($max_overlap < 0 || $max_overlap > 1);

usage(1, "key column must be greater than 0") if ($key_col_list < 1);
usage(1, "key column must be greater than 0") if ($key_col_comp < 1);
$key_col_list--;
$key_col_comp--;

usage(1, "can not have negative header lines") if ($headers_list < 0);
usage(1, "can not have negative header lines") if ($headers_comp < 0);

usage(1, "Must specify two file arguments") if scalar(@ARGV) != 2;

my $comp = &setsReadLists($ARGV[1], $delim_comp, $key_col_comp,
    $headers_comp, undef, undef, 0);

my $list = &openFile($ARGV[0]) or die ("couldn't open file $ARGV[0]");

my %kept_sets;

print scalar(<$list>) while ($headers_list-- > 0);
while(my $l = <$list>) 
{
    chomp $l;
    my @f = split($delim_list, $l);
    my $newsetname = $f[$key_col_list];
    my $newset = ${$comp}{$newsetname};
    if (!defined($newset)) {
	warn "Couldn't find set \"$newsetname\" in compendium";
	next;
    }
    my $overlap = max(percentageOverlap($newset, \%kept_sets));
    if (!defined($overlap) || $overlap <= $max_overlap) {
	$kept_sets{$newsetname} = $newset;
	print $l, "\n";
    }
}
    
close($list);

sub percentageOverlap {
    my ($newset, $sets) = @_;
    my @pover;
    for my $set (values(%$sets)) {
	my $i = &setIntersection($newset, $set);
	push @pover, &setSize($i)/&setSize($set), &setSize($i)/&setSize($newset);
    }
    return @pover;
}

sub usage {
    my ($er, $msg) = @_;
    $er |= 0;
    print <DATA>;
    print "\nError: $msg\n" if (defined($msg));
    exit($er);
}

__DATA__
Description:

    Removes sets that are "too similar" to each other, so you can get
    a list of sets with (mostly) non-redundant elements.
    Iterate through a list of sets, removing any sets with overlap
    that surpasses a maximum amount (by default 25%).  The overlap
    percentage for sets A and B is calculated as
    |A^B|/max(|A|,|B|). 
        where
          A^B means "A intersect B", i.e. the overlap
          |A| means "the number of members of set"

    The list of sets may be any column in a
    tab-delimited file. Each sets content is specified by a separate
    set compendium file in lists_t format.

    The way this works is that the very first set in the SETLISTFILE
    will ALWAYS be included (because there are no other "accepted" sets
    yet, so it is not similar to anything), and subsequent sets are
    compared to the previous accepted sets (i.e., the second set in the
    SETLISTFILE is compared only against the first set).

    The order of sets in the SETLISTFILE is VERY IMPORTANT--when two
    sets are similer, the earlier one is included. (The order also
    changes which comparisons are done.)
    
    The order of sets in the COMPENDIUMFILE is not important at all.

Syntax:

    filter_set_list.pl [OPTIONS] SETLISTFILE COMPENDIUMFILE

SETSLISTFILE is at least a single column, with names of sets. (It can also have set membership)
COMPENDIUMFILE is a lists_t.tab-style file, with SETNAME <tab> member1 <tab> member2 ...

Example usage:

Example set file "MySet.tab":
ALPHA   a   b   c
BETA    b   c
GAMMA   g   f   a
DELTA   b

filter_set_list.pl --max-overlap 0.25  MySet.tab  MySet.tab   > sets_with_output

or when given a smaller set file...

Example set file "SmallerSet.tab"
ALPHA
GAMMA

...you could use the command:

filter_set_list.pl --max-overlap 0.25  SmallerSet.tab  MySet.tab   > other_sets_with_output


Options:
    --max-overlap    The maximum overlap a set can have with a previous
    -m               set and still be output.  This should be a number 
                     between 0 and 1.
    
    -kl              the key column for the set list
    -kc              the key column for the set compendium

    -dl              field delimiter for set list
    -dc              field delimiter for set compendium

    -hl              number of header lines in set list
    -hc              number of header lines in set compendium
