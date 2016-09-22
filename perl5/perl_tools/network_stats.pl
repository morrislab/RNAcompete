#!/usr/bin/perl -w

# By Alex Williams, May 2007
# alexgw@soe.ucsc.edu

# This script calculattes properties for a network
# By default, it reads in an edge list
#
#  NODE1   NODE2
#  NODE3   NODE5
#  NODE5   NODE4
# (those are edges... for example, an edge from 1 to 2, 3 to 5, 5 to 4)

use strict;
use Getopt::Long;
use List::Util;

require "$ENV{MYPERLDIR}/lib/libstats.pl"; # Note that this defines "max" and "min" as vector operations! This overloads the ones found in List::Util
require "$ENV{MYPERLDIR}/lib/libset.pl";


sub arrayUnion {
    # From: http://www.unix.org.ua/orelly/perl/cookbook/ch04_09.htm (perl cookbook)
    my ($aPtr, $bPtr) = @_;
    my @a = @$aPtr;
    my @b = @$bPtr;
    my %union = (); # note--same names for hashes and arrays
    my %count = ();
    foreach my $e (@a, @b) { $union{$e}++ }
    my @unionArr = keys %union;
    return @unionArr;
}


my $delimiter = "\t";
my $operation = undef;
my $graphIsDirected = 0; # default: UNDIRECTED

my $sourceNodeIndex = 1; # default. 1 means "first element"
my $destNodeIndex = 2; # default. 2 means "second element"

my $verbose = 0; # print additional information to STDERR if this is set!

my $calcClusterCoeff = 1; # should we calculate the clustering coefficient?

my $floatDecimalPoints = 3;

my $caseSensitive = 1; # default is case-sensitive

my $printHistogramStyleWithoutTallies = 0; # if this is set, then we just print out each "this node had degree of 27" as many times as we have a node with that degree, instead of summing the results. If you set this to 0, it's suitable for making an EXCEL histogram, if you set it to 1 (with rawCounts), it's more suitable for R.

# IMPORTANT: Note that GetOptions CONSUMES @ARGV--you CAN'T use it afterward)!
# More info about GetOptions: http://www.perl.com/doc/manual/html/lib/Getopt/Long.html
#Getopt::Long::Configure(qw(pass_through)); # pass_through: "Don't flag options we don't process as errors"
{
    my $graphShouldBeUndirected = 0;
    my $specifyCaseInsensitive = 0;
    my $specifyYesCaseSensitive = 0;
    GetOptions("help|?|man" => sub { printUsage(); }
	       , "1|sourceNode=i" => \$sourceNodeIndex # Note that this is where "index" means from 1..end, instead of being numbered from 0. 1 is the first element!
	       , "2|destNode=i"   => \$destNodeIndex # note that index starts at 1 and not 0 like programmers expect! 1 is the first element!
	       , "delim|d=s"      => \$delimiter
	       , "dir|directed!"      => \$graphIsDirected
	       , "undir|undirected!"    => \$graphShouldBeUndirected
	       , "cc|cluster_coeff!" => \$calcClusterCoeff
	       , "ins|case_insensitive!" => \$specifyCaseInsensitive
	       , "sens|yes_case_sensitive!" => \$specifyYesCaseSensitive
	       , "v|verbose!"     => \$verbose
	       , "dp|decimal_precision=i"  => \$floatDecimalPoints
	       , "rc|rawCounts!"  => \$printHistogramStyleWithoutTallies
	       ) or printUsage();

    if ($specifyYesCaseSensitive && $specifyCaseInsensitive) {
	die "You specified both case-INsensitive (--ins) and case-SENSITIVE (--sens) at the same time. Pick one or the other!\n";
    } else {
	if ($specifyCaseInsensitive) { $caseSensitive = 0; }
	if ($specifyYesCaseSensitive) { $caseSensitive = 1; }
    }
    

    if ($graphIsDirected && $graphShouldBeUndirected) {
	die "You passed in both the --directed and --undirected options. This is contradictory--you have to pick one of them! A graph can't be both directed AND undirected at the same time.\n";
    } else {
	if ($graphShouldBeUndirected) {
	    $graphIsDirected = 0; # "graph should be undirected"
	}
    }
    
    if ($floatDecimalPoints < 0) {
	die "You can\'t specify fewer than 0 decimal points in the output. You specified $floatDecimalPoints decimal points. Look up the --dp=<INTEGER> option, and choose a value greater than 0. Probably you want it to be at least 3, but it depends on your dataset.";
    }
}

if ($sourceNodeIndex < 1 || $destNodeIndex < 1) {
    die qq{The node index cannot be less than 1. 1 is the minimum index--it means \"the first column in this file\".\n};
}

if ($sourceNodeIndex == $destNodeIndex) {
    die qq{The from-node index and to-node indices CANNOT be the same.\n};
}

#if ($operation == 'u') {
#    my $argStr = join(' ', @ARGV);
#    system("cat $argStr | uniq");
#    exit(0);
#}

my %nodeSet = (); # just a set of all the nodes we've seen so far
my %edges = ();
# "%edges" is a "two-dimensional" hash (a hash of hashes, actually)
# The first hash is the node in question, and all the sub-hashes of this guy
# are the outgoing edges.

my %numOutgoing = (); # number of outgoing edges for the item at the hash key
my %numIncoming = (); # number of incoming edges for the item at the hash key

my $numEdges = 0; # number of edges we read

my $lineNum = 0;

# READ THE EDGES INTO MEMORY HERE
&readGraphFileFromDisk();

my %numNodesWithInCount = (); # number of nodes with this edge count (edge count = key, number of nodes with this many edges = value)
my %numNodesWithOutCount = (); # number of nodes with this edge count (edge count = key, number of nodes with this many edges = value)
my %numNodesWithTotalCount = (); # number of nodes with this edge count (edge count = key, number of nodes with this many edges = value)

$verbose and print STDERR "network_stats.pl is done reading in the input file: Read a total of $lineNum lines.\n";

my $numNodes = scalar(keys(%nodeSet));
print "NUM_NODES:\t" . $numNodes . "\tSUMMARY_STAT" . "\n";
print "NUM_EDGES:\t" . $numEdges . "\tSUMMARY_STAT" . "\n";

my @outgoingEdgeCounts = values(%numOutgoing); # get the number of edges for each node...
my @incomingEdgeCounts = values(%numIncoming); # get the number of edges for each node...
my @totalEdgeCounts = (@outgoingEdgeCounts, @incomingEdgeCounts); # concatenate arrays
my ($totalCount, $avgNodeDegree, $totalSD) = &vec_stats(\@totalEdgeCounts); # vec_stats function is from libstats.pl


if (!defined($avgNodeDegree)) { $avgNodeDegree = 0; }
if (!defined($totalSD)) { $totalSD = 0; }

print "AVG_NODE_DEGREE:\t" . sprintf("%.${floatDecimalPoints}f", $avgNodeDegree) . "\tSUMMARY_STAT" . "\n";
print "STDEV_OF_NODE_DEGREE:\t" . sprintf("%.${floatDecimalPoints}f", $totalSD) . "\tSUMMARY_STAT" . "\n";

if ($graphIsDirected) {
    my ($outgoingCount, $outgoingMean, $outgoingSD) = &vec_stats(\@outgoingEdgeCounts); # vec_stats function is from libstats.pl
    print "OUTGOING_NODE_DEGREE_STDEV:\t" . sprintf("%.${floatDecimalPoints}f", $outgoingSD) . "\tSUMMARY_STAT" . "\n";
    my ($incomingCount, $incomingMean, $incomingSD) = &vec_stats(\@incomingEdgeCounts); # vec_stats function is from libstats.pl
    print "INCOMING_NODE_DEGREE_STDEV:\t" . sprintf("%.${floatDecimalPoints}f", $incomingSD) . "\tSUMMARY_STAT" . "\n";

}



if ($calcClusterCoeff) {
    my %clusterCoefficients = calculateClusteringCoefficients(\%nodeSet, \%edges);
    my @ccArray = values(%clusterCoefficients);
    #print(join(',', @ccArray)); print "\n";
    my ($ccCount, $ccMean, $ccSD) = &vec_stats(\@ccArray);
    print STDOUT "MEAN_CLUSTERING_COEFFICIENT:\t" . sprintf("%.${floatDecimalPoints}f", $ccMean) . "\tSUMMARY_STAT" . "\n";
    print STDOUT "STDEV_OF_CLUSTERING_COEFFICIENT:\t" . sprintf("%.${floatDecimalPoints}f", $ccSD) . "\tSUMMARY_STAT" . "\n";
}

if ($printHistogramStyleWithoutTallies) {
    # Print data for each item, not a summary
    if ($graphIsDirected) {
	print STDOUT "NODE	OUTGOING_DEGREE\n";
	&printHash(\%numOutgoing, *STDOUT, "NODE_OUTGOING_DEGREE"); # <-- note, we use printHash, because we do NOT want to sort things here. i.e., don't use printNodeDegreeData
	print STDOUT "NODE	INCOMING_DEGREE\n";
	&printHash(\%numIncoming, *STDOUT, "NODE_INCOMING_DEGREE"); # don't use printNodeDegreeData!
    }
    print STDOUT "NODE	OVERALL_DEGREE\n";
    foreach my $k (sort( (keys(%numIncoming), keys(%numOutgoing) ) )) {
	my $in = (exists($numIncoming{$k}) && defined($numIncoming{$k})) ? $numIncoming{$k} : 0;
	my $out = (exists($numOutgoing{$k}) && defined($numOutgoing{$k})) ? $numOutgoing{$k} : 0;
 	print STDOUT ($k . "\t" . ($in+$out) . "\t" . "NODE_OVERALL_DEGREE" . "\n");
    }
    print STDOUT "\n";
    
} else {
    &printTalliesForDegreeData();
}


die "If the graph is UNDIRECTED, the we must have 0 incoming nodes (we count everything as outgoing). In this case, we had: " . scalar(keys(%numIncoming)) . " incoming nodes, however. Find this bug!\n" if (!$graphIsDirected && (scalar(keys(%numIncoming)) > 0));


exit(0);







sub printUsage {
    print STDOUT <DATA>;
    exit(0);
}

sub printHash {
    my ($hashPtr, $printToWhere, $suffix) = @_;
    my %hash = %{$hashPtr};
    foreach my $k (sort(keys(%hash))) {
 	print $printToWhere ($k . "\t" . $hash{$k} . "\t" . $suffix . "\n");
    }
}

sub printNodeDegreeData { # prints the individual data for each node
    my ($hashPtr, $printToWhere, $suffix) = @_;
    foreach my $node (sort { $a <=> $b } keys(%$hashPtr)) {
	print $printToWhere ($node . "\t" . $$hashPtr{$node} . "\t" . $suffix . "\n");
    }
}


sub readGraphFileFromDisk {
    # operates on global variables...
    while (my $line = <STDIN>) {
	$lineNum++;
	chomp($line);

	if (!$caseSensitive) {
	    $line = uc($line); # make everything upper-case if we're being case-insensitive
	}

	my (@edgeLine) = split(/$delimiter/, $line);

	next if (scalar(@edgeLine) == 0); # skip blank lines...

	if (scalar(@edgeLine) < List::Util::min($sourceNodeIndex, $destNodeIndex) ) {
	    # W need to at least get one edge...
	    die qq{Error in input to network_stats.pl: On line $lineNum, we found fewer columns than expected! The line was this: \"$line\".\n};
	}

	my $firstVertex  = undef;
	if ((($sourceNodeIndex-1) < scalar(@edgeLine))
	    && (length($edgeLine[$sourceNodeIndex - 1]) > 0) ) {
	    $firstVertex = $edgeLine[$sourceNodeIndex - 1];
	    # note that the index begins at *1*, but the ARRAY index begins at 0. Hence, we subtract one from each index.
	    # Also note that we don't want to have an edge with name '' (that should actually indicate a blank edge,
	    # or rather a non-connected vertex, so we check for the length of this element, and make sure it's > 0.
	}

	my $secondVertex = undef;
	if ((($destNodeIndex-1) < scalar(@edgeLine))
	    && (length($edgeLine[$destNodeIndex - 1]) > 0) ) {
	    $secondVertex = $edgeLine[$destNodeIndex - 1]; # see the comments for $firstVertex above
	}
	
	foreach my $vert ($firstVertex, $secondVertex) {
	    # Initialize stuff...
	    if (defined($vert)) {
		$nodeSet{$vert}  = 1;
		if (!defined($edges{$vert})) { %{$edges{$vert}} = (); } # no edges yet...
		if (!defined($numOutgoing{$vert})) {  $numOutgoing{$vert} = 0;  }
		if ($graphIsDirected && !defined($numIncoming{$vert})) {  $numIncoming{$vert} = 0;  }
	    }
	}

	if (defined($firstVertex) && defined($secondVertex)) {
	    # There are TWO vertices, and hence an edge as well.
	    if ($graphIsDirected) {
		# Add a directed edge
		$edges{$firstVertex}{$secondVertex} = 1;
		$numOutgoing{$firstVertex}++;
		$numIncoming{$secondVertex}++;
	    } else {
		# If the graph isn't directed, then we want to add the edges OUTGOING both ways,
		$edges{$firstVertex}{$secondVertex} = $edges{$secondVertex}{$firstVertex} = 1; # add this edge both ways...
		$numOutgoing{$firstVertex}++; # we only use the OUTGOING edges for undirected graphs
		$numOutgoing{$secondVertex}++; # we only use the OUTGOING edges for undirected graphs
	    }
	    $numEdges++;
	} else {
	    # Only one of the two vertices we defined--thus, we have read in
	    # a vertex with (perhaps) no edges at all. This is the way you define
	    # a vertex that is not connected at all... just the name, and leave the rest blank.
	    # Thus, do NOT increment $numEdges
	}
#    print STDERR "LINE $lineNum:\t$line" . "\n";
    }


}



sub printTalliesForDegreeData {
    foreach my $node (keys(%nodeSet)) {
	#print "$node\n";
	
	my $nOut   = (defined($numOutgoing{$node})) ? $numOutgoing{$node} : 0;
	my $nIn = 0;  # if it isn't directed, then we just count all edges as being outgoing edges (hence, $nIn = 0;)
	if ($graphIsDirected && defined($numIncoming{$node})) {
	    $nIn = $numIncoming{$node};
	}
	my $nTotal = $nOut + $nIn;
	
	if (!defined($numNodesWithOutCount{$nOut}))  { $numNodesWithOutCount{$nOut} = 0; }
	if (!defined($numNodesWithInCount{$nIn}))   { $numNodesWithInCount{$nIn} = 0; }
	if (!defined($numNodesWithTotalCount{$nTotal})) { $numNodesWithTotalCount{$nTotal} = 0; }
	
	$numNodesWithOutCount{$nOut}++;
	$numNodesWithInCount{$nIn}++;
	$numNodesWithTotalCount{$nTotal}++;
    }

    if ($graphIsDirected) {
	print STDOUT "NUM_OUTGOING_EDGES	COUNT_OF_NODES_WITH_THIS_MANY_OUTGOING_DIRECTED_EDGES\n";
	printNodeDegreeData(\%numNodesWithOutCount, *STDOUT, "OUTGOING_DIRECTED_DEGREE");
	print STDOUT "NUM_INCOMING_EDGES	COUNT_OF_NODES_WITH_THIS_MANY_INCOMING_DIRECTED_EDGES\n";
	printNodeDegreeData(\%numNodesWithInCount, *STDOUT, "INCOMING_DIRECTED_DEGREE");
    }

    print STDOUT "NUM_EDGES	COUNT_OF_NODES_WITH_THIS_MANY_OUTGOING_PLUS_INCOMING_EDGES_TOTAL\n";
    printNodeDegreeData(\%numNodesWithTotalCount, *STDOUT, "TOTAL_DEGREE");
    print STDOUT "\n";
}

sub calculateClusteringCoefficients {
    # http://en.wikipedia.org/wiki/Clustering_Coefficient
    # Returns a hash with key = name of vertex and value = clustering coefficient of that vertex.
    # Works for both directed and undirected graphs

    my ($nodeSetPointer, $edgesPtr) = @_;
    my %ns = %$nodeSetPointer;
    my %es = %$edgesPtr;
    
    my %clusterCoefficients = ();
    
    foreach my $v (keys(%ns)) { # for each node...
	#print "$v\n";
	my %neighborsOfV = &getNeighborhood($v, $nodeSetPointer, $edgesPtr);

	my $countOfWithinNeighborhoodEdges = 0;

	foreach my $n (keys(%neighborsOfV)) { # check each neighbor...
	    # See how many neighbor-neighbor edges there are for this particular neighbor...
	    foreach my $neighborOfNeighbor (keys(%{$es{$n}})) {
		if (exists($neighborsOfV{$neighborOfNeighbor}) && defined($neighborsOfV{$neighborOfNeighbor})) {
		    $countOfWithinNeighborhoodEdges++;
		} else {
		    # This neighbor-of-(a-neighbor-of-v) wasn't also a first-degree neighbor of v
		}
		# Note! For undirected graphs, this actually double-counts each edge. But I believe that is intentional!
		# Check the wiki page!
	    }
	}
	
	# Ok, now we have the edge count (this is |e_jk| on the wiki page)
	# (note that we do NOT have to multiply by two for undirected graphs, because we ALREADY double-count
	# in the neighbor-neighbor counting procedure (each edge is listed TWICE, rather than just once, in an undirected graph)
	
	# k_i is the degree of node i. In this case, it's just scalar(keys(%neighborsOfV)).
	my $degreeOfV = scalar(keys(%neighborsOfV)); # this is the "outgoing only" degree
	
	my $clusterCoeffForV = ($degreeOfV >= 2)
	    ? $countOfWithinNeighborhoodEdges / ($degreeOfV*($degreeOfV-1))
	    : 0; # the cluster coefficient is 0 if there are only one or zero neighbors
	$clusterCoefficients{$v} = $clusterCoeffForV;
    }
    
    return %clusterCoefficients;
}


sub getNeighborhood {
    # All the vertices that are pointed to by edges from this vertex (first-degree neighbors)
    # In other words, every vertex that you can get to by following one edge from $theVerte. Maybe include itself, I guess, if there are self-links?
    # Returns a SET of neighbors. (A hash.) Note that if there are self-links, this very node can appear again. But no node can appear more than once, since it's a proper mathematical set.
    my ($theVertex, $nodeSetPointer, $edgesPtr) = @_;
    my %ns = %$nodeSetPointer;
    my %es = %$edgesPtr;
    my %neighbors = ();
    
    if (!exists($es{$theVertex}) || !defined($es{$theVertex})) {
	# The vertex doesn't even exist in the edge set, so it has no neighbors
	die "Error, trying to get a non-existent vertex $theVertex in getNeighborhood.";
    }
    
    foreach my $singleNeighbor (keys( %{$es{$theVertex}} )) {
	$neighbors{$singleNeighbor} = 1;
    }
    return %neighbors;
}




__DATA__
Description:
    network_stats.pl
    This programs calculates properties of interest for a network.

Syntax: network_stats.pl (--directedd or --undirected) [OPTIONS] < [EDGES]

    The [EDGES] should be given as tab-delimited pairs: VERTEX1 <tab> VERTEX2
    means there is a directed edge from VERTEX1->VERTEX2. Note, however
    that *un*directed is the default.

    If we find an "edge" with just one value, i.e. only VERTEX1 or VERTEX2, but
    not both, then we add that node to the graph. This is how you add nodes
    that do nothave any edges at all.

Example usage:

    cat MY_EDGE_FILE | network_stats.pl -1=4 -2=5 -d=','

       This reads edges from columns 4 and 5 in MY_EDGE_FILE,
       and specifies that it is a comma-delimited file. Note:
       UNDIRECTED edges are the default.

    network_stats.pl --directed -1=2 -2=3 < MY_EDGES_DIRECTED

       This reads DIRECTED edges from columns 2 (source) and 3 (dest)
       from the MY_EDGES_DIRECTED file.

Options:
    -1 = <COLUMN_INDEX>  (default value: 1)  (Specify SOURCE node of edges)
    or --sourceNode = <COLUMN_INDEX>
    (Note that this is the number 1, not a lower-case L.)
    
    Specifies the column in [EDGES] with the OUTGOING edges.
    The edge comes *FROM* this node. (Source node of the edge.)
    Note that in an undirected graph, it does not matter which node
    is the source and which is the destination (they are interchangeable).
    The default is -1=1, meaning the first column of data in the file has
    the sources of the edges.

    -2 = <COLUMN_INDEX>  (default value: 2) (Specify DESTINATION node of edges)
    or --destNode = <COLUMN_INDEX>
    Specifies the column in [EDGES] with the INCOMING edges.
    The edge goes *TO* this node. (Destination node of the edge.)
    The default is -2=2 meaning the second column in the file has the
    destinations of the edges.

    TO BE ADDED: -w = <COLUMN_INDEX> (default value: NONE)
    TO BE ADDED: or --edgeWeight = <COLUMN_INDEX>
    TO BE ADDED: Specify which column contains the edge weights.
    TO BE ADDED:  Currently NOT IMPLEMENTED YET. So do not use it!

    -d or    (default is a tab)
    --delim = <DELIMITER>
    Specifies the delimiter between columns in the EDGES file.

    --dp=<INTEGER> or --decimal_precision=<INTEGER>
    Specifies how many decimal places you want for the floating-point output.
    Default is 3.

    --undirected or --undir (default)
    Interpret the [EDGES] file as UNDIRECTED edges--that is, the
    source/destination of each edge is interchangeable.

    --directed or --dir
    Interpret the [EDGES] file as being DIRECTED edges.
    Default is *undirected.*

    --sens or --yes_case_sensitive (DEFAULT)
      Count "vertex_a" and "VERTEX_A" as two different vertices.

    --ins or --case_insensitive
      Count "vertex_a" and "VERTEX_A" as synonyms (otherwise they are distinct)

    --cc or --cluster_coeff
      Disable with --nocc or --nocluster_coeff
    Also calculate the clustering coefficient (slightly slow)
    Basically, the clustering coefficient means:
      Take a vertex "v": now look at all its first neighbors
      Now for each neighbor, see how many of ITS first neighbors are also first
      neighbors of v. That is the total number of neighbor-neighbor connections.
      Divide that by the total possible connections (degree_of_v * (deg_of_v - 1)),
      and you have the clustering coefficient. Note that it works for both
      directed AND undirected graphs.
    http://en.wikipedia.org/wiki/Clustering_Coefficient

    --rc or --rawCounts
    Print the RAW counts of each node\'s degree, instead of summing
    them up and reporting the total. This is useful if you want to
    plot the degree of nodes in R (http://www.r-project.org/).
    Here\'s how you plot it, assuming the degree of each node is in
    the second column of this program\'s output:
    On the command line:
       network_stats.pl < YOUR_EDGES > /path/to/your/file
    And in R:
       x = read.table("/path/to/your/file");
       hist(x[,2])
    That will plot a histogram of the data in the second column.

    -v or --verbose
    Print more information to the screen. Should print to STDERR instead of STDOUT.


Note: "Node" and "Vertex" are synonyms.

Revision History:

    June 2007: Added "--rawCounts" switch for handy histogram export to R. See above
    for instructions and exact commands to use.

    May 24, 2007: First version (Alex Williams)


Things that would be nice to add:

Betweenness:
  http://en.wikipedia.org/wiki/Betweenness

Graph eccentricity / diameter / radius:
    http://mathworld.wolfram.com/GraphEccentricity.html
    http://en.wikipedia.org/wiki/Eccentricity_(graph_theory)

