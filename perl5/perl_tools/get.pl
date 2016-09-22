#!/usr/local/bin/perl

##############################################################################
##############################################################################
##
## get.pl
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
                , [    '-a', 'scalar',     0,     1]
                , [  '-abs', 'scalar',     0,     1]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose  = not($args{'-q'});
my $machine  = defined($args{'-m'}) ? $args{'-m'} : $ENV{'REMOTEHOST'};
my $user     = defined($args{'-u'}) ? $args{'-u'} : $ENV{'USER'};
my $path     = $args{'-p'};
my $recurse  = $args{'-r'};
my $absolute = $args{'-abs'} + $args{'-a'};
my $extra    = $args{'--extra'};

my $exe     = $recurse ? 'scp -r' : 'scp';

if($machine !~ /\S/) {
   print STDERR "No machine name supplied.\n";
   exit(1);
}

if($user !~ /\S/) {
   print STDERR "No user name supplied.\n";
   exit(1);
}

if($absolute) {
   $path = '';
}
elsif(not(defined($path))) {

   my $home = $ENV{'HOME'};

   $path = $ENV{'PWD'};

   $path =~ s/$home/~/;

   if($path !~ /\/$$/) {
      $path .= '/';
   }
}

if(defined($extra)) {
   foreach my $file (@{$extra}) {
      my $address = $user . '@' . $machine . ':' . $path . $file;
      my $cmd = "$exe '$address' .";

      $verbose and print STDERR "Executing: $cmd\n";

      system($cmd);
   }
}

exit(0);

__DATA__
syntax: get.pl [OPTIONS] FILE1 [FILE2..]

OPTIONS are:

-q: Quiet mode (default is verbose)

-m MACHINE: Supply the machine to copy from (default is taken from the
            value in the environment variable $REMOTEHOST.

-u USER: Set the username of the account to copy from (default is $USER).

-p PATH: Set the path from where to copy the file. The default is to use the
         present working directory.

-abs: Use the absolute paths given to find the files. The default is to use the
      path in which the caller is presently working.


