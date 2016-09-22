#!/usr/bin/perl

##############################################################################
##############################################################################
##
## subst.pl - Substitute strings in text.
##
##############################################################################
##############################################################################
##
## Written by Josh Stuart in the lab of Stuart Kim, Stanford University.
##
##  Email address: jstuart@stanford.edu
##          Phone: (650) 725-7612
##
## Postal address: Department of Developmental Biology
##                 Beckman Center Room B314
##                 279 Campus Dr.
##                 Stanford, CA 94305
##
##       Web site: http://www.smi.stanford.edu/people/stuart
##
##############################################################################
##############################################################################
##
## Written: 00/00/02
## Updated: 00/00/02
##
##############################################################################
##############################################################################

require "libfile.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-h', 'scalar',     0, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , ['--file',   'list',    [], undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose   = not($args{'-q'});
my $delim     = $args{'-d'};
my $headers   = $args{'-h'};
my @files     = @{$args{'--file'}};
my $regex_col = 0;
my $repl_col  = 1;

scalar(@files) >= 2 or die("Please supply at least 2 files");

my $filep   = &openFile(shift(@files));
my $line_no = 0;
my @regexs;
my @replacements;
while(<$filep>)
{
   my @tuple = split($delim);
   chomp($tuple[$#tuple]);
   $regexs[$line_no]       = $tuple[$regex_col];
   $replacements[$line_no] = $tuple[$repl_col];
   $line_no++;
}
close($filep);

foreach my $file (@files)
{
   $line_no = 0;
   $filep   = &openFile($file);
   while(<$filep>)
   {
      $line_no++;
      if($line_no > $headers)
      {
	 for(my $i = 0; $i < scalar(@replacements); $i++)
	 {
	    my $repl  = $replacements[$i];
	    my $regex = $regexs[$i];
	    my $safe  = $pad . $regex . $pad;
	    s/$regex/$safe/ge;
	    s/$safe/$repl/ge;
	 }
      }
      print;
   }
   close($filep);
}

exit(0);


__DATA__
syntax: subst.pl [OPTIONS] SUBST_FILE TARGET_FILE1 [TARGET_FILE2...]

SUBST_FILE - contains two columns - First column has the regular
expression to match and the second column has the associated
string to replace the matched text with.

TARGET_FILEs can be any ASCII file.

OPTIONS are:

-q: Quiet mode (default is verbose)

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: The number of headers in the TARGET_FILE(s) (default is 0).

