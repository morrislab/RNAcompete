#!/usr/bin/perl

require "libfile.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-i', 'scalar',     1, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-b', 'scalar',     1, undef]
                , [    '-e', 'scalar',    10, undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose = not($args{'-q'});
my $file    = $args{'--file'};
my $inc     = $args{'-i'};
my $delim   = $args{'-d'};
my @extra   = @{$args{'--extra'}};
my $end     = scalar(@extra) == 1 ? $extra[0] :
              (scalar(@extra) > 1 ? $extra[1] : undef);
$end        = defined($end) ? $end : $args{'-e'};
$end        = defined($end) ? $end : int(100*rand);
my $beg     = scalar(@extra) >= 2 ? $extra[0] : undef;
$beg        = defined($beg) ? $beg : $args{'-b'};

for(my $i=$beg; $i<=$end; $i+=$inc)
{
   print STDOUT $i == $beg ? "" : $delim, $i;
}
print STDOUT "\n";

__DATA__
syntax: nums.pl [OPTIONS] [BEG] END

Generates numbers from BEG to END; one for each line.

Default for BEG is 1.

*** Note, if you are trying to number lines in a file,
*** you want "lin.pl" instead. Or you could run:
*** cat YOURFILE | awk '{ print FNR "\t" $0 }'
*** (which has equivalent output to lin.pl)

Options / Arguments:

BEG (optional):  (default value: 1)
      The number that we start counting from.

END (required):
      A non-negative integer.  If this is a filename, then
      nums.pl reads from the first line in the file.

-i INCREMENT: Increment the count by INCREMENT (default is 1).

-d DELIM: Print DELIM between each of the numbers (default is tab).

