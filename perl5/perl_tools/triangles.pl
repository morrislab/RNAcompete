#!/usr/bin/perl

##############################################################################
##############################################################################
##
## triangles.pl
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
require "$ENV{MYPERLDIR}/lib/libset.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [   '-k1', 'scalar',     1, undef]
                , [   '-k2', 'scalar',     2, undef]
                , [  '-dir', 'scalar',     0,     1]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-h', 'scalar',     1, undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose       = not($args{'-q'});
my $key_col1      = $args{'-k1'};
my $key_col2      = $args{'-k2'};
my $delim         = $args{'-d'};
my $headers       = $args{'-h'};
my $file          = $args{'--file'};

$key_col1--;
$key_col2--;

$verbose and print STDERR "Reading in edges from '$file'...";
my $edges = &setsRead($file, $delim, $key_col1, $key_col2, undef, 1);

my $num_nodes = &setSize($edges);
$verbose and print STDERR " done ($num_nodes nodes read).\n";

my %triangles;

my $iter = 0;
my $passify = 100;
$verbose and print STDERR "Identifying edges that participate in triangles.\n";
foreach my $u (keys(%{$edges}))
{
   my $u_set = $$edges{$u};

   foreach my $v (keys(%{$u_set}))
   {
      $iter++;

      if(not(exists($triangles{$u . $delim . $v})) or
         not(exists($triangles{$v . $delim . $u})))
      {
         exists($$edges{$v}) or die("Edge set for '$v' does not exist");

         my $v_set = $$edges{$v};

         my @v_nbrs = keys(%{$v_set});
         my $is_triangle = 0;
         for(my $i = 0; ($i < scalar(@v_nbrs)) and not($is_triangle); $i++)
         {
            my $w = $v_nbrs[$i];
            if(exists($$u_set{$w}))
            {
               $triangles{$u . $delim . $v} = 1;
               $triangles{$u . $delim . $w} = 1;
               $triangles{$v . $delim . $w} = 1;
               $is_triangle = 1;
            }
         }
      }

      if($iter % $passify == 0)
      {
         print STDERR "$iter edges analyzed.\n";
      }
   }
}
$verbose and print STDERR "Done.\n";

my %printed;
foreach my $triangle (keys(%triangles))
{
   my ($u, $v) = split($delim, $triangle);

   if(not(exists($printed{$u . $delim . $v})) and
      not(exists($printed{$v . $delim . $u})))
   {
      if(($u cmp $v) <= 0)
        { print STDOUT $u, $delim, $v, "\n"; }
      else
        { print STDOUT $v, $delim, $u, "\n"; }
      $printed{$u . $delim . $v} = 1;
      $printed{$v . $delim . $u} = 1;
   }
}

exit(0);


__DATA__
syntax: triangles.pl [OPTIONS] [FILE | < FILE]

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Compare the values in key_column COL to the threshold in the file (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 1).



