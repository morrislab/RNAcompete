#!/usr/bin/perl

##############################################################################
##############################################################################
##
## merge_fields.pl
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
require "$ENV{MYPERLDIR}/lib/libset.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;


my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-d', 'scalar', undef, undef]
                , [   '-d1', 'scalar',  "\t", undef]
                , [   '-d2', 'scalar', undef, undef]
                , [    '-f',   'list',    [], undef]
                , [    '-h', 'scalar',     1, undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose   = not($args{'-q'});
my @fields    = @{$args{'-f'}};
my $delim     = $args{'-d'};
my $delim1    = $args{'-d1'};
my $delim2    = $args{'-d2'};
my $headers   = $args{'-h'};
my $file      = $args{'--file'};

$delim1 = defined($delim) ? $delim : $delim1;
$delim2 = defined($delim) ? $delim : $delim2;

my $line = 0;
my $filep;
open($filep, $file) or die("Could not open file '$file' for reading");
my @order;
while(<$filep>)
{
   $line++;

   my @x = split($delim1, $_);
   chomp($x[$#x]);

   if($line == $headers)
   {
      @order = @{&orderHeader(\@x, \@fields)};
   }

   my $merged = &groupTuple(\@x, \@order, $delim2);

   print STDOUT join($delim1, @{$merged}), "\n";
}
close($filep);

exit(0);

sub groupTuple
{
   my ($tuple, $groups, $delim) = @_;

   my $len = scalar(@{$tuple});

   my @grouped;

   foreach my $group (@{$groups})
   {
      my @merged;
      foreach my $i (@{$group})
      {
	 my $entry = $i < $len ? $$tuple[$i] : '';

	 if(defined($delim))
	 {
	    push(@merged, $entry);
	 }
	 elsif($entry =~ /\S/)
	 {
	    # Keep overwriting
	    $merged[0] = $entry;
	 }
      }

      my $merged = join(defined($delim) ? $delim : "", @merged);

      push(@grouped, $merged);
   }

   return \@grouped;
}

sub orderHeader
{
   my ($header, $fields) = @_;

   my %fields = %{&list2Set($fields)};

   my $destination = undef;

   for(my $i = 0; $i < @{$header} and not(defined($destination)); $i++)
   {
      if(exists($fields{$$header[$i]}))
      {
         $destination = $i;
      }
   }

   my @order;

   for(my $i = 0; $i < @{$header}; $i++)
   {
      if(exists($fields{$$header[$i]}))
      {
         push(@{$order[$destination]}, 0, $i);
      }
      else
      {
         push(@order, [$i]);
      }
   }

   return \@order;
}


__DATA__
syntax: merge_fields.pl [OPTIONS] [FILE | < FILE]

OPTIONS are:

-q: Quiet mode (default is verbose)

-f FIELD: Merges any columns that start with the header FIELD.
          Multiple -f may be used.

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Specify the number of rows that are headers (default 1).
            Only the last of these is used to match the supplied
            fields.


