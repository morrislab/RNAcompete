#!/usr/bin/perl

##############################################################################
##############################################################################
##
## random.pl
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
                 ,[    '-n', 'scalar',     1, undef]
                 ,[    '-r', 'scalar', undef, undef]
                 ,[    '-c', 'scalar', undef, undef]
                 ,[    '-d', 'scalar', undef, undef]
                 ,[    '-s', 'scalar',     3, undef]
                 ,[    '-a', 'scalar',     0,     1]
                 ,[   '-dc', 'scalar',  "\t", undef]
                 ,[   '-dr', 'scalar',  "\n", undef]
                 ,[   '-dn', 'scalar',  "\n", undef]
                 ,[    '-i', 'scalar', undef, undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose    = not($args{'-q'});
my $number     = $args{'-n'};
my $rows       = $args{'-r'};
my $cols       = $args{'-c'};
my $integer    = $args{'-i'};
my $seed       = $args{'-d'};
my $sigfigs    = $args{'-s'};
my $after      = $args{'-a'};
my $delim_cols = $args{'-dc'};
my $delim_rows = $args{'-dr'};
my $delim_nums = $args{'-dn'};
my @extra      = @{$args{'--extra'}};
my $file       = undef;

foreach my $ex (@extra) {
   if((-f $ex) or (-l $ex) or ($ex eq '-')) {
      $file = $ex;
   }
   elsif($ex =~ /^\d+$/ and not(defined($rows))) {
      $rows = $ex;
   }
   elsif($ex =~ /^\d+$/ and not(defined($cols))) {
      $cols = $ex;
   }
}
$rows = defined($rows) ? $rows : 1;
$cols = defined($cols) ? $cols : 1;
$seed = defined($seed) ? $seed : time()^($$+($$<<15));
srand($seed);

if(defined($file)) {
   my $fp = &openFile($file);
   while(<$fp>) {
      chomp;
      my @rands;
      for(my $i = 1; $i <= $number; $i++) {
         push(@rands, &getRand($sigfigs, $integer));
      }
      print STDOUT $after ? ($_ . $delim_cols . join($delim_cols, @rands))
                          : (join($delim_cols, @rands) . $delim_cols . $_), "\n";
   }
   close($fp);
}
else {
   for(my $i = 1; $i <= $number; $i++) {
      for(my $row = 0; $row < $rows; $row++) {
         my @rands;
         for(my $col = 0; $col < $cols; $col++) {
            push(@rands, &getRand($sigfigs, $integer));
         }
         print STDOUT join($delim_cols, @rands), $delim_rows;
      }
      print STDOUT $delim_nums;
   }
}

exit(0);

sub getRand {
   my ($sigfigs, $integer) = @_;
   my $r = rand();
   $r = defined($integer) ? int($r*$integer)+1 : $r;
   return &format_number($r, $sigfigs);
}

__DATA__
syntax: random.pl [OPTIONS] [ROWS | ROWS COLS | FILE]

Produces random numbers. Can produce a ROWS-by-COLS matrix
of random numbers by specifying one or two arguments on the
command-line respectively (or use the -r and -c options).

If FILE is specified, it produces N random numbers for each line of the file.

OPTIONS are:

-q: Quiet mode (default is verbose)

-d SEED: Make random numbers deterministic (default is non-deterministic).  For every
         value of SEED, the same random numbers will be returned.

-s SIGS: Set the number of significant digits to SIGS (default is 3).

-a: Print the random numbers after the row of the file.

-n N: Print N random replicates. If ROWS and COLUMNS are set, produces N random
      matrices of size ROW-by-COLUMN.

-i INTEGER: Produce random number(s) between 1 and INTEGER inclusive (default produces
            reals between 0 and 1, non-inclusive).

-r ROWS: Set the number of rows of random numbers (default is 1). Overrides
         any command-line argument supplied.

-c COLS: Set the number of columns of random numbers (default is 1). Overrides
         any command-line argument supplied.

-dc DELIM: Column delimiter (default is "\t").

-dr DELIM: Row delimiter (default is "\n").

-dn DELIM: Delimiter between the n replicates (default is "\n").

