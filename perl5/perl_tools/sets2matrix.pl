#!/usr/bin/perl

##############################################################################
##############################################################################
##
## cluster2matrix.pl
##
##############################################################################
##############################################################################
##
## Written by Josh Stuart in the lab of Stuart Kim, Stanford University.
## jstuart@stanford.edu
##
## Postal address: Department of Developmental Biology, B314
##                 279 Campus Dr.
##                 Stanford, CA 94305
##
## Web site: http://www.smi.stanford.edu/people/stuart
##
##############################################################################
##############################################################################
##
## Written: 12/24/01
## Updated: 12/28/01
##
##############################################################################
##############################################################################

use strict;

require "libfile.pl";

# Given one directory.  Assumes each has a list of files where each
# file contains a list of genes belonging to a single cluster (or layer).
#
my($arg);
my($outfile) = '';
my($source)="";
my($dir)='';
my(@files);
my(@counts);
my($col) = 0;
my($id) = 0;
my($id_offset) = 0;
my($short)=1;
my($group);
my($total_set_file) = "";
my($total_set_col) = -1;
my($keep_total_set) = '';
my(@tmp);
my($N,$m,$P);
my($item,$index);
my(%itemindices);
my(@itemnames);
my(%groups,%count_items,%score,@count_groups);
my($line,$score_col,$score,$loops,$passify);
my(@clusternames);
my($uppercase)=0;
my($valueCol)=0;
my(@values);
my($regexp)='';
my(@regexp);
my($beautify)=0;
my($force)=0;
my($verbose)=1;
my $synfile='';
my $delim = "\t";

while(@ARGV)
  {
    $arg = shift @ARGV;

    if($arg eq '--help')
    {
      &printSyntax();
      exit(0);
    }
    elsif($arg eq "-v")
    {
      $arg = shift @ARGV;
      $verbose = ($arg eq 'off') ? 0 : 1;
    }
    elsif($arg eq "-s")
      {
        $short = 1;
      }
    elsif($arg eq "-c")
      {
        $col = shift @ARGV;
      }
    elsif($arg eq "-i")
      { 
        $id = 1;
        $id_offset = int(shift @ARGV);
      }
    elsif($arg eq "-f")
      { 
        $force = 1;
      }
    elsif($arg eq '-syn')
    {
      $synfile = shift @ARGV;
    }
    elsif($arg eq '-d')
    {
      $delim = shift @ARGV;
    }
    elsif($arg eq "-t")
      {
        $arg = shift @ARGV;
	@tmp = split('=',$arg);
	$total_set_file = $tmp[0];
	if($#tmp>0)
	  { $total_set_col = $tmp[1]-1; }
	else
	  { $total_set_col = 0; }
      }
    elsif($arg eq '-k')
      {
        $keep_total_set = shift @ARGV;
      }
    elsif($arg eq '-u')
      {
        $uppercase=1;
      }
    elsif($arg eq '-n')
      {
        $valueCol = int(shift @ARGV);
      }
    elsif($arg eq '-r')
      {
        $regexp = shift @ARGV;
	@regexp = split('/',$regexp);
      }
    elsif($arg eq '-b')
      { $beautify = 1; }

    else
      {
        push(@files,$arg);
      }
  }

$valueCol--;

$col = ($col==0) ? 0 : ($col-1);

# Process the synonyms file if it exists.
my %syns;
my @syns;
my $syn;
my $s;
my @new_syns;
my $syn_rep;
if(length($synfile)>0)
{
  if(not(open(FILE,$synfile)))
  {
    print STDERR "Could not open synonyms file $synfile, skipping.\n";
  }
  else
  {
    print STDERR "Reading synonyms from $synfile...";
    while(<FILE>)
    {
      if(/\S/ and not(/^\s*#/))
      {
	chop;
        @tmp = split($delim);
	@new_syns=();
	$syn_rep='';
	for($s=0; $s<=$#tmp; $s++)
	{
	  if(exists($syns{$tmp[$s]}))
	  {
	    if(length($syn_rep)<1)
	    {
	      $syn_rep = $syns{$tmp[$s]};
	    }
	  }
	  else
	  {
	    push(@new_syns, $tmp[$s]);
	  }
	}
	# If all the synonyms have not been seen before, create a new
	# representative for these synonyms (choose the first one seen).
	if(length($syn_rep)<1)
	{
	  $syn_rep = $new_syns[0];

	  if($beautify)
	    { $syn_rep = &beautify($syn_rep); }
	  if($uppercase)
	    { $syn_rep =~ tr/a-z/A-Z/; }
	  $syn_rep = &clean($syn_rep,$regexp,@regexp);
	}

	# Point these synonyms to the correct representative.
	foreach $syn (@new_syns)
	{
	  if($beautify)
	    { $syn = &beautify($syn); }
	  if($uppercase)
	    { $syn =~ tr/a-z/A-Z/; }
	  $syn = &clean($syn,$regexp,@regexp);
	  $syns{$syn} = $syn_rep;
	}
      }
    }
    close(FILE);
    print STDERR " done.\n";
  }
}

$N=0;
if(length($total_set_file)>0)
  {
    open(FILE, $total_set_file) or die("Could not open total set file -->$total_set_file<-- for clustering.\n");
    print STDERR "Reading entire set of items used for the clustering from $total_set_file...";
    while(<FILE>)
      {
	chop;
	@tmp = split($delim,$_);
	$item = $tmp[$total_set_col];
	if($beautify)
	  { $item = &beautify($item); }
	if($uppercase)
	  { $item =~ tr/a-z/A-Z/; }
	$item = &clean($item,$regexp,@regexp);

	# See if a synonym exists for this entry.  If it does, replace
	# the entry with its representative.
	if(exists($syns{$item}))
	{
	  $item = $syns{$item};
	}

	if(length($item)>0 and not($itemindices{$item}))
	  { 
	    $N++; 
	    $itemindices{$item} = $N;
	    $itemnames[$N] = $item;
	  }
      }
    close(FILE);
    print STDERR " done ($N item(s) found).\n";
  }

my($path, $file, @tmp);
my(@ids);
my($f)=0;
my(@orders)=();
my $short_name = '';
foreach $file (@files)
{
    # Get the next file
    $path = $file;
    $short_name = &getPathSuffix($file);
    $short_name = &remPathExt($short_name);
    # Extract an id from the file name if instructed to do so:
    if($id)
      {
        if($file =~ /(\d+)\D*$/)
	  { 
	    $ids[$f] = int($1) + $id_offset; 
	    $orders[$ids[$f]] = $f;
	  }
        else
	  {
	    print STDERR "Could not extract an ID from file $file, quitting.\n";
	    exit(2);
	  }
      }
    # Otherwise the id corresponds to the discovery index.
    else
      { 
        $ids[$f] = $f+1; 
	$orders[$f] = $f;
      }

    print STDERR "Reading file($f, index=$ids[$f]) $path...";
    if(not(open(PATH,$path)))
      {
        print STDERR "Could not open the file, $path \n";
	exit(3);
      }
    # Grab all the items from this file
    $line=0;
    # Get all the items from this file (one item per line at the specified
    # column):
    while(<PATH>)
      {
	$line++;
	# If the line is non-empty and does not start with a comment character:
        if(/\S/ and not(/^\s+#/))
          {
	    chop;
	    @tmp = split($delim,$_);
	    $item = $tmp[$col];

	    if($beautify)
	      { $item = &beautify($item); }
	    if($uppercase)
	      { $item =~ tr/a-z/A-Z/; }
	    $item = &clean($item,$regexp,@regexp);

	    if(length($item)>0)
	      {
	        # See if a synonym exists for this item.  If it does, replace
	        # the entry with its representative.
	        if(exists($syns{$item}))
	        {
	          $item = $syns{$item};
	        }

	        if(not($itemindices{$item}))
	          {
		    if(length($total_set_file)>0 and $verbose)
	              {
		        print STDERR "WARNING: Item -->$item<-- found on ",
		      		"line $line in $path is not in the total set ",
				"file -->$total_set_file<--. ";
		      }

		    # If we're not forcing use of the total set list then
		    # we can add this to the items we've seen.  Otherwise
		    # we can just ignore this item.
		    if(not($force))
		      {
		        $N++;
		        $itemindices{$item} = $N;
		        $itemnames[$N] = $item;
			# print STDERR "Adding item to the total set.\n";
		      }
	          }

		if($itemindices{$item})
		  {
		    $index = $itemindices{$item};
		    $counts[$index][$ids[$f]]++;

		    if($valueCol>=0)
		      {
		        $values[$index][$ids[$f]] = $tmp[$valueCol];
		      }
		  }
	      }
          }
      }
    close(PATH);
    print STDERR " done.\n";
    $clusternames[$ids[$f]] = $short ? $short_name : $path;
    $f++;
  }

$P = $f;

print STDERR "Number of total items in the all sets was $N.\n"; 
print STDERR "Number of sets (files) read was $P\n";

if(length($keep_total_set)>0)
  {
    if(not(open(PATH,">$keep_total_set")))
      {
        print STDERR "Could not open $keep_total_set to write total set to.\n";
      }
    else
      {
        print STDERR "Sorting and saving total set of genes to file $keep_total_set...";
	foreach $item (sort(keys(%itemindices)))
	  {
	    print PATH "$item\n";
	  }
        print STDERR " done.\n";
	close(PATH);
      }
  }

$loops=0;
$passify=100;
my($i,$j,$k);

print "Item";
for($j=1; $j<=$P; $j++)
  {
    print "\t$clusternames[$j]";
  }
print "\n";

# Print out the NxP count matrix:
for($i=1; $i<=$N; $i++)
  {
    print "$itemnames[$i]";
    for($j=1; $j<=$P; $j++)
      {
	if($valueCol<0)
	  {
	    if(not($counts[$i][$j]))
	      { print "\t0"; }
            else
	      { print "\t$counts[$i][$j]"; }
          }
        else
	  {
	    if(not($counts[$i][$j]))
	      { print "\tNaN"; }
            else
	      { print "\t$values[$i][$j]"; }
	  }
      }
    print "\n";
  }

exit(0);

sub getFileNames
  {
    my($path) = shift @_;
    my(@files) = ();
    if(-d $path)
      { 
	if(not(opendir(DIR,$path)))
	{
	  print STDERR "Could not open directory $path, quitting.\n";
	  exit(1);
	}
        @files = readdir(DIR);
	shift @files; # get rid of the '.' directory
	shift @files; # get rid of the '..' directory
	close(DIR);
      }
    elsif(-f $path)
      { @files = ($path); }

    print STDERR "[", join(',',@files), "]\n";
    return @files;
  }

sub beautify
  {
    my($a) = shift @_;
    $a =~ s/^\s+//;	# Remove leading spaces
    $a =~ s/\s+$//;	# Remove trailing spaces
    $a =~ s/\s\s+/ /g;	# Convert consecutive spaces into one underscore
    $a =~ s/"//g;	# Remove double quotes
    $a =~ s/'//g;	# Remove single quotes
    # $a =~ s/[,;#-!+$%@^&*()]/_/g;	# Convert punctuation to underscores
    $a =~ s/\(//g;	# Remove left parens
    $a =~ s/\)//g;	# Remove right parens
    $a =~ s/\[//g;	# Remove left brace
    $a =~ s/\]//g;	# Remove right brace
    $a =~ s/[;,#]/_/g;	# Remove punctuation
    $a =~ s/\s/_/g;	# Convert a space into an underscore (again?!)
    $a =~ s/[_]+/_/g;	# Turn consecutive underscores into one.
    
    return $a;
  }

sub get_path_suffix
  {
    my($path) = shift @_;
    while($path =~ /\/$/)
      { chop($path); }
    if($path =~ /([^\/]+)$/)
      { $path = $1; }
    return $path;
  }

sub by2nditem
  {
    my(@list_a) = @$a;
    my(@list_b) = @$b;
    return ($list_b[1]-$list_a[1]);
  }

sub permute
  {
    my(@original) = @_;
    my(@permuted) = ();
    my($element);
    my($last);

    while(@original)
      {
        $last = $#original;
        ($element) = splice(@original, int(($last+1)*rand()), 1);
	unshift(@permuted,$element);
      }
    return (@permuted);
  }

sub clean
  {
    my $item = shift @_;
    my $regexp = shift @_;
    my @regexp = @_;
    if(length($regexp)>0 and $regexp[0] eq 's')
      { 
        if(length($regexp[3])<1)
          { $item =~ s/$regexp[1]/$regexp[2]/; }
        elsif($regexp[3] eq 'g')
          { $item =~ s/$regexp[1]/$regexp[2]/g; }
        elsif($regexp[3] eq 'e')
          { $item =~ s/$regexp[1]/$regexp[2]/e; }
        elsif($regexp[3] eq 'ge' or $regexp[3] eq 'eg')
          { $item =~ s/$regexp[1]/$regexp[2]/ge; }
      }
    return $item;
  }


sub printSyntax
{
    print STDERR "syntax: cluster2matrix.pl [OPTIONS] DIR\n",
		"\twhere DIR is a directory containing a file for\n",
		"\teach cluster.",
    		"\tAnd where OPTIONS are:\n",
		"\t  -v [on|off]:\tTurn verbosity on or off (default is on)\n",
		"\t  -s:\tReport short group names w/o attached paths\n",
		"\t  -c n:\tSpecify which column contains the item's label (default is 1)\n",
		"\t  -n n:\t\"numbers\": Report real-valued numbers from column n instead of [0,1] inclusion matrix\n",
		"\t  -i offset:\tExtract an index from the clustering's file names (will grab the first numbers encountered from the file name. Will add offset to the id extracted\n",
		"\t  -b\t\"beautify\": Normalizes the key names (white-space turned into \'_\', leading trailing whitespace removed, etc).\n",
		"\t  -u\t\"upper\": Makes all names upper-case so matches case-insensitively\n",
		"\t  -f\t\"force\": Use with -t option: force membership of resulting list to belong to total set (i.e. ignore any outside the total set).\n",
		"\t  -r REGEX\tApplies the regular expression to each item before using as a key (use for cleaning).\n",
		"\t  -d DELIM\tSet the delimiter to DELIM\n",
		"\t  -syn SYNFILE\tSpecify a synonyms file\n",
		"\t  -k FILE:\tKeep the resulting total set of items\n",
		"\t  -t FILE=n:\tSpecifies that the entire set of items seen by the clustering can be found in column n of the file FILE.  Default is to assume the union of all clusters is the entire set (i.e. exhaustive)\n";
}
