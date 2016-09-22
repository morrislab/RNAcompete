#!/usr/bin/perl

##############################################################################
##############################################################################
##
## collapse.pl
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
                , [    '-k', 'scalar',     1, undef]
                , [   '-d1', 'scalar',  "\t", undef]
                , [   '-d2', 'scalar',   ",", undef]
                , [   '-na', 'scalar',  "NA", undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose = not($args{'-q'});
my $col     = int($args{'-k'}) - 1;
my $delim1  = $args{'-d1'};
my $delim2  = $args{'-d2'};
my $file    = $args{'--file'};
my $natext  = $args{'-na'};

my @order;

my %data;
my $filep;
open($filep, $file) or die("Could not open file '$file' for reading");
while(<$filep>)
{
    my @tuple = split($delim1, $_);
    chomp($tuple[$#tuple]);
    my $key = splice(@tuple, $col, 1);
    
    if(not(exists($data{$key})))
    {
	my $list_r = $data{$key} = [];
	foreach my $e (@tuple) {
	    push @{$list_r}, [$e];
	}
    
    push(@order, $key);
}
   else
   {
      my $list = $data{$key};

      my $n = scalar(@{$list});

      my $m = scalar(@tuple);

      my $min = ($n < $m) ? $n : $m;

      for(my $i = 0; $i < $min; $i++)
      {
	  push(@{$$list[$i]},  $tuple[$i]);
      }

      for(my $i = $m; $i < $n; $i++)
      {
	  push(@{$$list[$i]}, "");
      }
   }
}
close($filep);

sub collapse_entry {
    my ($list_r) = @_;
    my $numeric_count = 0;
    my $numeric_sum = 0;
    
    my $text_count = 0;
    my %text_entries;

    foreach my $e (@{$list_r}) {
	my $ne;
 	{ 
	    no strict "vars";
	    local $SIG{__WARN__} = sub {};
	    $ne = $e + 0;
	}
 	if ($e eq $ne) {
	    ++$numeric_count;
	    $numeric_sum += $ne;
	} elsif ($e eq $natext) {
	    # ignore
	} elsif ($e eq '') {
	    # ignore
	} else {
	    ++$text_count;
	    $text_entries{$e} = 1;
	}
    }
    if ($numeric_count > 0) {
	return $numeric_sum / $numeric_count;
    } else {
	return(join($delim2, keys(%text_entries)));
    }
}

foreach my $key (@order)
{
   my $list = $data{$key};

   print $key, $delim1;
   foreach my $list_r (@{$list}) {
#       print join($delim2, @{$list_r}), $delim1;
       my $s = collapse_entry($list_r);
       print $s, $delim1;
   }
   print "\n";
}

exit(0);

__DATA__
syntax: collapse.pl [OPTIONS]

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Compare the values in column COL to the threshold in the file (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).



