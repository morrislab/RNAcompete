#!/usr/bin/perl

##############################################################################
##############################################################################
##
## sets.pl
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
require "libset.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [   '-k1', 'scalar',     1, undef]
                , [   '-k2', 'scalar',     2, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-e', 'scalar',    "", undef]
                , [    '-h', 'scalar', undef, undef]
                , [    '-i', 'scalar',   'v', undef]
                , [    '-o', 'scalar',   'V', undef]
                , [    '-m', 'scalar',     1, undef]
                , [    '-v', 'scalar', undef, undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose       = not($args{'-q'});
my $key_col1      = $args{'-k1'} - 1;
my $key_col2      = $args{'-k2'} - 1;
my $delim         = &interpMetaChars($args{'-d'});
my $empty         = $args{'-e'};
my $headers       = $args{'-h'};
my $mem_val       = defined($args{'-m'}) ? ($args{'-m'} eq '.' ? undef : $args{'-m'}) : undef;
my $val_delim     = &interpMetaChars($args{'-v'});
my $in_type       = $args{'-i'};
my $out_type      = $args{'-o'};
my @extra         = @{$args{'--extra'}};
my $file          = $args{'--file'};

$headers     = defined($headers) ? $headers : ($in_type eq 'm' ? 1 : 0);

my $sets = undef;

my $print_mem_val = defined($mem_val) ? $mem_val : '.';

# Read in the setst.
if($in_type eq 'v')
{
   $verbose and print STDERR "Reading in sets from a set-major list.\n";
   $sets = &setsReadLists($file, $delim, $key_col1, $headers, undef, undef, 0);
}
elsif($in_type eq 'V')
{
   $verbose and print STDERR "Reading in sets from a member-major list.\n";
   $sets = &setsReadLists($file, $delim, $key_col1, $headers, undef, undef, 1);
}
elsif($in_type eq 'p')
{
   my $mem_col = defined($mem_val) ? $mem_val - 1 : undef;
   $verbose and print STDERR "Reading in sets from a list of pairs.\n";
   $sets = &setsRead($file, $delim, $key_col1, $key_col2, undef, 0, $mem_col);
}
elsif($in_type eq 'm')
{
   $verbose and print STDERR "Reading in sets from a matrix (membership value=$print_mem_val).\n";
   $sets = &setsReadMatrix($file, $mem_val, $delim, $key_col1, $headers, $empty);
}

# Apply any filters to the sets.
for(my $i = 0; $i < @extra; $i++) {
   my $arg = $extra[$i];
   if($arg eq '-rank') {
      $verbose and print STDERR "Ranking values within each set.\n";
      &setsRankValues($sets);
      $verbose and print STDERR "Finished ranking values within each set.\n";
   }
   if($arg eq '-top') {
      my $top = $extra[++$i];
      &setsKeepTop($sets, $top);
   }
}

# Write out the sets.
if(defined($sets))
{
   my $num_sets = &setSize($sets);
   $verbose and print STDERR "Done reading in sets ($num_sets read).\n";

   if($out_type eq 'v')
   {
      $verbose and print STDERR "Printing out sets to a set-major list.\n";
      &setsPrintLists($sets, \*STDOUT, $delim, 0, $val_delim);
   }
   elsif($out_type eq 'V')
   {
      $verbose and print STDERR "Printing out sets to a member-major list.\n";
      &setsPrintLists($sets, \*STDOUT, $delim, 1, $val_delim);
   }
   elsif($out_type eq 'p')
   {
      $verbose and print STDERR "Printing out sets to a list of pairs.\n";
      # &setsPrint($sets, \*STDOUT, $delim, 0, $val_delim);
      &setsPrintPairs($sets, \*STDOUT, $delim, 0, $val_delim);
   }
   elsif($out_type eq 'P')
   {
      $verbose and print STDERR "Printing out sets to a list of pairs.\n";
      # &setsPrint($sets, \*STDOUT, $delim, 1, $val_delim);
      &setsPrintPairs($sets, \*STDOUT, $delim, 1, $val_delim);
   }
   elsif($out_type eq 'm')
   {
      $verbose and print STDERR "Printing out sets to a matrix (membership value=$print_mem_val).\n";
      &setsPrintMatrix($sets, \*STDOUT, $delim, $empty);
   }
   $verbose and print STDERR "Done.\n";
}
else
{
   $verbose and print STDERR "No sets read.\n";
}

if (defined($headers) && ($headers > 0) && ($in_type eq 'p' || $in_type eq 'P')) {
	print STDERR
		"\n\n" .
		"!! WARNING: sets.pl: Invalid/ignored command-line argument:\n" .
		"!! WARNING: sets.pl: the -h (headers) option is ignored when the input type is p (pairs) or P. You specified a header option, but we didn't use it.\n" .
		"!! WARNING: sets.pl: The number of headers was set to zero.\n" .
		"\n\n";
}

exit(0);


__DATA__
syntax: sets.pl [OPTIONS] [TAB_FILE | < TAB_FILE]

Manipulates and reformats sets contained in tab delimited files.

OPTIONS are:

-q: Quiet mode (default is verbose)

-k1 COL: Set the first key column to COL (default is 1).

-k2 COL: Set the second key column to COL (default is 2).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 1).
            This is not used when the input type is "p" or "P".

-i INPUT_TYPE: The input set is in the format INPUT_TYPE.  INPUT_TYPE can
               be any of:

      v: The input is a list of vectors where the first column is a set ID and
         the remaining entries in a row is a list of member IDs in that set (i.e.
         this is set major format) (default).

      V: The same as v except the first column is a *member* ID and the entries
         contain the sets the member is in (i.e. member major format).

      p: The input is a list of pairs where the first column is a member ID and the
         second column is the set ID.

      P: The same as p except the set key and member key are swapped.
      NOTE: This does not appear to actually work!

      m: The input file is in the form of a set matrix (set names in first row, element
         names in first column, and values in third column).

-o OUTPUT_TYPE: Same as -i only change the output format.  The default is "V".
      If you want to output pairs from a matrix, make sure to use these options:
           sets.pl  -i m  -o p  -v '\t'  -m .  YOUR_FILENAME
      or use matrix2pairs.pl

-m VAL: Membership value (default is 1).  If VAL equals "." then any non-empty
        value is considered to be a member. If used in combination
        with the "p" input type, then VAL is interpreted to be
        the column where a membership value can be found.

-e EMPTY: Set the empty value to EMPTY (default is blank).  For
          example, Matlab friendly empty values would be NaN.

-v DELIM: Print out the values and delimit them from their members
          by DELIM (default does not print the values).
          For example setting DELIM to = would make the script
          print out MEMBER=VAL pairs for each member.

Filters
 Between reading in a set and writing it out,  one of the following filters can be set on the values.
 Note that these are order dependant and will be executed in the order supplied.

-top N: For each set, keep those members with the N largest values. If N < 0, it keeps the smallest -N values
        (e.g. calling -top -10 will keep the 10 members with the smallest associated values).

-rank: Convert the values of each member to a rank ratio (ranging from 1/N to 1).

How to format a "list" file for viewing with a microarray viewer:
    If you have a file "FILE" in the format:
      Gene_1 <tab> Experiment_1 <tab> Value_0.222
      Gene_1 <tab> Experiment_2 <tab> Value_0.424
      ...
    You can easily turn this into a matrix with the command:
      sets.pl  -i p   -o m   -m 3   -e NONE   -h 0   FILE

    Conversely, if you want to turn a matrix into a list of pairs, you can use:
      sets.pl -i m  -o p  -v '\t'  -m .  YOURFILE

    or use the program
      matrix2pairs.pl



