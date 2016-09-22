#!/usr/bin/perl

##############################################################################
##############################################################################
##
## tab2gml.pl
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
                  [       '-q', 'scalar',           0,     1]
                , [ '-creator', 'scalar',"$ENV{USER}", undef]
                , [  '-labelg', 'scalar',          '', undef]
                , ['-directed', 'scalar',           1, undef]
                , [     '-k1e', 'scalar',           1, undef]
                , [     '-k1e', 'scalar',           1, undef]
                , [     '-k1e', 'scalar',           1, undef]
                , [     '-k2e', 'scalar',           2, undef]
                , [      '-kn', 'scalar',           1, undef]
                , [      '-de', 'scalar',        "\t", undef]
                , [      '-dn', 'scalar',        "\t", undef]
                , [      '-he', 'scalar',           0, undef]
                , [      '-hn', 'scalar',           0, undef]
                , [      '-nh', 'scalar',          40, undef]
                , [      '-nw', 'scalar',          40, undef]
                , [  '-widthe', 'scalar',           1, undef]
                , [   '-typen', 'scalar', '"ellipse"', undef]
                , [  '-widthn', 'scalar',   '1.00000', undef]
                , [   '-filln', 'scalar', '"#E1E1E1"', undef]
                , [  '-labele', 'scalar',      '"pp"', undef]
                , ['-outlinen', 'scalar', '"#000000"', undef] # Alex: fixed for Cytoscape: default should be #000000, not 1.00000. Outline is not a width, it is a color.
                , [  '-pixelx', 'scalar',        4000, undef]
                , [  '-pixely', 'scalar',        4000, undef]
                , [  '     -x', 'scalar',       undef, undef]
                , [       '-y', 'scalar',       undef, undef]
                , [   '--file',   'list',       ['-'], undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose        = not($args{'-q'});
my $creator        = $args{'-creator'};
my $label_g        = $args{'-labelg'};
my $directed       = $args{'-directed'};
my $key1_col_e     = $args{'-k1e'} - 1;
my $key2_col_e     = $args{'-k2e'} - 1;
my $key_col_n      = $args{'-kn'} - 1;
my $delim_e        = $args{'-de'};
my $delim_n        = $args{'-dn'};
my $headers_e      = $args{'-he'};
my $headers_n      = $args{'-hn'};
my $x_col          = $args{'-x'};
my $y_col          = $args{'-y'};
my $pixels_x       = $args{'-pixelx'};
my $pixels_y       = $args{'-pixely'};
my @files          = @{$args{'--file'}};

my %default_e;
$default_e{'label'} = $args{'-labele'};
$default_e{'width'} = $args{'-widthe'};

my %default_n;
$default_n{'h'}       = $args{'-nh'};
$default_n{'w'}       = $args{'-nw'};
$default_n{'type'}    = $args{'-typen'};
$default_n{'width'}   = $args{'-widthn'};
$default_n{'fill'}    = $args{'-filln'};
$default_n{'outline'} = $args{'-outlinen'};

my $edge_file = scalar(@files) >= 1 ? $files[0] : undef;
my $node_file = scalar(@files) >= 2 ? $files[1] : undef;

my ($edges, $header_e) = defined($edge_file) ?
                         &tableRead($edge_file, $delim_e,
                            [$key1_col_e, $key2_col_e], $headers_e) :
                         (undef, undef);


my ($nodes, $header_n) = defined($node_file) ?
                         &tableRead($node_file, $delim_n, [$key_col_n], $headers_n) :
                         (undef, undef);


defined($edges) or die("No edges supplied");

# Read edges, initialize nodes.
my %nodes;
my %edges;
my %node_attribs;
my %edge_attribs;
my $num_nodes = 0;
foreach my $edge (@{$edges})
{
   my ($uv, $attribs) = @{$edge};
   my ($u,$v) = split($delim_e, $uv);

   # &initEdgeAttribs($u, $v, $num_edges, \%edge_attribs, \%default_e);

   # &setEdgeAttribs($u, $v, \%edge_attribs, $attribs);

   my ($uid, $vid) = (undef, undef);
   if(not(exists($nodes{$u})))
   {
      $num_nodes++;
      $nodes{$u} = $num_nodes;
      &initNodeAttribs($u, $num_nodes, \%node_attribs, \%default_n);
      $uid = $num_nodes;
   }
   else { $uid = $node_attribs{$u, 'id'}; }

   if(not(exists($nodes{$v})))
   {
      $num_nodes++;
      $nodes{$v} = $num_nodes;
      &initNodeAttribs($v, $num_nodes, \%node_attribs, \%default_n);
      $vid = $num_nodes;
   }
   else { $vid = $node_attribs{$v, 'id'}; }

   $edges{$uv} = 1;

   $edge_attribs{$uv, 'source'} = $uid;
   $edge_attribs{$uv, 'target'} = $vid;
   $edge_attribs{$uv, 'label'}  = $default_e{'label'};
   $edge_attribs{$uv, 'width'}  = 2;
   $edge_attribs{$uv, 'type'}   = '"line"';
   $edge_attribs{$uv, 'fill'}   = '"#0000E1"';

}

# Store node attributes
foreach my $node_data (@{$nodes})
{
   my ($node, @values) = @{$node_data};
   for(my $i = 0; $i < scalar(@values); $i++)
   {
      my $attrib = $$header_n[$i];
      $node_attribs{$node, $attrib} = $values[$i];
   }
}

&layoutNodes(\%nodes, \%node_attribs, $pixels_x, $pixels_y);

print STDOUT "Creator \"$creator\" Version 1.0 graph [\n",
             "\tlabel\t\"$label_g\"\n",
             "\tdirected	$directed\n";

foreach my $node (keys(%nodes))
{
   print STDOUT &getGmlNodeString($node, \%node_attribs), "\n";
}

foreach my $edge (keys(%edges))
{
   my ($u, $v) = split($delim_e, $edge);

   print STDOUT &getGmlEdgeString($edge, \%edge_attribs), "\n";
}

print STDOUT "]\n";

exit(0);

sub layoutNodes
{
   my ($nodes, $attribs, $pixels_x, $pixels_y) = @_;

   my ($min_x, $max_x, $min_y, $max_y) = (undef, undef, undef, undef);
   foreach my $node (keys(%{$nodes}))
   {
      if(not(defined($$attribs{$node, 'x'})))
         { $$attribs{$node, 'x'} = rand; }
      if(not(defined($$attribs{$node, 'y'})))
         { $$attribs{$node, 'y'} = rand; }

      my $x = $$attribs{$node, 'x'};
      my $y = $$attribs{$node, 'y'};

      $min_x = (not(defined($min_x)) or ($x < $min_x)) ? $x : $min_x;
      $max_x = (not(defined($max_x)) or ($x > $max_x)) ? $x : $max_x;
      $min_y = (not(defined($min_y)) or ($y < $min_y)) ? $y : $min_y;
      $max_y = (not(defined($max_y)) or ($y > $max_y)) ? $y : $max_y;
   }

   my $range_x = $max_x - $min_x;
   my $range_y = $max_y - $min_y;
   foreach my $node (keys(%{$nodes}))
   {
      my $x = $$attribs{$node, 'x'};
      my $y = $$attribs{$node, 'y'};

      $$attribs{$node, 'x'} = ($x - $min_x) / $range_x * ($pixels_x - 1) + 1;
      $$attribs{$node, 'y'} = ($y - $min_y) / $range_y * ($pixels_y - 1) + 1;
   }
}

sub getGmlNodeString
{
   my ($node, $attribs) = @_;
   my @general  = ('id', 'label');
   my @graphics = ('x','y','w','h','type','width','fill','outline');
   my $gml = "\tnode\n\t[\n";

   foreach my $attrib (@general)
   {
      my $value  = $$attribs{$node, $attrib};
      $gml      .= "\t\t$attrib\t$value\n";
   }

   $gml .= "\t\tgraphics\n\t\t[\n";
   foreach my $attrib (@graphics)
   {
      my $value  = $$attribs{$node, $attrib};
      $gml      .= "\t\t\t$attrib\t$value\n";
   }
   $gml .= "\t\t]\n\t]\n";

   return $gml;
}

sub getGmlEdgeString
{
   my ($edge, $attribs) = @_;
   my @general  = ('source', 'target', 'label');
   my @graphics = ('width', 'type', 'fill');
   my $gml = "\tedge\n\t[\n";

   foreach my $attrib (@general)
   {
      my $value  = $$attribs{$edge, $attrib};
      $gml      .= "\t\t$attrib\t$value\n";
   }

   $gml .= "\t\tgraphics\n\t\t[\n";
   foreach my $attrib (@graphics)
   {
      my $value  = $$attribs{$edge, $attrib};
      $gml      .= "\t\t\t$attrib\t$value\n";
   }
   $gml .= "\t\t]\n\t]\n";

   return $gml;
}

#
sub initNodeAttribs
{
   my ($node, $id, $attribs, $defaults) = @_;
   $$attribs{$node, 'id'}       = $id;
   $$attribs{$node, 'label'}    = "\"$node\"";
   $$attribs{$node, 'x'}        = undef;
   $$attribs{$node, 'y'}        = undef;
   $$attribs{$node, 'w'}        = $$defaults{'w'};
   $$attribs{$node, 'h'}        = $$defaults{'h'};
   $$attribs{$node, 'type'}     = $$defaults{'type'};
   $$attribs{$node, 'width'}    = $$defaults{'width'};
   $$attribs{$node, 'fill'}     = $$defaults{'fill'};
   $$attribs{$node, 'outline'}  = $$defaults{'outline'};
}

__DATA__

Note: tab2gml.pl is perhaps more understandable, and is currently being maintained.

You might consider using it instead, unless you already know how to use tab2gml.pl.

syntax: tab2gml.pl [OPTIONS] [EDGE_FILE | < EDGE_FILE] [NODE_FILE]

The headers for each file describe which attribute is contained in each
column.  For example, labelling a node column 'type' allows one to
specify node shapes other than ellipse (the default).

EDGE_FILE - has ID1 <tab> ID2 [<tab> ATTRIB1 ...] on each line.

NODE_FILE - ID1 <tab> ATTRIB1 [<tab> ATTRIB2 ...] on each line.

OPTIONS are:

-q: Quiet mode (default is verbose)

-k1e COL: Set the key column to COL for the source edge (default is 1).

-k2e COL: Set the key column to COL for the target edge (default is 2).

-kn COL: Set the key column to COL for the node (default is 1).

-de DELIM: Set the field delimiter to DELIM for edges (default is tab).

-dn DELIM: Set the field delimiter to DELIM for nodes (default is tab).

-tn TYPE: Set node type to TYPE (default is ellipse).

-hn HEADERS  (node file)  and
-he HEADERS  (edge file)
   Set the number of header lines to HEADERS (default is 1).

-g GRAPHICS


EXAMPLE:

???
