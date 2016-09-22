#!/usr/local/bin/perl

##############################################################################
##############################################################################
##
## table2visant.pl
##
## Takes tab-delimited edge and node data files, and outputs an XML-format
## graph file that can be read by the graph viewing utility VisANT.
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
require "$ENV{MYPERLDIR}/lib/libgraph.pl";
require "$ENV{MYPERLDIR}/lib/libset.pl";

use strict;
use warnings;

use Getopt::Long;
use POSIX qw(ceil floor);

# Prototype
sub readListFileIntoHash($);


# Flush output to STDOUT immediately.
$| = 1;

my $default_edge_color = 'black';

my @flags   = (
			   [    '-q', 'scalar',     0,     1]
			   , [    '-d', 'scalar',  "\t", undef]
			   , [  '-dir', 'scalar',     0,     1]
			   , [   '-f1', 'scalar',     1, undef]
			   , [   '-f2', 'scalar',     2, undef]
			   , [   '-ec', 'scalar', undef, undef]
			   , [   '-el', 'scalar', undef, undef]
			   , [    '-l', 'scalar', undef, undef]
			   , [    '-g', 'scalar', undef, undef]
			   , [    '-t', 'scalar', undef, undef]
			   , [    '-s', 'scalar', undef, undef]
			   , [    '-h', 'scalar', undef, undef]
			   , [    '-w', 'scalar', undef, undef]
			   , [    '-f', 'scalar',     1, undef]
			   , [    '-x', 'scalar', undef, undef]
			   , [    '-y', 'scalar', undef, undef]
			   , [   '-nc', 'scalar', undef, undef]
			   , [   '-gc', 'scalar', undef, undef]
			   , [    '-r', 'scalar',     0,     1]
			   , ['--file',   'list',    [], undef]
			   );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

my ($nodeAttribFilename) = undef;
my ($mainNodeFilename  ) = undef;
my ($secondaryNodeFilename) = undef;
my %mainNodeHash = ();
my %secondaryNodeHash = ();

# IMPORTANT: Note that GetOptions CONSUMES @ARGV--you CAN'T use it afterward)!
# More info about GetOptions: http://www.perl.com/doc/manual/html/lib/Getopt/Long.html
Getopt::Long::Configure(qw(pass_through)); # pass_through: "Don't flag options we don't process as errors"
GetOptions("help|man|?", sub { print STDOUT <DATA>; exit(0); }
		   , "nodeattribs=s", \$nodeAttribFilename
		   , "mainnodes=s",   \$mainNodeFilename
		   , "secondarynodes=s", \$secondaryNodeFilename
		   );

my $verbose        = not($args{'-q'});
my $directed       = $args{'-dir'};
my $delim          = $args{'-d'};
my $key_col1       = &undefAdd($args{'-f1'}, -1);
my $key_col2       = &undefAdd($args{'-f2'}, -1);

my $edge_color_col = &undefAdd($args{'-ec'}, -1);
my $edge_label_col = &undefAdd($args{'-el'}, -1);

my $key_col        = &undefAdd($args{'-f'}, -1);
my $x_col          = &undefAdd($args{'-x'}, -1);
my $y_col          = &undefAdd($args{'-y'}, -1);
my $node_color_col = &undefAdd($args{'-nc'}, -1);
my $type_col       = &undefAdd($args{'-t'}, -1);
my $label_col      = &undefAdd($args{'-l'}, -1);
my $group_col      = &undefAdd($args{'-g'}, -1);
my $group_color_col= &undefAdd($args{'-gc'}, -1);
my $size_col       = &undefAdd($args{'-s'}, -1);
my $height_col     = &undefAdd($args{'-h'}, -1);
my $width_col      = &undefAdd($args{'-w'}, -1);
my $restrict       = $args{'-r'};
my @files          = @{$args{'--file'}};

my %GLOBAL_edge_method_assignment = ();

if(scalar(@files) == 0)
{
	@files = ('-');
}

# Maps color names for edges to their VisAnt specific
# methods.
my %color2method =
(
 'black'       => 'M0099'
 , 'gray'        => 'M9901', 'grey'        => 'M9901'
 , 'green'       => 'M0010'
 , 'orange'      => 'M0054'
 , 'blue'        => 'M0034'
 , 'purple'      => 'M0013'
 , 'red'         => 'M0026'
 , 'brown'       => 'M0033'
# , 'yellow'      => 'M0019'
 , 'pink'        => 'M0028'
 , 'hotpink'     => 'M0053'
 , 'lightblue'   => 'M0041'
 , 'turquoise'   => 'M0041'
 , 'lightgreen'  => 'M0049'
 , 'lightpurple' => 'M0018'
 , 'lightred'    => 'M0036'
 , 'lightorange' => 'M0025'
 , 'army'        => 'M0050'
 , 'armygreen'   => 'M0050'
 , 'darkgreen'   => 'M0050'
 );

my %color2rgb =
(
 'black'      => '0 0 0'
 , 'white'      => '255 255 255'
 , 'grey'       => '127 127 127', 'gray'       => '127 127 127'
 , 'red'        => '255 0 0'
 , 'green'      => '0 255 0'
 , 'blue'       => '0 0 255'
 , 'purple'     => '148 0 211'
 , 'yellow'     => '255 204 0'
 , 'lightblue'  => '255 127 255'
 , 'lightblue'  => '127 255 255'
 , 'lightgreen' => '0 0 255'
 , 'darkgreen'  => '0 127 0'
 , 'orange'     => '255 127 0'
 , 'brown'      => '139 69 19'
 , 'yellow'  => '0 245 255'
 , 'pink'       => '255 20 147'
 , 'default'    => '200 200 200'
 );
# , 'yellow'     => '255 255 0'

my @edge_attrib_cols = @{&keepDefined(($edge_color_col
									   , $edge_label_col
									   ))};
# 42 -1


my @node_attrib_cols = @{&keepDefined(( $key_col
										, $x_col
										, $y_col
										, $node_color_col
										, $type_col
										, $group_col
										, $group_color_col
										, $size_col
										, $height_col
										, $width_col
										))};


# print STDERR "[", join("\n", @edge_attrib_cols), "]\n";

print STDOUT '<?xml version="1.0"?>', "\n";

print STDOUT '<VisAnt ver="1.32" species="sce" nodecount="236" edgeopp="false" fineArt="true">'
, "\n\t" . '<method name="M0029" desc="monoclonal antibody" weight="null" type="E" visible="true" color="0,182,212"/>'
, "\n\t" . '<method name="M0028" desc="mass spectrometry studies of complexes" weight="null" type="E" visible="true" color="255,182,212"/>'
, "\n\t" . '<method name="M0059" desc="genetic synthetic phenotype" weight="null" type="E" visible="true" color="193,100,42"/>'
, "\n\t" . '<method name="M0026" desc="In vitro binding" weight="null" type="E" visible="true" color="255,0,90"/>'
, "\n\t" . '<method name="M0058" desc="genetic suppression" weight="null" type="E" visible="true" color="28,144,242"/>'
, "\n\t" . '<method name="M0025" desc="colocalization by immunostaining" weight="null" type="E" visible="true" color="255,165,0"/>'
, "\n\t" . '<method name="M0057" desc="genetic,suppression expression alteration" weight="null" type="E" visible="true" color="123,109,238"/>'
, "\n\t" . '<method name="M0024" desc="Immunoprecipitation" weight="null" type="E" visible="true" color="105,67,159"/>'
, "\n\t" . '<method name="M0056" desc="genetic,suppression mutation" weight="null" type="E" visible="true" color="0,51,153"/>'
, "\n\t" . '<method name="M0055" desc="genetic,synthetic growth effect" weight="null" type="E" visible="true" color="144,176,17"/>'
, "\n\t" . '<method name="M0054" desc="genetic,conditional synthetic lethal" weight="null" type="E" visible="true" color="242,103,26"/>'
, "\n\t" . '<method name="M0021" desc="western blot" weight="null" type="E" visible="true" color="129,94,42"/>'
, "\n\t" . '<method name="M0053" desc="filter binding" weight="null" type="E" visible="true" color="255,0,204"/>'
, "\n\t" . '<method name="M0020" desc="genetic,tetrad analysis" weight="null" type="E" visible="true" color="204,113,0"/>'
, "\n\t" . '<method name="M0052" desc="fluorescence polarization spectroscopy" weight="null" type="E" visible="true" color="0,153,153"/>'
, "\n\t" . '<method name="M0051" desc="elisa" weight="null" type="0" visible="true" color="193,100,42"/>'
, "\n\t" . '<method name="M0050" desc="phage display" weight="null" type="E" visible="true" color="166,195,96"/>'
, "\n\t" . '<method name="M0019" desc="Gel retardation assays " weight="null" type="E" visible="true" color="158,240,27"/>'
, "\n\t" . '<method name="M0018" desc="molecular sieving" weight="null" type="E" visible="true" color="142,146,215"/>'
, "\n\t" . '<method name="M0049" desc="surface plasmon resonance" weight="null" type="E" visible="true" color="137,220,101"/>'
, "\n\t" . '<method name="M0048" desc="structure based prediction" weight="null" type="E" visible="true" color="174,121,131"/>'
, "\n\t" . '<method name="M0047" desc="genetic,synthetic lethal" weight="null" type="E" visible="true" color="91,167,147"/>'
, "\n\t" . '<method name="M9999" desc="KEGG Pathway" weight="null" type="E" visible="true" color="250,51,131"/>'
, "\n\t" . '<method name="M0014" desc="cross-linking studies" weight="null" type="E" visible="true" color="176,48,96"/>'
, "\n\t" . '<method name="M0046" desc="Bayesian Predicted Interaction" weight="null" type="C" visible="true" color="162,230,60"/>'
, "\n\t" . '<method name="M9901" desc="Connection of Shared Components" weight="null" type="C" visible="true" color="185,191,180"/>'
, "\n\t" . '<method name="M0013" desc="copurification" weight="null" type="E" visible="true" color="85,26,139"/>'
, "\n\t" . '<method name="M0045" desc="affinity chromatography" weight="null" type="E" visible="true" color="139,169,9"/>'
, "\n\t" . '<method name="M0012" desc="Competition binding" weight="null" type="E" visible="true" color="12,254,34"/>'
, "\n\t" . '<method name="M0044" desc="Affinity Precipitation" weight="null" type="E" visible="true" color="8,130,224"/>'
, "\n\t" . '<method name="M0010" desc="coimmunoprecipitation" weight="null" type="E" visible="true" color="25,110,6"/>'
, "\n\t" . '<method name="M0042" desc="Chromatin Immunoprecipitation (ChIP)" weight="null" type="E" visible="true" color="100,14,33"/>'
, "\n\t" . '<method name="M0041" desc="Transcription Factor" weight="null" type="E" visible="true" color="22,214,233"/>'
, "\n\t" . '<method name="M0040" desc="Screened two hybrid test" weight="null" type="E" visible="true" color="232,14,133"/>'
, "\n\t" . '<method name="M0039" desc="transient coexpression" weight="null" type="E" visible="true" color="34,255,209"/>'
, "\n\t" . '<method name="M0006" desc="Affinity Column" weight="null" type="E" visible="true" color="191,88,3"/>'
, "\n\t" . '<method name="M0038" desc="gene neighbourhoods" weight="null" type="C" visible="true" color="205,95,245"/>'
, "\n\t" . '<method name="M0037" desc="phylogenetic profile" weight="null" type="C" visible="true" color="6,185,76"/>'
, "\n\t" . '<method name="M0036" desc="domain fusion" weight="null" type="C" visible="true" color="205,95,138"/>'
, "\n\t" . '<method name="M0099" desc="unknown" weight="null" type="E" visible="true" color="0,0,0"/>'
, "\n\t" . '<method name="M0034" desc="two hybrid" weight="null" type="E" visible="true" color="0,0,255"/>'
, "\n\t" . '<method name="M0033" desc="cosedimentation through density gradients" weight="null" type="E" visible="true" color="125,93,66"/>'
, "\n\t" . '<method name="M0031" desc="Other Biophysical" weight="null" type="E" visible="true" color="125,93,255"/>'
, "\n\t" . '<method name="M0063" desc="colocalization/visualisation technologies" weight="null" type="E" visible="true" color="0,0,0"/>'
, "\n\t" . '<method name="M0030" desc="other genetic" weight="null" type="E" visible="true" color="125,182,97"/>'
, "\n\t" . '<method name="M0062" desc="electron microscopy" weight="null" type="E" visible="true" color="0,0,0"/>'
, "\n\t" . '<method name="M0061" desc="resonance energy transfer" weight="null" type="E" visible="true" color="0,0,0"/>'
, "\n\t" . '<method name="M5001" desc="Tandem Affinity Mass. Spec Complex Determination from Gavin, et al." weight="null" type="g" visible="true" color="0,0,0"/>'
, "\n\t" . '<method name="M0060" desc="far western blotting" weight="null" type="E" visible="true" color="0,0,0"/>'
, "\n"
;



if (defined($mainNodeFilename)) {
# This file just has a list of node names in it, one per line.
# We will color / indicate these nodes differently from the others.
	%mainNodeHash = readListFileIntoHash($mainNodeFilename);
}

if (defined($secondaryNodeFilename)) {
# This file just has a list of node names in it, one per line.
# We will color / indicate these nodes differently from the others.
	%secondaryNodeHash = readListFileIntoHash($mainNodeFilename);
}



my $graph = &graphReadEdgeList($files[0], $delim, $key_col1, $key_col2, $directed, \@edge_attrib_cols); # function in libgraph.pl

my %groups;

my %node_attribs;
if(scalar(@files) > 1 || defined($nodeAttribFilename))
{
    if (!(defined($nodeAttribFilename))) { 
		$nodeAttribFilename = $files[1];
    }
    open(FILE, $nodeAttribFilename) or die("Could not open NODES file '$nodeAttribFilename'.");
    
	while(<FILE>)
	{
		my @tokens = split($delim);
		chomp($tokens[$#tokens]);
		
		my $node = $tokens[$key_col];
		
		my %attribs;
		
		$attribs{'x'}      = defined($x_col)          ? $tokens[$x_col] : undef;
		$attribs{'y'}      = defined($y_col)          ? $tokens[$y_col] : undef;
		$attribs{'node_color'}  = defined($node_color_col) ? $tokens[$node_color_col] : undef;
		$attribs{'label'}  = defined($label_col)      ? $tokens[$label_col] : undef;
		my $group          = defined($group_col) ? $tokens[$group_col] : undef;
		$attribs{'group'}  = $group;
		$attribs{'group_color'}  = defined($group_color_col) ? $tokens[$group_color_col] : undef;
		$attribs{'size'}   = defined($size_col)       ? $tokens[$size_col] : undef;
		$attribs{'height'} = defined($height_col)     ? $tokens[$height_col] : undef;
		$attribs{'width'}  = defined($width_col)      ? $tokens[$width_col] : undef;
		$attribs{'type'}   = defined($type_col)       ? $tokens[$type_col] : undef;
		
# print STDERR "$tokens[$key_col] $key_col\n";
# print STDERR "$tokens[$group_col] $group_col\n";
# print STDERR "$group_col\n";
				
		$node_attribs{$node} = \%attribs;
		
		if(defined($group))
		{
			&createIfNotExist(\%groups, $group, 'set');
			
			my $group_nodes = $groups{$group};
			
			$$group_nodes{$node} = 1;
		}
	}
	close(FILE);
}

if($restrict)
{
	$graph = &graphDeleteNodes($graph, \%node_attribs);
}

&convertEdgeColors2Methods($graph, \%color2method, $default_edge_color);

my $nodes = &graphNodes($graph);

print STDOUT "\t<Nodes>\n";
my $index = 0;
foreach my $node (keys(%{$nodes})) {
	&printNode($node, $graph, $node_attribs{$node}, \$index, \%color2rgb, $directed);
}

foreach my $group (keys(%groups)) {
	&printGroup($group, $groups{$group}, \%node_attribs, \$index, \%color2rgb);
}

print STDOUT "\t</Nodes>\n";

&printEdges($graph);

print STDOUT "</VisAnt>\n";

exit(0);

sub isAttribDefined($$) { # Returns a boolean value
	my ($attribPtr, $name) = @_;
	return (defined($attribPtr) and exists($$attribPtr{$name}) and defined($$attribPtr{$name}));
}

sub printNode
{
	my ($node, $graph, $attribs, $index, $col2rgb, $directed, $filep) = @_;
	
	my $new_index = 0;
	
	my $defaultSize = 15;
	
	my $label    = isAttribDefined($attribs, 'label')  ? $$attribs{'label'}  : $node;
	my $group    = isAttribDefined($attribs, 'group')  ? $$attribs{'group'}  : undef;
	my $x        = isAttribDefined($attribs, 'x')      ? $$attribs{'x'}      : 250;
	my $y        = isAttribDefined($attribs, 'y')      ? $$attribs{'y'}      : 250;
	
	my $color = 'default';
	if (isAttribDefined($attribs, 'node_color')) {	$color = $$attribs{'node_color'};
	} elsif (defined($mainNodeHash{$node})) {
		$color = 'red';
	} elsif (defined($secondaryNodeHash{$node})) {
		$color = 'blue';
	}
	
	my $size = $defaultSize;
	if (isAttribDefined($attribs, 'size')) {		$size = $$attribs{'size'};
	} elsif (defined($mainNodeHash{$node})) {		$size = 2 * $defaultSize;
	} elsif (defined($secondaryNodeHash{$node})) {	$size = floor(1.5 * $defaultSize);
	}
	
	my $width    = isAttribDefined($attribs, 'width')    ? $$attribs{'width'}    : $defaultSize;
	my $height   = isAttribDefined($attribs, 'height')   ? $$attribs{'height'}   : $defaultSize;
	my $type     = isAttribDefined($attribs, 'type')     ? $$attribs{'type'}     : 100;
	my $labelOn  = isAttribDefined($attribs, 'labelOn')  ? $$attribs{'labelOn'}  : 'true';
	my $labelPos = isAttribDefined($attribs, 'labelPos') ? $$attribs{'labelPos'} : 0;
	my $expandOn = isAttribDefined($attribs, 'expandOn') ? $$attribs{'expandOn'} : 'false';
	
	$index       = defined($index) ? $index : \$new_index;
	$filep       = defined($filep)  ? $filep  : \*STDOUT;
	
	my $num_nbrs = exists($$graph{$node}) ?
		scalar(keys(%{$$graph{$node}})) : 0;
	
	my $count = $num_nbrs + 1;
	
	my $nodeRGB; # Node color: 3-digit RGB triplets: like 200 100 100 (RED GRN BLU)
		if (exists($$col2rgb{$color})) {
			$nodeRGB = $$col2rgb{$color}; # If there is already a mapping from $color to "200 0 0" (for example), then use that
		} elsif ($color =~ /\d{1,3}\s\d{1,3}\s\d{1,3}/) {
			$nodeRGB = $color; # Otherwise, if the color is already an RGB value of the form "R G B", we use that
		} else {
			$nodeRGB = $$col2rgb{'default'}; # If $color is not a valid color name, and it is also not a valid RGB triplet, use the default node color.
			printVerbose("Note: the node color '$color' is not valid or else was not found in our list of mappings. We are using the default node color instead.");
		}
			
# print STDERR "'$color' => '$rgb'\n";
			
			print $filep "\t\t<VNodes"
				, " x=\"$x\""
				, " y=\"$y\""
				, " counter=\"$count\""
				, " w=\"$width\""
				, " h=\"$height\""
				, defined($group) ? " group=\"$group\"" : ""
				, " labelOn=\"$labelOn\""
				, " size=\"$size\""
				, " ncc=\"$nodeRGB\""
				, " labelPos=\"$labelPos\""
				, " esymbol=\"$expandOn\""
				, ">\n"
				, "\t\t\t<vlabel>$label</vlabel>\n"
				, "\t\t\t<data"
				, " name=\"$node\""
				, " index=\"$$index\""
				, " type=\"$type\""
				, ">\n"
				;
			
			&printEdgesFromNode($node, $graph, $directed);
			
			if(defined($group))
			{
				print $filep "\t\t\t\t<group name=\"common\" value=\"$group\"/>\n";
			}
			
			print $filep "\t\t\t</data>\n"
				, "\t\t</VNodes>\n"
				;
			$$index++;
}

sub printGroup
{
	my ($group_name, $group_set, $attribs, $index, $col2rgb, $filep) = @_;
	
	my $new_index = 0;
	
	my ($min_x,$max_x) = &getMinMaxAttrib($attribs,$group_set,'x');
	my ($min_y,$max_y) = &getMinMaxAttrib($attribs,$group_set,'y');
	my ($min_h,$max_h) = &getMinMaxAttrib($attribs,$group_set,'height');
	my ($min_w,$max_w) = &getMinMaxAttrib($attribs,$group_set,'width');
	
	my ($group_color) = &getGroupColorAttrib($attribs,$group_set);
	
	$min_x = defined($min_x) ? $min_x : 0;
	$max_x = defined($max_x) ? $max_x : 250;
	$min_y = defined($min_y) ? $min_y : 0;
	$max_y = defined($max_y) ? $max_y : 250;
	$min_h = defined($min_h) ? $min_h : 30;
	$max_h = defined($max_h) ? $max_h : 30;
	$min_w = defined($min_w) ? $min_w : 30;
	$max_w = defined($max_w) ? $max_w : 30;
	my $range_x = $max_x - $min_x;
	my $range_y = $max_y - $min_y;
	
#   die "NO\n" unless (exists($node_attribs{'group_color'}));
#   my $group_color    = (defined($attribs) and exists($$attribs{'group_color'}) and defined($$attribs{'group_color'}))  ? $$attribs{'group_color'}  : 'default';
	my $x      = $max_x;
	my $y      = $max_y;


	my $rgb    = (defined($group_color) && exists($$col2rgb{$group_color}))
	             ? $$col2rgb{$group_color} : $$col2rgb{'default'};
	my $width  = $range_x > $max_w ? $range_x : $max_w;
	my $height = $range_y > $max_y ? $range_y : $max_y;
	my $type   = '3';
	$index     = defined($index) ? $index : \$new_index;
	$filep     = defined($filep)  ? $filep  : \*STDOUT;
	
	my $count  = 1;
	
	print $filep "\t\t<VNodes"
		, " x=\"$x\""
		, " y=\"$y\""
		, " counter=\"1\""
		, " w=\"$width\""
		, " h=\"$height\""
		, " ncc=\"$rgb\""
		, ">\n"
		, "\t\t\t<vlabel>$group_name</vlabel>\n"
		, "\t\t\t<children>"
		, join(',', keys(%{$group_set}))
		, "</children>\n"
		, "\t\t\t<data"
		, " name=\"$group_name\""
		, " index=\"$$index\""
		, " type=\"$type\""
		, ">\n"
		, "\t\t\t</data>\n"
		, "\t\t</VNodes>\n"
		;
	$$index++;
}

sub printEdgesFromNode
{
	my ($node, $graph, $directed, $filep) = @_;
	$directed = defined($directed) ? $directed : 1;
	$filep    = defined($filep) ? $filep : \*STDOUT;
	my $fromType = 0;
	my $toType   = $directed ? 1 : 0;
	if(defined($node) and defined($graph))
	{
		my $nbrs = $$graph{$node};
		foreach my $nbr (keys(%{$nbrs}))
		{
			my $mtd = $GLOBAL_edge_method_assignment{$node . $delim . $nbr}; #$$nbrs{$nbr};
			$mtd = ($mtd =~ /^M\d+/) ? $mtd : 'M0099';
			print $filep "\t\t\t\t<link to=\"$nbr\""
				, " method=\"$mtd\""
				, " fromType=\"$fromType\""
				, " toType=\"$toType\""
				, "/>\n";
		}
	}
}

sub printEdges
{
	my ($graph, $filep) = @_;
	$filep = defined($filep) ? $filep : \*STDOUT;
	if(defined($graph))
	{
		print $filep "\t<Edges>\n";
		foreach my $node (keys(%{$graph}))
		{
			my $nbrs = $$graph{$node};
			foreach my $nbr (keys(%{$nbrs}))
			{
				&printEdge($node, $nbr, $filep, $graph);
			}
		}
		print $filep "\t</Edges>\n";
	}
}

sub printEdge
{
	my ($from, $to, $filep, $graphPtr) = @_;
	
	my ($indexOfEdgeLabel) = undef; # the index of the edge label, within the "$attributes" (which is a delimited string of many various edge attributes)
	
	if (defined($edge_label_col) && $edge_label_col > -1) {
		# if the edges have labels...
		for (my $count = 0; $count < scalar(@edge_attrib_cols); $count++) {
			if ($edge_attrib_cols[$count] == $edge_label_col) {
				$indexOfEdgeLabel = $count;
				last; # "break" out of the loop
			}
			# This loop seems slightly strange, but I *think* it is the only way to
			# figure out where in the list of $delimit-delimited items our edge label is.
		}
	}
	
	$filep = defined($filep) ? $filep : \*STDOUT;
	if(defined($from) and defined($to)) {
		
		my ($edgeAttribString) = ${${$graphPtr}{$from}}{$to};
		my @attribArr = split($delim, $edgeAttribString);
		
		my $theEdgeLabel = defined($indexOfEdgeLabel) ?
				$attribArr[$indexOfEdgeLabel] 
				: undef;
		
		#print STDERR ("Attr: " . $edgeAttribString . "\n" );
	
		if (defined($theEdgeLabel) && length($theEdgeLabel) > 0) {
			print $filep "\t\t<VEdge from=\"$from\" to=\"$to\" elabel=\"$theEdgeLabel\" la=\"T\"/>\n";
		} else {
			print $filep "\t\t<VEdge from=\"$from\" to=\"$to\"/>\n";
		}
   }
}

sub convertEdgeColors2Methods
{
	my ($graph, $clr2mtd, $def_edge_color) = @_;
	
	foreach my $firstNode (keys(%{$graph}))
	{
		my $neighbors = $$graph{$firstNode};
		foreach my $secondNode (keys(%{$neighbors}))
		{
			my $color = $$neighbors{$secondNode}; # a color like "red" maybe
			my $method;
			if(defined($clr2mtd) and exists($$clr2mtd{$color}))
			{ # if it's a color NAME, like "red" or "blue"
				$method = $$clr2mtd{$color};
			}
			elsif($color !~ /^M\d+/)
			{ # if it's a NOT already a method number (like M0099), then set it to the default edge color
				$method = $$clr2mtd{$def_edge_color};
			}
			# print STDERR "($firstNode,$secondNode): '$$neighbors{$secondNode}' -> '$method' (color was '$color')\n";
			$GLOBAL_edge_method_assignment{$firstNode . $delim . $secondNode} = $method;
			#$$neighbors{$secondNode} = $color; # <--  Alex: this was a bug, I think. it overwrites any other edge attributes!
		}
	}
}

sub getMinMaxAttrib
{
	my ($attribs, $nodes, $attrib) = @_;
	
	my $max = undef;
	my $min = undef;
	
	foreach my $node (keys(%{$nodes}))
	{
		my $node_attribs = $$attribs{$node};
		
		my $value = $$node_attribs{$attrib};
		
		if(not(defined($max)) or (defined($value) and $value > $max))
		{
			$max = $value;
		}
		
		if(not(defined($min)) or (defined($value) and $value < $min))
		{
			$min = $value;
		}
	}
	
	return ($min, $max);
}

sub getGroupColorAttrib
{
	my ($attribs, $nodes) = @_;
	
	my $color = undef;
	
	foreach my $node (keys(%{$nodes}))
	{
		my $node_attribs = $$attribs{$node};
		$color = $$node_attribs{'group_color'};
	}
	
	return ($color);
}

sub printVerbose {
# A debugging-style function to print status messages, if we are running in verbose mode.
	my ($msg) = @_;
	if ($verbose) {
		print STDERR "table2visant.pl: ${msg}\n";
	}
}

sub readListFileIntoHash($) {
# Input: file name to read a return-delimited list from (i.e., one item per line)
# Output: a hash where the items in the file are the keys in the hash (values are all set to 1)
# Reads a list file of the form:
# LINE1_ITEM
# LINE2_ITEM
# LINE3_ITEM
# etc...
# Into a hash where the elements like hash{'LINE1_ITEM'} are set to 1. Elements not appearing in the file remain undefined.
	my ($filename) = @_;
	my %hash = ();
	open(FILE, $filename) or die("Could not open list file '$filename'.");
    
	my $line;
	while($line = <FILE>) {
		chomp($line);
#print STDERR $line . "\n";
		$hash{$line} = 1;
	}
	close(FILE);
	return %hash;
}

__DATA__
syntax: table2visant.pl [OPTIONS] [LINKS | < LINKS] [NODES]

Prints out a VisANT-formatted XML file for the tab-delimited
links contained in LINKS.  If a second file NODES is supplied,
the script reads node attributes from the file.

OPTIONS are:

-q: Quiet mode (default is verbose)

-f1 COL: The first node id in the LINKS file is COL (default 1).

-f2 COL: The second node id in the LINKS file is COL (default 2).

-ec COLOR_COL: Specify where the edge color column is (default is none).

-el EDGE_LABEL_COL: Specify which column contains the label 
	for an edge (default: none).
	This is the text that will show up next to an edge in the XML file.

-d DELIM: Set the field delimiter to DELIM (default is tab).

-dir: Make graph directed (default assumes an undirected graph).

The rest of the options apply only to a NODES file if supplied:

--nodeattribs=FILENAME: Specify a node attribute file.

-f COL: The id for the node is in column COL (default is 1).

-l LABEL_COL: The label for this node can be found in column COL 
    (default none).

-x X_COL: The X-coordinate can be found in column COL (default none).

-y Y_COL: The Y-coordinate can be found in column COL (default none).

-g GROUP_COL: The GROUP_COL contains attributes that group the
	nodes into meta-nodes (default none).

-t TYPE_COL: The type of the node is in column TYPE_COL
	(default none and the type is 100).

-nc NODE_COLOR_COL: The color for this node can be found in
    column COL. This can be an RGB description or a common color name.

-gc GROUP_COLOR_COL: The color for this group can be found in
    column COL. This can be an RGB description or a common color name.

-s SIZE_COL: The SIZE_COL gives the size of the node (default
													  none and all nodes set to 15).

-r: Restrict the network to nodes mentioned in the NODES file.  The
    default behavior is to include all nodes from the LINKS file and
    if they are not mentioned in the NODES file then they are associated
    with default values for all of their attributes.

-nbrs N: Include nodes that connect to N or more nodes 


