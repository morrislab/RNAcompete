#!/usr/bin/perl

##############################################################################
##############################################################################
##
## rm.pl
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


# Also check trash.pl in this same directory.
# trash.pl is meant to be a "safer rm," which moves things to a trash can
# instead of immediately removing them. trash.pl will mangle names, so it's
# not necessarily going to be easy to restore things.

require "libfile.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-l', 'scalar', undef, undef]
                , ['--file',   'list',    [], undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose   = not($args{'-q'});
my @files     = @{$args{'--file'}};
my @extra     = @{$args{'--extra'}};
my $list      = $args{'-l'};
my $max_files = 50;

if(defined($list) and ((-f $list) or ($list eq '-')))
{
   if(open(LIST, $list))
   {
      while(<LIST>)
      {
         chomp;
         push(@files, $_);
      }
      close(LIST);
   }
}

# To make the deletion faster, put shorter files first (this ensures that
# a directory is deleted before its individual files.

@files  = sort { length($a) <=> length($b); } @files;

while(@files)
{
   my $end        = (scalar(@files) < $max_files) ? scalar(@files) : $max_files;

   my @some_files = splice(@files, 0, $end);

   my $command = "rm " . join(" ", @extra) . " " . join(" ", @some_files);

   $verbose and print STDERR "'$command'\n";

   system($command);
}

exit(0);


__DATA__
syntax: rm.pl [OPTIONS] [FILE | < FILE]

Generalizes the UNIX rm command utility.  Any additional options that are not
recognized below are passed on to the rm command.

OPTIONS are:

-q: Quiet mode (default is verbose)

-l LIST: Supply a list of files in the file LIST to delete.



