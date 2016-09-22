#!/usr/bin/perl

##############################################################################
##############################################################################
##
## find_rows.pl
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
use strict;

require "libfile.pl";
require "libset.pl";

$| = 1;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-k', 'scalar',     0, undef]
                , [    '-s',   'list',    [], undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-v', 'scalar',     1, undef]
                , [    '-f', 'scalar', undef, undef]
                , [    '-u', 'scalar',     0,     1]
                , ['--file', 'scalar',   '-', undef]
              );

my @extra;
my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose      = not($args{'-q'});
my $set_names    = $args{'-s'};
my $delim        = $args{'-d'};
my $key_row      = $args{'-k'};
my $row_val      = $args{'-v'};
my $list_file    = $args{'-f'};
my $print_union  = $args{'-u'};
my $file         = $args{'--file'};
my @extra = @{$args{'--extra'}};

if(scalar(@{$set_names}) == 0 and scalar(@extra) > 0)
{
   push(@{$set_names}, \@extra);
}

if(defined($list_file))
{
   $verbose and print STDERR "Reading set names from file '$list_file'.\n";
   my $more_names = &readFileName($list_file);
   $verbose and print STDERR "Done reading set names from file '$list_file'.\n";

   push(@{$set_names}, @{$more_names});
}

scalar(@{$set_names}) > 0 or die("Please supply a key name");

if($verbose)
{
   print STDERR "Selected sets:\n";
   foreach my $set_key (@{$set_names})
   {
      print STDERR "\t'$set_key'\n";
   }
}

$verbose and print STDERR "Reading in selected set(s) from '$file'...";
my $sets         = &setsReadMatrix($file,
                                   $row_val,
                                   $delim,
                                   0,
                                   $key_row + 1,
                                   undef,
                                   undef,
                                   &list2Set($set_names));
$verbose and print STDERR " done.\n";

if($print_union)
{
   my $union = &setsUnionSelf($sets);
   &setPrint($union);
}
else
{
   my $print_keys = &setSize($sets) > 1 ? 1 : 0;
   &setsPrint($sets, undef, undef, $print_keys);
}

__DATA__

find_rows.pl [FILE | < FILE]

   Prints the set of columns for a given row that have a certain value.
   For example, you can give it a GO file and specify a row you're
   interested in, and it will tell you all the GO categories that are '1'
   for that row/gene.

   -k <num>     The key row (default: 0)
   -s <name>    String value of the key row
   -v <value>   Value to find in order to print (default: 1)

   -u           Print the union of all the members from the supplied set names (default
                prints seperate lists in FASTA format).


