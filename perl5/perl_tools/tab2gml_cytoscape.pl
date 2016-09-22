#!/usr/bin/perl -w

require "libfile.pl";
require "$ENV{MYPERLDIR}/lib/libstats.pl";

use POSIX qw(ceil floor); # import the ceil(ing) and floor functions for handling fractions/integers
use List::Util qw(max min);		# import the max and min functions
use Term::ANSIColor;

use strict;
use warnings;
#use diagnostics;

use File::Basename;
use Getopt::Long;

sub main();


sub printUsage() {
  print STDOUT <DATA>;
  exit(0);
}

sub readColIfExistsElseDefault {
  my ($arrayPtr, $indexCountingFromOne, $defaultValue) = @_;

  # If the array has something at this column, then return that.
  # Otherwise, return the default value.
  # Note that the index counts from ONE and not ZERO!

  if (!defined($indexCountingFromOne)) {
	return $defaultValue;
  }

  if (scalar(@$arrayPtr) > ($indexCountingFromOne-1)) {
	# might want to also check for empty values here before returning...
	if (!defined($$arrayPtr[$indexCountingFromOne-1]) || ($$arrayPtr[$indexCountingFromOne-1] eq '')) {
	  return $defaultValue;
	}
	return $$arrayPtr[$indexCountingFromOne-1];
  }
  
  return $defaultValue;
}


# ==1==
sub main() {					# Main program
  my ($delim) = "\t";
  
  my $nodeFile = '-';
  my $edgeFile = '-';

  my $edgeColorCol = undef;

  my $nodeFillColorCol = undef;
  my $nodeOutlineColorCol = undef;
  my $nodeShapeCol = undef;
  my $nodeWidthCol = undef;
  my $nodeHeightCol= undef;

  my $directed = 1;

  # Note that there are two types of options, those starting with n (which apply to the NODES file)
  # and those starting with e (which apply to the EDGES file) (actually there are also a few other options like "delim" that
  # are universal).
  GetOptions("help|?|man" => sub { printUsage(); }
			 , "u|undirected!" => sub { $directed = 0; }
			 , "delim|d=s" => \$delim
			 , "e=s" => \$edgeFile
			 , "n=s" => \$nodeFile
			 , "nw=i" => \$nodeWidthCol
			 , "nh=i" => \$nodeHeightCol
			 , "nshape=i" => \$nodeShapeCol
			 , "ncolor|nfill=i" => \$nodeFillColorCol
			 , "noutline=i" => \$nodeOutlineColorCol
			 , "ecolor=i"   => \$edgeColorCol      # the column (numbered from *1* where the edge color is (in the edges file)
			) or printUsage();

  #print "Unprocessed by Getopt::Long\n" if $ARGV[0];
  
  my $OPEN = "[\n";
  my $CLOSE = "]\n";

  my %nodes = ();
  my $numNodesRead = 0;
  
  print "Creator \"default\" Version 1.0 graph" . "\n";
  print $OPEN; {
	print "label\t\"\"" . "\n";
	print "directed" . "\t" . $directed . "\n";
	
	# EDGES
	open(EDGES, "< $edgeFile") or die "Could not open  file $edgeFile.\n"; {
	  my %edgesAlreadyPrinted = ();
	  while (my $line = <EDGES>) {
		chomp($line);
		my @e = split(/$delim/, $line);
		if (scalar @e < 2) { die "An edge file must have at least two items per line (source <DELIM> target).\n"; }
		my $edgeSource = $e[0];
		my $edgeTarget = $e[1];
		my $edgeLabel  = readColIfExistsElseDefault(\@e, 3, "pp");
		my $edgeColor  = readColIfExistsElseDefault(\@e, $edgeColorCol, "#0000E1");

		if (not ($edgeColor =~ /^\#[0-9A-F]{6}$/)) {
		  die "\n\n\n*** ERROR in a file passed to tab2gml_cytoscape.pl: Got an invalid edge color:\n*** The invalid color was: $edgeColor\n*** Colors must be of the format #RRGGBB, where R,G,B are in the set 0-9 and A-F (they are hexadecimal digits).\n*** Examples: #FFFFF for white, #FF8800 for a bright orange.\n";
		}

		my $edgeWidth  = 2;
		
		if (!defined($nodes{$edgeSource})) {
		  $nodes{$edgeSource} = $numNodesRead;
		  $numNodesRead++;
		}
		if (!defined($nodes{$edgeTarget})) {
		  $nodes{$edgeTarget} = $numNodesRead;
		  $numNodesRead++;
		}

		if (!defined($edgesAlreadyPrinted{$edgeSource})
					 || !defined($edgesAlreadyPrinted{$edgeSource}{$edgeTarget})) {
		  # Don't print out edges more than once, or Cytoscape hates it. (Fails to read the GML)
		  $edgesAlreadyPrinted{$edgeSource}{$edgeTarget} = 1;
		  print "edge" . "\n";
		  print $OPEN; {
			print "source"   . "\t" . $nodes{$edgeSource} . "\n";
			print "target"   . "\t" . $nodes{$edgeTarget} . "\n";
			print "label"    . "\t" . qq{"$edgeLabel"} . "\n";
			print "graphics" . "\n";
			print $OPEN; {
			  print "width" . "\t" . $edgeWidth . "\n";
			  print "type" . "\t"  . qq{"line"}    . "\n";
			  print "fill" . "\t"  . qq{"$edgeColor"} . "\n";
			} print $CLOSE;
		  } print $CLOSE;
		  print "\n";
		}
	  } # end of while loop
	} close(EDGES);
	
	# NODES
	open(NODES, "< $nodeFile") or die "Could not open NODES file $nodeFile.\n"; {
	  my %nodesAlreadyPrinted = ();
	  while (my $line = <NODES>) {
		chomp($line);
		my @a = split(/$delim/, $line);
		my $nodeLabel = $a[0];
		my $nodeFillColor     = readColIfExistsElseDefault(\@a, $nodeFillColorCol, "#E1E1E1"); # last argument is the default value
		my $nodeOutlineColor  = readColIfExistsElseDefault(\@a, $nodeOutlineColorCol, "#000000");
		my $nodeShape  = readColIfExistsElseDefault(\@a, $nodeShapeCol, "ellipse");
		my $nodeWidth  = readColIfExistsElseDefault(\@a, $nodeWidthCol, 30);
		my $nodeHeight = readColIfExistsElseDefault(\@a, $nodeHeightCol, 30);

		if (!defined($nodes{$nodeLabel})) {
		  $nodes{$nodeLabel} = $numNodesRead;
		  $numNodesRead++;
		}

		if (!defined($nodesAlreadyPrinted{$nodeLabel})) {
		  # only print each node one time at most...
		  $nodesAlreadyPrinted{$nodeLabel} = 1;
		  print "node\n";
		  print $OPEN; {
			print "id" . "\t" . $nodes{$nodeLabel} . "\n";
			print "label" . "\t" . qq{"$nodeLabel"} . "\n";
			print "graphics\n";
			print $OPEN; {
			  print "x\t100" . "\n";
			  print "y\t100" . "\n";
			  print "w" . "\t" . $nodeWidth . "\n";
			  print "h" . "\t" . $nodeHeight . "\n";
			  print "type"    . "\t" . qq{"$nodeShape"} . "\n";
			  print "width"   . "\t" . 1.00000 . "\n";
			  print "fill"    . "\t" . qq{"$nodeFillColor"} . "\n";
			  print "outline" . "\t" . qq{"$nodeOutlineColor"} . "\n";
			} print $CLOSE;
		  } print $CLOSE;
		  print "\n";
		}
	  }
	} close(NODES);
	
  } print $CLOSE;

  #foreach (@ARGV) {
	# print "$_\n";
  #}

}								# end main()

main();

exit(0);
# ====

__DATA__

tab2gml_cytoscape.pl -e=EDGES_FILE -n=NODES_FILE

Converts tab-delimited edges + nodes files into a Cytoscape-readable GML file.

See below for an example.

CAVEATS:
  All nodes mentioned in the edges file must be also mentioned in the nodes file.
  Otherwise cytoscape will complain that it cannot find a node that was mentioned
  as being part of an edge.

TO DO:
  * Add a flag for auto-adding nodes from ones we read in edges. (In that case,
    the nodes file would be optional.)

  * Add a line width option

OPTIONS:

--delim or -d = DELIMITER
  Set the delimiter between items in the input files.

--e = EDGES_FILENAME

--n = NODES_FILENAME

--nw = COLUMN_INDEX (counting from 1)
  Column in the nodes file where we find the node width. 40 is a normal size.

--nh = COLUMN_INDEX (counting from 1)
  Column in the nodes file where we find the node height. 40 is a normal size.

--noutline = COLUMN_INDEX (counting from one)
  Column in the nodes file where we find the node OUTLINE color. Colors
  are of the format #RRGGBB.

--ncolor or --nfill = COLUMN_INDEX (counting from 1)
  Column in the nodes file where we find the node fill color.

--nshape = COLUMN_INDEX (counting from 1)
  Column in the nodes file where we find the node shape. Shapes can be
  triangle , rectangle, or ellipse .

--ecolor = COLUMN_INDEX (counting from 1)
  Column in the nodes file where we find the edge line color. Colors
  are of the format #RRGGBB.


EXAMPLE:

Example edges file: (tab-delimited columns) (note the self-link from d to d)

node_a     node_b       pp       #FFFF00
node_d     node_a       gl       #00FFFF
node_c     node_b       gl       #00FFFF
node_d     node_d       pp       #FFFF00

(Note that only the first two columns are required for the edges file)

Example nodes file: (tab-delimited)

node_a   triangle
node_b   ellipse
node_c   rectangle
node_d   rectangle

(Note that only the first column is actually required for a nodes file)

You would read in the above files with:

tab2gml_cytoscape -e=MY_EDGES --ecolor=4  -n=MY_NODES --nshape=2
                                       ^                       ^
                          Column 4 in the edges file           |
                          contains edge color info.     Column 2 in the nodes
                                                     file contains shape info.




