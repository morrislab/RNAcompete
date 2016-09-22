#!/usr/bin/perl

##############################################################################
##############################################################################
##
## sort_rows.pl
##
##############################################################################
##############################################################################
##
## Written by Josh Stuart.
##
##  Email address: jstuart@ucsc.edu
##          Phone: (650) 725-7612
##
## Postal address: Department of Bioengineering, UCSC
##                 1156 High Street
##                 Santa Cruz, CA 95060
##
##       Web site: http://www.soe.ucsc.edu/~jstuart/
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
                , [    '-f', 'scalar', undef, undef]
                , [    '-k', 'scalar', undef, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-n', 'scalar',     0,     1]
                , [    '-g', 'scalar',     0,     1]
                , [    '-r', 'scalar',     0,     1]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose  = not($args{'-q'});
my $fields   = defined($args{'-k'}) ? $args{'-k'} : $args{'-f'};
my $sort_num = ($args{'-n'} + $args{'-g'}) > 0 ? 1 : 0;
my $sort_rev = $args{'-r'};
my $delim    = $args{'-d'};
my $file     = $args{'--file'};

# If no user-supplied columns, use all of them.
$fields = defined($fields) ? $fields : '1:-1';

my @cols;
my $prev_cols = 0;

my $filep;
open($filep, $file) or die("Could not open file '$file' for reading");
while(<$filep>)
{
   my @x = split($delim, $_);
   my $num_cols = scalar(@x);

   if(defined($fields)) {
     if($num_cols != $prev_cols) {
       @cols = &parseRanges($fields, $num_cols, -1);
     }
   }
   $prev_cols = $num_cols;

   if($#x >= 0)
     { chomp($x[$#x]); }

   my @tuple;
   foreach my $i (@cols) {
     if($i <= $#x) {
        push(@tuple,$x[$i]);
     }
   }

   if(not($sort_num) and not($sort_rev))
      { @tuple = sort { $a cmp $b; } @tuple; }
   elsif(not($sort_num) and $sort_rev)
      { @tuple = sort { $b cmp $a; } @tuple; }
   elsif($sort_num and not($sort_rev))
      { @tuple = sort { $a <=> $b; } @tuple; }
   elsif($sort_num and $sort_rev)
      { @tuple = sort { $b <=> $a; } @tuple; }

   # Replace the sorted stuff into the original vector.
   for(my $j = 0; $j < @cols; $j++) {
     my $i = $cols[$j];
     if($i <= $#x and $j <= $#tuple) {
        $x[$i] = $tuple[$j];
     }
   }

   print join($delim, @x), "\n";

}
close($filep);

exit(0);

__DATA__
syntax: sort_rows.pl [OPTIONS]

OPTIONS are:

-q: Quiet mode (default is verbose)

-f COLS: Sort only the entries in these columns. Default: all columns are used.

-k COLS: Same as -f (for backward compatability).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-n: Sort numerically (default sorts each column lexically).

-g: Same as -n.

-r: Sort in reverse order.




