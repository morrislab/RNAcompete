#!/usr/bin/perl

##############################################################################
##############################################################################
##
## tab2xgr.pl
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
                , [   '-hn', 'scalar',     0, undef]
                , [   '-he', 'scalar',     0, undef]
                , [    '-g',   'list',    [], undef]
                , [   '-gc', 'scalar', undef, undef]
                , [   '-gs',    'set', undef, undef]
                , ['--file',   'list',    [], undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose      = not($args{'-q'});
my $key_col      = $args{'-k'} - 1;
my $delim        = $args{'-d'};
my $node_headers = $args{'-hn'};
my $edge_headers = $args{'-he'};
my @group_files  = @{$args{'-g'}};
my $group_colors_file = $args{'-gc'};
my $groups_selected = $args{'-gs'};
my @files        = @{$args{'--file'}};

scalar(@files) >= 1 or die("Please supply a NODE and EDGE file");

my $node_file = $files[0];
my $edge_file = $files[1];

my %groups;
my %group_colors;

$group_colors{'default'} = '255,255,255';

foreach my $group_file (@group_files)
{
   open(GROUPS, $group_file) or die("Could not open group file '$group_file'");
   while(<GROUPS>)
   {
      my ($id, @groups) = split("\t");
      chomp($groups[$#groups]);
      foreach my $group (@groups)
      {
	 if(not(exists($groups{$id})))
	 {
	    my @list;
	    $groups{$id} = \@list;
	 }
	 push(@{$groups{$id}}, $group);
      }
   }
   close(GROUPS);
}

if(defined($group_colors_file))
{
   open(COLORS, $group_colors_file) or die("Could not open colors file '$group_colors_file'");
   while(<COLORS>)
   {
      chomp;
      my ($group, $color) = split("\t");
      $group_colors{$group} = $color;
   }
   close(COLORS);
}

foreach my $group (keys(%group_colors))
{
   my $color = $group_colors{$group};
   print STDOUT "NodeSettings \"$group\"\n",
                "[\n",
                "color=$color,1\n",
                "]\n\n";
}

my $line = 0;
my $num_nodes = 0;
my $filep = &openFile($node_file);
while(<$filep>)
{
   $line++;
   if(($line > $node_headers) and /\S/)
   {
      $num_nodes++;
      chomp;
      my ($id,$x,$y) = split($delim);
      my @groups = exists($groups{$id}) ? @{$groups{$id}} : ('default');

      my $selected_group = undef;
      foreach my $group (@groups)
      {
         if(not(defined($groups_selected)) or exists($$groups_selected{$group}))
         {
            $selected_group = $group;
         }
      }
      if(defined($selected_group))
      {
         print STDOUT "Node \"$id\"\n",
                      "[\n",
                      "x=$x\n",
                      "y=$y\n",
                      "settings=$selected_group\n",
                      "]\n\n";
      }
   }
}
close($filep);

if(defined($edge_file))
{
   $filep = &openFile($edge_file);
   my $num_edges = 0;
   $line = 0;
   while(<$filep>)
   {
      $line++;
      if(($line > $edge_headers) and /\S/)
      {
         $num_edges++;
         chomp;
         my ($id1, $id2) = split($delim);

         print STDOUT "Edge \"$num_edges\"\n",
                      "[\n",
                      "n1=$id1\n",
                      "n2=$id2\n",
                      "]\n\n";
      }
   }
   close($filep);
}

exit(0);


__DATA__
syntax: tab2xgr.pl [OPTIONS] NODE_FILE EDGE_FILE

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Set the key column to COL (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 1).

-g GROUPFILE: supply a grouping file for the members.

-gc COLORFILE: supply colors for each group.

-gs GROUP: Select a particular group to print (default prints all).

Produces a file like:

NodeSettings "nset"
[
shape=oval
color=255,255,255,1
print_name=true
width=20
height=30
font=arial,1,16
]

EdgeSettings "eset"
[
color=0,0,0,1
]

Node "node1"
[
x=1
y=2
settings=nset
]

Node "node2"
[
x=4
y=2
settings=nset
]

Edge "id"
[
n1=node1
n2=node2
settings=eset
]



