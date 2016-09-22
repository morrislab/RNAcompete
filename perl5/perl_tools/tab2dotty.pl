#!/usr/bin/perl

require "$ENV{MYPERLDIR}/lib/libattrib.pl";

use lib "$ENV{MYPERLDIR}/xlib"; # <-- this is where GraphViz.pm is found

use strict;
use GraphViz;

my $key1;
my $key2;
my @info;

my $arg;
my $verbose      = 1;
my $delim        = "\t";
my $headers      = 0;
my $print_format = 'dot';

# Global graph attributes
my $merge        = 0;
my $random_start = 0;
my $width        = 8;
my $height       = 10.5;
my $pagewidth    = 8.5;
my $pageheight   = 11.0;
my $bifurcate    = 0;
my $weight_col   = 0;
my $weight_mul   = 1; # multiplier
my $elab_col     = 0; # Column containing label for edges.
my $elab_mul     = 1;

my $col1         = 1;
my $col2         = 2;
my $color1       = 'yellow';
my $color2       = 'yellow';
my $style1       = 'filled';
my $style2       = 'filled';
my $cluster1     = '1';
my $cluster2     = '1';
my $rank1        = '';
my $rank2        = '';

my %clusters;
my %colors;
my %styles;
my %ranks;
my %urls;
my $descriptions;
my $dir               = 0;
my $fontsize          = 18;
my $weight_cutoff     = undef;
my $info_headers      = 1;

my $descriptions_file = undef;
my $desc_key_col      = 1;
my $desc_col          = 2;

while(@ARGV)
{
  $arg = shift @ARGV;
  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
  elsif($arg eq '-q')
  {
    $verbose = 0;
  }
  elsif($arg eq '-d')
  {
    $delim = shift @ARGV;
  }
  elsif($arg eq '-k1')
  {
    $col1 = int(shift @ARGV);
  }
  elsif($arg eq '-k2')
  {
    $col2 = int(shift @ARGV);
  }
  elsif($arg eq '-c1')
  {
    $color1 = int(shift @ARGV);
  }
  elsif($arg eq '-c2')
  {
    $color2 = int(shift @ARGV);
  }
  elsif($arg eq '-h')
  {
    $headers = int(shift @ARGV);
  }
  elsif($arg eq '-e')
  {
    $elab_col = int(shift @ARGV);
  }
  elsif($arg eq '-ew')
  {
    $elab_col = -1;
  }
  elsif($arg eq '-em')
  {
    $elab_mul = int(shift @ARGV);
  }
  elsif($arg eq '-w')
  {
    $weight_col = int(shift(@ARGV));
  }
  elsif($arg eq '-wc')
  {
    $weight_cutoff = shift @ARGV;
  }
  elsif($arg eq '-wm')
  {
    $weight_mul = shift @ARGV;
  }
  elsif($arg eq '-bi')
  {
    $bifurcate = 1;
    $color2 = 'gray';
    # $style2 = 'solid';
    $cluster2 = '2';
  }
  elsif($arg eq '-fs')
  {
    $fontsize = int(shift @ARGV);
  }
  elsif($arg eq '-m')
  {
    $merge = 1;
  }
  elsif($arg eq '-r')
  {
    $random_start = 1;
  }
  elsif($arg eq '-o')
  {
    $print_format = shift @ARGV;
  }
  elsif($arg eq '-desc')
  {
     $descriptions_file = shift @ARGV;
  }
  elsif($arg eq '-desci')
  {
     $desc_col = int(shift @ARGV);
  }
  elsif($arg eq '-desck')
  {
     $desc_key_col = int(shift @ARGV);
  }
  elsif($arg eq '-dir')
  {
    $dir = 1;
  }
  elsif($arg eq '-n')
  {
    $arg = shift @ARGV;
    if(not(-f $arg) | not(open(FILE,$arg)))
    {
      print STDERR "Could not open file $arg for reading.\n";
      exit(1);
    }
    my $node;
    my $node_col=undef;
    my $color_col=-1;
    my $cluster_col=-1;
    my $style_col=-1;
    my $rank_col=-1;
    my $url_col=-1;
    my $line=0;
    my @tuple;
    while(<FILE>)
    {
      if(/\S/ and not(/^\s*#/))
      {
        $line++;
        chop;
        s/\s+$//;
        @tuple = split($delim);
        chomp($tuple[$#tuple]);
        if($line <= $info_headers)
        {
          for(my $t=0; $t<=$#tuple; $t++)
          {
            if($tuple[$t] =~ /node/i)
              { $node_col = $t; }
            elsif($tuple[$t] =~ /color/i)
              { $color_col = $t; }
            elsif($tuple[$t] =~ /cluster/i)
              { $cluster_col = $t; }
            elsif($tuple[$t] =~ /style/i)
              { $style_col = $t; }
            elsif($tuple[$t] =~ /rank/i)
              { $rank_col = $t; }
            elsif($tuple[$t] =~ /url/i)
              { $url_col = $t; }
          }
        }
        else
        {
          if(not(defined($node_col)))
            { $node_col = 0; }
          if($node_col>=0)
          {
            $node = $tuple[$node_col];
            if($color_col>=0)
              { $colors{$node} = $tuple[$color_col]; }
            if($cluster_col>=0)
              { $clusters{$node} = $tuple[$cluster_col]; }
            if($style_col>=0)
              { $styles{$node} = $tuple[$style_col]; }
            if($rank_col>=0)
              { $ranks{$node} = $tuple[$rank_col]; }
            if($url_col>=0)
              { $urls{$node} = $tuple[$url_col]; }
          }
        }
      }
    }
  }
  else
  {
    print STDERR "Bad argument [$arg] given, try --help for help\n";
    exit(1);
  }
}
$weight_col--;
$elab_col--;

my $g = GraphViz->new(
                        directed => 0,
                        random_start => $random_start,
                        concentrate => $merge,
                         # width => $width,
                         # height => $height,
                        node => {fontsize => $fontsize}
                         # pagewidth => $pagewidth,
                         # pageheight => $pageheight
                      );

$col1--;
$col2--;

# Read in descriptions if they were supplied
$desc_key_col--;
$desc_col--;
if(defined($descriptions_file))
{
  $descriptions = &attribRead($descriptions_file, "\t", $desc_key_col, $desc_col);

  foreach my $node (keys(%{$descriptions}))
  {
     my $desc = $$descriptions{$node};
     $$descriptions{$node} = &cleanDescription($desc);
  }
}

my @tuple;
my $line=0;
my $data_line=0;
my %seen;
my %seen1;
my %seen2;
my $num_nodes=0;
my $color;
my $style;
my $cluster;
my $rank;
my $url;
my $weight;
my $elab;
while(<STDIN>)
{
  $line++;
  if(/\S/ and not(/^\s*#/))
  {
    $data_line++;
    if($data_line>$headers)
    {
      @tuple = split($delim);
      chomp($tuple[$#tuple]);
      $key1 = $tuple[$col1];
      $key2 = $tuple[$col2];
      my $node1 = $key1 . (exists($$descriptions{$key1}) ? " $$descriptions{$key1}" : "");
      my $node2 = $key2 . (exists($$descriptions{$key2}) ? " $$descriptions{$key2}" : "");
      # print STDERR "[$node1] [$node2]\n";
      $weight = $weight_col>=0 ? $tuple[$weight_col]*$weight_mul : undef;
# print STDERR "[$elab_mul] [$elab_col] [$tuple[$elab_col]]\n";
      my $eval = $elab_col>=0 ? 
                      ($elab_mul<=0 ? $tuple[$elab_col] :
                        int($tuple[$elab_col]*$elab_mul)) :
                      ($elab_col==-2 ? $weight : '');

      $elab = $elab_col>=0 ? $tuple[$elab_col] : '';

      if(not(exists($seen1{$key1})))
      {
        $num_nodes++;
        $color = exists($colors{$key1}) ? $colors{$key1} : $color1;
        $style = exists($styles{$key1}) ? $styles{$key1} : $style1;
        $cluster = exists($clusters{$key1}) ? $clusters{$key1} : $cluster1;
        $rank = exists($ranks{$key1}) ? $ranks{$key1} : $rank1;
        $url = exists($urls{$key1}) ? $urls{$key1} : '';
        $node1 = &chunk($node1);
        $g->add_node($key1,
                        color => $color,
			label => $node1,
                        style => $style);
                        # url => $url);
                        # cluster => $cluster);
                        # rank => $rank);
        $seen1{$key1} = $num_nodes;
      }
      if(not(exists($seen2{$key2})))
      {
        $num_nodes++;
        $color = exists($colors{$key2}) ? $colors{$key2} : $color2;
        $style = exists($styles{$key2}) ? $styles{$key2} : $style2;
        $cluster = exists($clusters{$key2}) ? $clusters{$key2} : $cluster2;
        $rank = exists($ranks{$key2}) ? $ranks{$key2} : $rank2;
        $url = exists($urls{$key2}) ? $urls{$key2} : '';
        $node2 = &chunk($node2);
        $g->add_node($key2,
                        color => $color,
		        label => $node2,
                        style => $style);
                        # url => $url);
                        # cluster => $cluster);
                        # rank => $seen2{$key2});
        $seen2{$key2} = $num_nodes;
      }
      if(not(exists($seen{$key1,$key2})))
      {
        # print STDERR "'$weight' <=> '$weight_cutoff'\n";
        if(not(defined($weight_cutoff)) or not(defined($weight)) 
           or $weight >= $weight_cutoff)
        {
          # print STDERR ".";
          $g->add_edge($key1 => $key2,
                        weight => $weight,
                        label => $elab,
                        dir => ($dir ? 'forward' : 'none')
                        );
        }
        $seen{$key1,$key2} = 1;
      }
    }
  }
}

if($print_format eq 'dot')
  { print STDOUT $g->as_canon; }
elsif($print_format eq 'ps')
  { print STDOUT $g->as_ps; }
elsif($print_format eq 'gif')
  { print STDOUT $g->as_gif; }
elsif($print_format eq 'jpg')
  { print STDOUT $g->as_jpeg; }
elsif($print_format eq 'imap')
  { print STDOUT $g->as_imap; }
elsif($print_format eq 'txt')
  { print STDOUT $g->as_plain; }

exit(0);

sub chunk
{
  my $name = shift;
  my $chunks;
  my $inc=10;
  for(my $i=0; $i<length($name); $i+=$inc)
  {
    my $len = length($name)-$i;
    $len = $len>$inc ? $inc : $len;
    $chunks .= ($i>0 ? '\n' : '') . substr($name,$i,$len);
  }
  return $chunks;
}

sub cleanDescription
{
   my ($s) = @_;
   $s =~ s/["'\/\\\[\]]//g;
   return $s;
}

__DATA__

syntax: tab2dotty.pl [OPTIONS] < TAB_FILE

Converts binary relationships in the tab-delimited file into
a graph in GraphViz format.

TAB_FILE: any tab-delimited file where the two keys are in the first two
        columns of the file.

OPTIONS are:

        -q: quiet mode (default is verbose)
        -dir: make graph directed (default is undirected)
        -d DELIM: change the delimiter to DELIM (default is <tab>)
        -k1 COL: change the column of the first key to COL (deafult is 1)
        -k2 COL: change the column of the second key to COL (default is 2)
        -c1 COLOR: set the color of the first set of nodes to COLOR
        -c2 COLOR: set the color of the second set of nodes to COLOR
        -h HEADER: set the number of header lines to HEADER (default is 0)
        -e COL: specify a column containing edge labels (default none)
        -ew: Use the weight as the label on the edge
        -em MUL: set a weight for the edge display
        -w COL: extract a weight from column COL from the input file for
                edges.
        -wc CUTOFF: use a weight cutoff.  Edges with values greater than
                    or equal to cutoff will be kept.
        -wm MUL: set a weight multiplier.  This value will be multiplied to
                 the weights before setting (default is 1).
        -bi: treat nodes as if come from 2 sets.  nodes listed on the left
             are assumed to belong to set 1 and nodes on the right belong to
             set two.  Nodes in the same set will be colored and filled 
             identically so they can be distinguished in the plot.
        -fs FONTSIZE: set the fontsize to FONTSIZE points (default 10).
        -n FILE: specify a settings file for node attributes.
        -r: Random layout initialization.  This causes the layout program to
                use a random starting point.  Useful if you want to keep trying
                to find sensical looking plots (and the non-random run gives
                a poor layout).
        -m: Merge.  Merge neighboring edges.
        -o FORMAT: specify the output format (default is dot).  Can be:

                dot - dotty readable format (text based)
                ps - postscript format
                gif - GIF format
                jpg - JPEG format
                txt - text format
                imap - prints an HTML image map

	-desc FILE: Supply descriptions for the nodes in FILE.
	
	-desci COL: Set the column for where the node description is in the descriptions
	            file (used with the -desc option).

	-desck COL: Set the column for where the node key is in the descriptions
	            file (used with the -desc option).

