#!/usr/bin/perl -w

# A program for asking about what files are in our repository.
# By Alex Williams, 2008.

#require "libfile.pl";
#require "$ENV{MYPERLDIR}/lib/libstats.pl";

use POSIX qw(ceil floor); # import the ceil(ing) and floor functions for handling fractions/integers
use List::Util qw(max min); # import the max and min functions

use File::Basename;
use Getopt::Long;

use strict;
use warnings;
#use diagnostics;

no warnings 'redefine';

sub main();

sub printUsage() {
    print STDOUT <DATA>;
    exit(0);
}


sub main() { # Main program

  my $query = $ARGV[0];

  my $labwide_perl_repository = `find /projects/sysbio/lab_apps/perl/ -iregex '.*\\(README\\|\\.p[lm]\\)' | grep -i -v 'CVS/' | grep -i -v 'Backup'`;

  my $labwide_R_repository = `find /projects/sysbio/lab_apps/R_shell/ -iregex '.*\\(README\\|\\.py\\|\\.R\\)' | grep -i -v 'CVS/' | grep -i -v 'Backup'`;

  #print $labwide_R_repository;

  my $all_places = $labwide_perl_repository . ' ' . $labwide_R_repository;
  $all_places =~ s/[\n\r]/ /g;

  #print $all_places;

  my $resultStr = `grep -i --color=auto "$query" $all_places`;
  my @results = split(/\n/, $resultStr);

  for my $line (@results) {
	chomp($line);
	$line =~ s/:[\s]*/:/g; # remove only the very first whitespace after the colon, if there is any (this way the results are flush left)
	$line =~ s/[\s]+/ /g; # collapse all the tabs so that the results aren't incredibly annoying
	$line =~ s/:/\t/; # now replace the first : (for the path) with a tab
	print $line;
	print "\n";
  }

} # end main()


main();
exit(0);
# ====

__DATA__

labman.pl 'SEARCH_TEXT_HERE'

labman.pl will find any programs that lab members have written that contain the selected text.

Searches are case-insensitive.

This is like the unix "man" and "apropos" commands. However, it is tailored specifically to our lab software.

(Internally, it is a wrapper around grep and find.)

 EXAMPLES:

Suppose you are wondering if someone already wrote a program to make a historgram, for example,
you could type:
    labman.pl  histogram   | less -S

Or maybe you are thinking about writing a program to calculate the median value of a line,
but you suspect someone might have already written it:
    labman.pl  median   | less -S

Queries with spaces in them should be enclosed in quotes:
    labman.pl  'pearson corr'   | less -S
