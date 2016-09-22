#!/usr/bin/perl

##############################################################################
##############################################################################
##
## if.pl - Prints TRUE if the file has any non-white space in it.
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
                , [    '-n', 'scalar',     0,     1]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose = not($args{'-q'});
my $return  = $args{'-n'};
my @extra   = @{$args{'--extra'}};

scalar(@extra) >= 1 or die("Please supply at least a file and a truth argument.");

my $file   = $extra[0];

my $true   = scalar(@extra) >= 2 ? $extra[1] : 1;

my $false  = scalar(@extra) >= 3 ? $extra[2] :
             (scalar(@extra) >= 2 ? '' : 0);

my $result = 0;

if((-f $file) or ($file eq '-'))
{
   my $filep = &openFile($file);
   my $done = 0;
   while(not($done))
   {
      $_ = <$filep>;
      if(/\S/)
      {
         $result = 1;
         $done   = 1;
      }
      elsif(eof($filep))
      {
         $done = 1;
      }
   }
   close($filep);
}
else
{
   $result = 0;
}

if($result)
{
   if((-f $true) or ($true eq '-'))
   {
      my $truep = &openFile($true);
      while(<$truep>) { print STDOUT $_; }
      close($truep);
   }
   else
   {
      print STDOUT $true, (($return and ($true =~ /\S/)) ? "\n" : "");
   }
}
else
{
   if((-f $false) or ($false eq '-'))
   {
      my $falsep = &openFile($false);
      while(<$falsep>) { print STDOUT $_; }
      close($falsep);
   }
   else
   {
      print STDOUT $false, (($return and ($false =~ /\S/)) ? "\n" : "");
   }
}

exit(0);


__DATA__
syntax: if.pl [OPTIONS] [FILE | < FILE] TRUE [FALSE]

OPTIONS are:

-q: Quiet mode (default is verbose)

-n: Print an extra carraige-return after TRUE (and FALSE if supplied).


