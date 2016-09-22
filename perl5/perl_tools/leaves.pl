#!/usr/bin/perl

##############################################################################
##############################################################################
##
## leaves.pl
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
                , [    '-k', 'scalar',     1, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-h', 'scalar',     1, undef]
                , [    '-b',   'list', undef, undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose  = not($args{'-q'});
my $key_col  = $args{'-k'} - 1;
my $delim    = $args{'-d'};
my $headers  = $args{'-h'};
my $branches = $args{'-b'};
my $file     = $args{'--file'};

my $filep = &openFile($file);
my $prev_indent = -1;
my @line_stack;
my %seen;
while(<$filep>)
{
   chomp;
   if(/^(\s*)\S/)
   {
      my $indent = length($1);

      # print STDERR join(",",values(%seen)), "\n";

      if($indent <= $prev_indent)
      {
         my $line = pop(@line_stack);

         if(&underBranch($branches, \%seen))
         {
            print STDOUT $line, "\n";
         }
      }

      push(@line_stack, $_);


      $prev_indent = $indent;

      $seen{$indent} = $_;

   }
}
close($filep);

if(scalar(@line_stack) > 0)
{
   if(&underBranch($branches, \%seen))
   {
      my $line = pop(@line_stack);
      print STDOUT $line;
   }
}

exit(0);

sub underBranch
{
   my ($branches, $seen) = @_;

   if(defined($branches) and scalar(@{$branches}) > 0)
   {
      foreach my $s (values(%{$seen}))
      {
         foreach my $b (@{$branches})
         {
            if($s =~ /$b/)
            {
               return 1;
            }
         }
      }

      return 0;
   }
   return 1;
}

__DATA__
syntax: leaves.pl [OPTIONS] [FILE | < FILE]

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Set the key column to COL (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 1).


