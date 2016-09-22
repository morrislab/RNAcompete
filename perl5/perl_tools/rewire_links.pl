#!/usr/bin/perl

##############################################################################
##############################################################################
##
## rewire.pl
##
##############################################################################
##############################################################################
##
## Written by Josh Stuart.
##
##  Email address: jstuart@ucsc.edu
##          Phone: (831) 459-1344
##
## Postal address: Department of Biomolecular Engineering
##                 Baskin Engineering 129
##                 University of California, Santa Cruz
##                 Santa Cruz, CA 95064
##
##############################################################################

require "libfile.pl";
require "$ENV{MYPERLDIR}/lib/liblist.pl";
require "$ENV{MYPERLDIR}/lib/libset.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [   '-f1', 'scalar',     1, undef]
                , [   '-f2', 'scalar',     2, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-h', 'scalar',     0, undef]
                , [    '-m', 'scalar',    10, undef]
                , [    '-l', 'scalar',     0,     1]
                , [    '-r', 'scalar',     0,     1]
                , [    '-u', 'scalar',     0,     1]
                , [    '-U', 'scalar', undef, undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose       = not($args{'-q'});
my $field1        = $args{'-f1'} - 1;
my $field2        = $args{'-f2'} - 1;
my $delim         = $args{'-d'};
my $headers       = $args{'-h'};
my $max_failures  = $args{'-m'};
my $left          = $args{'-l'};
my $right         = $args{'-r'};
my $universe_file = $args{'-U'};
my $undirected    = $args{'-u'};
my $file          = $args{'--file'};
my @extra         = @{$args{'--extra'}};

my $edges = [];
my %edges;
my %left_keys;
my %right_keys;
my %all_keys;
open(FILE, $file) or die("Could not open file '$file' for reading");
while(<FILE>)
{
   my @x = split($delim, $_);

   chomp($x[$#x]);

   my $key1 = undef;
   my $key2 = undef;
   if($field1 > $field2)
   {
      $key1 = splice(@x, $field1, 1);
      $key2 = splice(@x, $field2, 1);
   }
   else
   {
      $key2 = splice(@x, $field2, 1);
      $key1 = splice(@x, $field1, 1);
   }
   # If undirected, randomly orient the edge so get different rewiring
   # results each time.
   if($undirected) {
      if(rand() < 0.5) {
         my $tmp = $key1;
         $key1 = $key2;
         $key2 = $tmp;
      }
      my $e = $key1 . $delim . $key2;
      if(not(exists($edges{$e}))) {
         push(@{$edges}, [$key1, $key2, \@x]);
         $edges{$e} = 1;
      }
   }
   else {
      push(@{$edges}, [$key1, $key2, \@x]);
   }

   $left_keys{$key1}  = 1;
   $right_keys{$key2} = 1;
   $all_keys{$key1}   = 1;
   $all_keys{$key2}   = 1;
}
close(FILE);

my $universe = undef;
if(defined($universe_file))
{
   $universe = &list2Set(&readFileColumn($universe_file, 1), 1);
}

my %new_edges;

if(not($left) and not($right))
{
   # Scramble the order so we don't always rewire in the
   # same sequence.

   $edges = &listPermute($edges);

   # foreach my $e (@{$edges}) {
   #    print join(",",@{$e}), "\n";
   # }

   my %failed_attempts;

   while(scalar(@{$edges}) > 1)
   {
      my $e1 = pop(@{$edges});
      my $e2 = pop(@{$edges});
      my $u1 = $$e1[0];
      my $v1 = $$e1[1];
      my $x1 = $$e1[2];
      my $u2 = $$e2[0];
      my $v2 = $$e2[1];
      my $x2 = $$e2[2];

      my $old_e1 = $u1 . $delim . $v1;
      my $old_e2 = $u2 . $delim . $v2;
      my $new_e1 = $u1 . $delim . $v2;
      my $new_e2 = $u2 . $delim . $v1;
      my $rev_e1 = $v2 . $delim . $u1;
      my $rev_e2 = $v1 . $delim . $u2;

      # Don't allow creation of self-loops or repeats.
      if(($u1 ne $v2) and ($u2 ne $v1)
          and not(exists($new_edges{$new_e1}))
          and not(exists($new_edges{$new_e2}))
          and (not($undirected) or (not(exists($new_edges{$rev_e1}))))
          and (not($undirected) or (not(exists($new_edges{$rev_e2}))))
        ) 
      {
         # print STDERR "Rewired '$old_e1' <=> '$old_e2'.\n";
         my @x1 = ($u1, $v2, @{$x1});
         my @x2 = ($u2, $v1, @{$x2});
         $new_edges{$new_e1} = \@x1;
         $new_edges{$new_e2} = \@x2;
      }
      else
      {
         $failed_attempts{$old_e1}++;

         $failed_attempts{$old_e2}++;

         if($failed_attempts{$old_e1} >= $max_failures)
         {
            if(not(exists($new_edges{$old_e1})))
            {
               # Put the first edge on the bottom.
               my @x1 = ($u1, $v1, @{$x1});
               $new_edges{$old_e1} = \@x1;
            }
         }
         else
         {
            # print STDERR "Could not rewire '$old_e1' <=> '$old_e2'.\n";

            # Put the first edge on the bottom.
            unshift(@{$edges}, $e1);
            # splice(@{$edges}, scalar(@{$edges}), 0, $e1);
         }
         if($failed_attempts{$old_e2} >= $max_failures)
         {
            if(not(exists($new_edges{$old_e2})))
            {
               my @x2 = ($u2, $v2, @{$x2});
               $new_edges{$old_e2} = \@x2;
            }
         }
         else
         {
            # Put the second edge on the top.
            push(@{$edges}, $e2);
            # splice(@{$edges}, 0, 0, $e1);
         }
      }
   }
   while(scalar(@{$edges})) {
      my $edge = pop(@{$edges});
      my ($u, $v, $x) = @{$edge};
      my @x = ($u, $v, @{$x});
      my $e = $u . $delim . $v;
      my $r = $v . $delim . $u;
      if(not(exists($new_edges{$e}))
         and (not($undirected) or (not(exists($new_edges{$r}))))) {
         $new_edges{$e} = \@x;
      }
   }

   my $map = &getRandomMap(\%all_keys, $universe);
   foreach my $edge (keys(%new_edges))
   {
      my $x = $new_edges{$edge};
      if(defined($map))
      {
         $$x[0] = $$map{$$x[0]};
         $$x[1] = $$map{$$x[1]};
      }
      print STDOUT join($delim, @{$x}), "\n";
   }
}
else
{
   $left and $verbose and print STDERR "Permuting left side of edges.\n";
   $left and &permuteColumn($edges, $field1);

   $right and $verbose and print STDERR "Permuting right side of edges.\n";
   $right and &permuteColumn($edges, $field2);

   my $map = ($left and $right) ? &getRandomMap($universe, \%all_keys) :
              ($left ? &getRandomMap(\%left_keys, $universe) :
                       &getRandomMap(\%right_keys, $universe));

   foreach my $e (@{$edges})
   {
      my ($u, $v, $x) = @{$e};

      if(defined($map))
      {
         $u = $left  ? $$map{$u} : $u;
         $v = $right ? $$map{$v} : $v;
      }

      unshift(@{$x}, ($u, $v));
      print STDOUT join($delim, @{$x}), "\n";
   }
}

exit(0);

sub getRandomMap
{
   my ($from_set, $to_set) = @_;

   my $map = undef;

   if(defined($from_set) and defined($to_set))
   {
      foreach my $from_key (keys(%{$from_set}))
      {
         if(not(exists($$to_set{$from_key})))
         {
            $$to_set{$from_key} = 1;
         }
      }

      my @from_keys = keys(%{$from_set});
      my @to_keys = keys(%{$to_set});

      my $n = scalar(@from_keys);
      my $m = scalar(@to_keys);
      if($n > 0 and $m > 0)
      {
         my %map;
         &permuteList(\@to_keys);
         for(my $i = 0; $i < $n; $i++)
         {
            $map{$from_keys[$i]} = $to_keys[$i];
         }
         $map = \%map;
      }
   }
   return $map;
}

__DATA__
syntax: rewire.pl [OPTIONS] [FILE | < FILE]

OPTIONS are:

-q: Quiet mode (default is verbose)

-f COL: Set the key column to COL (default is 1).

-k COL: Same as -f.

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 1).

-m MAX_FAILURES: The maximum number of failures allowed for rewiring a single edge
                 (default is 10).

-u: Treat the graph as undirected (default is directed).



