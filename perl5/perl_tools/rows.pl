#!/usr/bin/perl

##############################################################################
##############################################################################
##
## rows.pl
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
                , [    '-f', 'scalar',     1, undef]
                , [    '-k', 'scalar', undef, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-h', 'scalar',     0, undef]
                , [    '-s', 'scalar',     0,     1]
                , [    '-m', 'scalar',     0,     1]
                , ['--file',   'list', ['-'], undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose          = not($args{'-q'});
my $field            = (defined($args{'-k'}) ? $args{'-k'} : $args{'-f'}) - 1;
my $delim            = $args{'-d'};
my $headers          = $args{'-h'};
my $print_seperators = $args{'-s'};
my $print_missing    = $args{'-m'};
my @files            = @{$args{'--file'}};
my $file             = shift @files;
my @lists            = @files;

my @header;
my @seperator;
my @missing;
my $seperator;

for(my $l = 0; $l < scalar(@lists); $l++)
{
   my $list = $lists[$l];

   if(-f $list and open(LIST, $list))
   {
      my @selected;
      my %selected;

      while(<LIST>)
      {
         chomp;
         push(@selected, $_);
         $selected{$_} = 1;
      }

      my %found;

      my $line_no = 0;

      open(FILE, $file) or die("Could not open file '$file' for reading"); while(<FILE>)
      {
         $line_no++;

         if($line_no > $headers)
         {
            my @x = split($delim, $_);

            if(scalar(@header) == 0)
            {
               @header = @x;

	       for(my $i = 0; $i < scalar(@header); $i++)
	       {
	          push(@seperator, "");
	          push(@missing, "");
	       }
	       $seperator[$field] = "Seperator";
	       $missing[$field] = "Missing";
	       $seperator = join($delim, @seperator);
            }

            chomp($x[$#x]);

            my $key  = $x[$field];

            if(exists($selected{$key}))
            {
               $found{$key} = $_;
            }
         }
         elsif(scalar(@header) == 0)
         {
            @header = split($delim, $_);

            print STDOUT $_;

	    for(my $i = 0; $i < scalar(@header); $i++)
	    {
	       push(@seperator, "");
	       push(@missing, "");
	    }
	    $seperator[$field] = "Seperator";
	    $missing[$field] = "Missing";
	    $seperator = join($delim, @seperator);
         }
      }

      foreach my $key (@selected)
      {
         if(exists($found{$key}))
         {
            print STDOUT $found{$key};
         }
	 elsif($print_missing)
	 {
	    $missing[$field] = '_' . $key . '_';

	    print STDOUT join($delim, @missing), "\n";
	 }
      }

      if($print_seperators and $l < scalar(@lists) - 1)
      {
         print STDOUT join($delim, $seperator), "\n";
      }

      close(FILE);

      close(LIST);
   }
}

exit(0);


__DATA__
syntax: rows.pl [OPTIONS] [FILE | < FILE] LIST1 [LIST2...]

Selects rows from FILE where the keys match the keys in the given
lists LIST1, LIST2, etc.

FILE - a tab-delimited file with the first column as the key.

LISTi - a file containing a list of keys.

OPTIONS are:

-q: Quiet mode (default is verbose)

-f COL: Set the key column to COL (default is 1).

-k COL: Same as -f.

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 0).

-s: Print seperators between each row (a line of blanks)

-m: Print missing values (in the list but not in the FILE).



