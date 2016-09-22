#!/usr/bin/perl

use strict;

my $fin = \*STDIN;
my @patterns;
my $key_col = 1;
my $alias_col = 2;
my $delim = "\t";
my $identity = 0;
while(@ARGV)
{
  my $arg = shift @ARGV;
  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
  elsif($arg eq '-d')
  {
    $delim = shift @ARGV;
  }
  elsif($arg eq '-key')
  {
    $key_col = int(shift @ARGV);
  }
  elsif($arg eq '-alias')
  {
    $alias_col = int(shift @ARGV);
  }
  elsif($arg eq '-identity')
  {
    $identity = 1;
  }
  elsif(-f $arg)
  {
    open($fin,$arg) or die("Could not open file '$arg' for reading.");
  }
  else
  {
    push(@patterns,$arg);
  }
}
$key_col--;
$alias_col--;

$#patterns >= 0 or die("No regular expression(s) PATTERN supplied.");

my %alias2key;
my %alias2alias;
my %is_key;
while(<$fin>)
{
  if(/\S/)
  {
    chomp;

    my @tuple  = split($delim);
    my $key    = $tuple[$key_col];
    my $alias  = $tuple[$alias_col];
    if(&IsMatch($key,@patterns))
    {
      $alias2key{$alias} = $key;
      # print "key[$key] alias[$alias]\n";

      $is_key{$key} = 1;
    }
    else
    {
      if(not(exists($alias2alias{$alias})))
      {
        $alias2alias{$alias} = $key;
      }
      else
      {
        $alias2alias{$alias} .= $delim . $key;
      }
      # print "alias[$key] alias[$alias]\n";
    }
  }
}

# Try to resolve as many aliases as possible
my %resolved;
for(my @aliases = keys(%alias2key); $#aliases>=0; @aliases = keys(%alias2key))
{
  foreach my $alias (@aliases)
  {
    my $key = $alias2key{$alias};
    if(exists($alias2alias{$alias}))
    {
      my @neighbors = split($delim,$alias2alias{$alias});

      # Add mapping from these neighbors to the key if they aren't in the
      # final mapping.
      foreach my $neighbor (@neighbors)
      {
	if(not(exists($resolved{$neighbor})))
	{
          $alias2key{$neighbor} = $key;
        }
      }
    }
    # Remove this mapping from the old record
    delete($alias2key{$alias});

    # Add the mapping to the final record
    $resolved{$alias} = $key;
  }
}

# Print the final mapping out.
foreach my $alias (keys(%resolved))
{
  my $key = $resolved{$alias};
  print $key, $delim, $alias, "\n";
}

# Print the identity mapping if requested.
if($identity)
{
  foreach my $key (keys(%is_key))
  {
    print $key, $delim, $key, "\n";
  }
}

exit(0);

sub IsMatch
{
  my $key      = shift;
  foreach my $pattern (@_)
  {
    my $result = eval("\$key =~ $pattern");
    if(defined($result) and $result)
    {
      return 1;
    }
  }
  return 0;
}

__DATA__
syntax: resolve_keys.pl [OPTIONS} PATTERN < TABFILE

Resolves keys and flattens the mapping.  Assumes the key is in the first column.  It replaces
any tuple pairs of the form:

	original 1: A <tab> B
	original 2: C <tab> B

with the tuples:
	
	resolved 1: A <tab> B
	resolved 2: A <tab> C

where A matches the regular expression PATTERN and C does not.

TABFILE is any tab-delimited file containing at least 2 columns of keys (one column containing
only aliases and the other containing keys and aliases).

OPTIONS are:

-d DELIM:   Set the delimiter to DELIM (default is tab)
-key COL:   Set the column for keys to be COL (default is 1).
-alias COL: Set tthe alias column to COL (default is 2).
-identity:  Include the identity mapping.  All keys will be listed as their own aliases in
            addition to those found (default does not include).


