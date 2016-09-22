#!/usr/bin/perl

##############################################################################
##############################################################################
##
## cross.pl
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
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-u', 'scalar',     0,     1]
                , [    '-t', 'scalar',     0,     1]
                , [    '-o', 'scalar',     0,     1]
                , [    '-s', 'scalar',     0,     1]
                , [    '-l', 'scalar', undef, undef]
                , ['--file',   'list',    [], undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose       = not($args{'-q'});
my $delim         = $args{'-d'};
my $uniq          = $args{'-u'};
my $transpose     = $args{'-t'};
my $oriented      = $args{'-o'};
my $suppress_self = $args{'-s'};
my $label_col     = $args{'-l'};
my @files         = @{$args{'--file'}};

$label_col = defined($label_col) ? $label_col - 1 : undef;

if(scalar(@files) == 0)
{
   @files = ('-');
}

if(scalar(@files) == 2)
{
   my $fp1 = &openFile($files[0]);
   my @list1 = <$fp1>;
   close($fp1);

   my $list2;
   if($files[1] eq $files[0])
   {
      $list2 = \@list1;
   }
   else
   {
      my $fp2 = &openFile($files[1]);
      my @list2 = <$fp2>;
      close($fp2);
      $list2 = \@list2;
   }
   &printCrossProduct(\@list1, $list2, $uniq, $oriented, $suppress_self, undef, $delim);
}
elsif(scalar(@files) == 1)
{
   my $fp = &openFile($files[0]);
   if($transpose)
   {
      while(<$fp>)
      {
         my @list = split($delim);
         my $label = defined($label_col) ? splice(@list, $label_col, 1) : undef;
         &printCrossProduct(\@list, \@list, $uniq, $oriented, $suppress_self, $label, $delim);
      }
   }
   else
   {
      my @list = <$fp>;
      &printCrossProduct(\@list, \@list, $uniq, $oriented, $suppress_self, undef, $delim);
   }
   close($fp);
}
else
{
   print STDERR <DATA>;
   exit(1);
}

exit(0);

sub printCrossProduct
{
   my ($list1, $list2, $uniq, $oriented, $suppress_self, $label, $delim, $filep) = @_;
   $uniq  = defined($uniq)  ? $uniq  : 0;
   $delim = defined($delim) ? $delim : "\t";
   $filep = defined($filep) ? $filep : \*STDOUT;
   $label = defined($label) ? $delim . $label : '';

   my $n1 = scalar(@{$list1});
   my $n2 = scalar(@{$list2});

   my $end1 = $oriented ? $n1 - 1 : $n1;

   for(my $i = 0; $i < $n1; $i++)
   {
      chomp($$list1[$i]);
   }
   if($list1 != $list2)
   {
      for(my $j = 0; $j < $n2; $j++)
      {
         chomp($$list2[$j]);
      }
   }
   for(my $i = 0; $i < $end1; $i++)
   {
      my $beg2 = $oriented ? $i : 0;
      for(my $j = $beg2; $j < $n2; $j++)
      {
         if(not($uniq) or ($$list1[$i] ne $$list2[$j]))
         {
            if(not($suppress_self) or ($$list1[$i] ne $$list2[$j]))
            {
               print $filep $$list1[$i], $delim, $$list2[$j], $label, "\n";
            }
         }
      }
   }
}

__DATA__
syntax: cross.pl [OPTIONS] FILE1 [FILE2]

Takes the cross-product between two lists.  One contained
in FILE1 and the other in FILE2.

If only one file is supplied then it forms all possible pairs
for the list in FILE1.

OPTIONS are:

-q: Quiet mode (default is verbose)

-d DELIM: Set the delimiter between the two lines to DELIM (default is <tab>).

-uniq: Unique: do not include pairs where each line is identical.

-t: Transpose.  If this flag is set, the cross-product operation
                operates on every line in the file.  This is only
                used when a single file is supplied.  Items are
                assumed to be delimited by tabs (but this can
                be changed with the -d flag).

-o: Orientation of the links matters.  By default, the script
    only prints out unique unordered pairs such that either (A,B)
    or (B,A) will be printed but not both.  If this flag is
    set, the script will print out both orientations.

-s: Suppress printing out pairs where each member is identical
    such as (A,A).

-l LABEL_COLUMN: Specify that there is a column correponding
    to a label that should be used to associate with each
    reported pair.  By default no label is assumed.  This is
    only useful when the -t flag is set.

