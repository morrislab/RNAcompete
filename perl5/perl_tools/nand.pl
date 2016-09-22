#!/usr/local/bin/perl

##############################################################################
##############################################################################
##
## nand.pl
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

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

# my $verbose = 1;
my $verbose = not($args{'-q'});
my @cmds    = @{$args{'--extra'}};
my $n       = scalar(@cmds);

for(my $i = 0; $i < $n; $i++)
{
   my @args = split(/\s+/,$cmds[$i]);
   my $cmd  = shift @args;
   $verbose and print STDERR "Executing command '$cmd' with arguments: '", join(",",@args), "'.\n";
   if(system($cmd, @args))
   {
      $verbose and print STDERR "Not all commands successful: $i out of $n commands successful.\n";
      exit(1);
   }
}

$verbose and print STDERR "All commands successful: $n out of $n commands successful.\n";

exit(0);

__DATA__
syntax: nand.pl CMD1 CMD2 [CMD3...]

Implements the logical NAND operation on the command
exit status in a lazy fashion.

Executes the command in CMD2 only if the command in CMD1 is
successful.  The script checks the exit status of CMD1 and
if it is 0, it executes CMD2.  If more than two commands are
supplied, it will execute if the previous commands are
successful.  For example, it will execute CMD3 if both CMD1
and CMD2 are succesful.  This script will return a 0 only if
all of its argument commands return 0.


