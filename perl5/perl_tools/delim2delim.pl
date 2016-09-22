#!/usr/bin/perl

require "libfile.pl";
require "$ENV{MYPERLDIR}/lib/libset.pl";

use strict;
use warnings;

$| = 1;

my @flags   = (
                  [     '-q', 'scalar',     0,     1]
                , [     '-f', 'scalar', undef, undef]
                , [ '--file', 'scalar',   '-', undef]
              );
my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose    = not($args{'-q'});
my $col_ranges = $args{'-f'};
my $file       = $args{'--file'};
my @extra      = @{$args{'--extra'}};

my $delim_in   = scalar(@extra) > 0 ? $extra[0] : "\t";
my $delim_out  = scalar(@extra) > 1 ? $extra[1] : " ";
my $cols       = undef;
my $max_cols   = 0;
my $filep      = &openFile($file);
while(<$filep>)
{
   if(not(defined($col_ranges)))
   {
      s/$delim_in/$delim_out/g;
      print;
   }
   else
   {
      my @tuple     = split($delim_in);
      my $tmp_cols  = &getCols(\@tuple, $col_ranges, \$max_cols);
      $cols         = defined($tmp_cols) ? $tmp_cols : $cols;
      my $col_set   = &list2Set($cols);
      my $converted = shift @tuple;
      for(my $i = 0; $i < scalar(@tuple); $i++)
      {
         my $delim  = exists($$col_set{$i}) ? $delim_out : $delim_in;
         $converted .= $delim . $tuple[$i];
      }
      print $converted;
   }
}
close($filep);

__DATA__
syntax: delim2delim.pl [DELIM1] [DELIM2] < FILE

Converts the DELIM1 delimiters in standard input to DELIM2 delimiters in standard output.  If
no delimiters are supplied it converts tabs to a single space.
