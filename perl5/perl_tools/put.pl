#!/usr/local/bin/perl

##############################################################################
##############################################################################
##
## put.pl
##
##############################################################################
##############################################################################
##
## Written by Josh Stuart.
##
##  Email address: jstuart@ucsc.edu
##          Phone: (831) 459-1344
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
                , [    '-m', 'scalar', undef, undef]
                , [    '-u', 'scalar', undef, undef]
                , [    '-p', 'scalar', undef, undef]
                , [    '-r', 'scalar',     0,     1]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose = not($args{'-q'});
my $machine = defined($args{'-m'}) ? $args{'-m'} : undef;
my $user    = defined($args{'-u'}) ? $args{'-u'} : $ENV{'USER'};
my $path    = $args{'-p'};
my $recurse = $args{'-r'};
my $extra   = $args{'--extra'};

$machine = defined($machine) ? $machine : exists($ENV{'FTPHOST'}) ? $ENV{'FTPHOST'} : undef;
$machine = defined($machine) ? $machine : exists($ENV{'REMOTEHOST'}) ? $ENV{'REMOTEHOST'} : undef;

my $exe     = $recurse ? 'scp -r' : 'scp';

if(not(defined($machine)) or $machine !~ /\S/) {
   print STDERR "No machine name supplied.\n";
   exit(1);
}

if($user !~ /\S/) {
   print STDERR "No user name supplied.\n";
   exit(1);
}

if(not(defined($path))) {

   my $home = $ENV{'HOME'};

   $path = $ENV{'PWD'};

   $path =~ s/$home/~/;
}

if(defined($extra)) {
   foreach my $file (@{$extra}) {

      my $address = $user . '@' . $machine . ':' . $path;

      my $cmd = "$exe '$file' '$address'";

      $verbose and print STDERR "Executing: $cmd\n";

      system($cmd);
   }
}

exit(0);

__DATA__
syntax: put.pl [OPTIONS] FILE1 [FILE2..]

OPTIONS are:

-q: Quiet mode (default is verbose)

-m MACHINE: Supply the machine to copy to (default is taken from the
            value in the environment variable $REMOTEHOST.

-u USER: Set the username of the account to copy to (default is $USER).

-p PATH: Set the path to which to copy the file. The default is to use the
         present working directory.


