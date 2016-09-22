#!/usr/bin/perl

##############################################################################
##############################################################################
##
## scp.pl
##
##############################################################################
##############################################################################
##
## Written by Josh Stuart.
##
##  Email address: jstuart@ucsc.edu
##          Phone: (831) 459-1344
##
## Postal address: Department of Biomolecular Engineering
##                 Baskin Engineering 129
##                 University of California, Santa Cruz
##                 Santa Cruz, CA 95064
##
##############################################################################

require "libfile.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [  '-dir', 'scalar', undef, undef]
                , [   '-up', 'scalar',     0,     1]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose       = not($args{'-q'});
my $dir           = $args{'-dir'};
my $up            = $args{'-up'};
my @extra         = @{$args{'--extra'}};
my $num           = '';

for(my $i = scalar(@extra) - 1; $i >= 0; $i--)
{
   if($extra[$i] =~ /^-(\d+)/)
   {
      $num = $1;
      splice(@extra, $i, 1);
   }
}

if(not(defined($dir)))
{
   my $var = "SCP_DIR$num";
   $dir    = exists($ENV{$var}) ? $ENV{$var} : 'localhost:~';
}

my $options = '';

for(my $i = scalar(@extra) - 1; $i >= 0; $i--)
{
   if($extra[$i] =~ /^-/)
   {
      $options = splice(@extra, $i, 1) . ' ' . $options;
   }
}

scalar(@extra) >= 1 or die("Please supply at least a source");

if(scalar(@extra) == 1)
{
   push(@extra, ($up ? "" : "."));
}

my $second        = pop(@extra);
my $first         = pop(@extra);
my $source_prefix = $up ? '' : "$dir/";
my $target_prefix = $up ? "$dir/" : '';
my $source        = $source_prefix . $first;
my $target        = $target_prefix . $second;
my $cmd           = "scp $options $source $target";

$verbose and print STDERR "Executing `$cmd'.\n";

my $child = undef;

exec($cmd);

exit(0);


__DATA__
syntax: scp.pl [OPTIONS] FILE1 [FILE2 FILE3 ...]

OPTIONS are passed to the scp command.

-up: If supplied tells the script to upload the files from the
     remote host rather than download them (download is default).

-N: Use the Nth scp directory listed as SCP_DIRN in the environment


