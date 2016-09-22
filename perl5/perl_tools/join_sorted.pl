#!/usr/bin/perl

require "libfile.pl";

use strict;

my $delim = "\t";

my $file1       = undef;
my $file2       = undef;
my @key_cols1   = ();
my @key_cols2   = ();
my $print_left  = 1;
my $print_right = 1;
my $verbose     = 1;
while(@ARGV)
{
  my $arg = shift @ARGV;
  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
  elsif($arg eq '-q')
  {
    $verbose = 0;
  }
  elsif($arg eq '-1')
  {
    my @cols = &parseRanges(shift @ARGV);
    push(@key_cols1,@cols);
  }
  elsif($arg eq '-2')
  {
    my @cols = &parseRanges(shift @ARGV);
    push(@key_cols2,@cols);
  }
  elsif($arg eq '-inner')
  {
    $print_left  = 0;
    $print_right = 0;
  }
  elsif($arg eq '-outer')
  {
    $print_left  = 1;
    $print_right = 1;
  }
  elsif($arg eq '-left')
  {
    $print_left  = 1;
    $print_right = 0;
  }
  elsif($arg eq '-right')
  {
    $print_left  = 0;
    $print_right = 1;
  }
  elsif(((-f $arg) or ($arg eq '-')) and not(defined($file1)))
  {
    open($file1,$arg) or die("Could not open file '$arg'");
  }
  elsif(((-f $arg) or ($arg eq '-')) and not(defined($file2)))
  {
    open($file2,$arg) or die("Could not open file '$arg'");
  }
  else
  {
    die("Invalid argument '$arg' given.");
  }
}

defined($file1) or die("No left file specified.");
defined($file2) or die("No right file specified.");

if($#key_cols1==-1) { $key_cols1[0] = 1; }
if($#key_cols2==-1) { $key_cols2[0] = 1; }

for(my $i=0; $i<=$#key_cols1; $i++) { $key_cols1[$i]--; }
for(my $i=0; $i<=$#key_cols2; $i++) { $key_cols2[$i]--; }

# Sort the keys
my @sorted_key_cols1 = sort {$a <=> $b} (@key_cols1);
my @sorted_key_cols2 = sort {$a <=> $b} (@key_cols2);

my ($lines1,$lines2)                = (undef,undef);
my ($line1,$line2)                  = (undef,undef);
my ($last_line1,$last_line2)        = (undef,undef);
my ($done1,$done2,$done)            = (0,0,0);
my ($blanks1,$blanks2,$made_blanks) = ('','',0);
my ($in1,$in2,$in_both)             = (0,0,0);
my ($key1,$key2)                    = (undef,undef);
my ($values1,$values2)              = (undef,undef);
my ($val1,$val2)                  = (undef,undef);
my @values1;
my @values2;
my $passify = 10000;
my ($i,$k) = (0,0);
$verbose and print STDERR "Joining sorted files.";
while(not($done))
{
  my ($print1,$print2) = (0,0);
  if(not($done1) and (not(defined($lines1)) or scalar(@{$lines1})==0))
  {
    ($lines1,$last_line1) = &getLinesWithIdenticalKeys($file1,\@key_cols1,$last_line1,$delim);
    $line1 = $$lines1[0];
    if(not(defined($line1)))
      { $done1 = 1; }
    else
    { 
      ($key1,$val1) = &splitKeyAndValue($line1,\@key_cols1,\@sorted_key_cols1);
      @values1 = ();
      foreach my $line (@{$lines1})
      {
        my ($key,$vals) = &splitKeyAndValue($line,\@key_cols1,\@sorted_key_cols1);
	push(@values1,join($delim,@{$vals}));
      }
      $i += scalar(@{$lines1});
    }
    # print "1 : [", join("__AND__\n",@{$lines1}), "]\n";
    # @{$lines1} = ();
  }

  if(not($done2) and (not(defined($lines2)) or scalar(@{$lines2})==0))
  {
    ($lines2,$last_line2) = &getLinesWithIdenticalKeys($file2,\@key_cols2,$last_line2,$delim);
    $line2 = $$lines2[0];
    if(not(defined($line2)))
      { $done2 = 1; }
    else
    { 
      ($key2,$val2) = &splitKeyAndValue($line2,\@key_cols2,\@sorted_key_cols2);
      @values2 = ();
      foreach my $line (@{$lines2})
      {
        my ($key,$vals) = &splitKeyAndValue($line,\@key_cols2,\@sorted_key_cols2);
	push(@values2,join($delim,@{$vals}));
      }
      $i += scalar(@{$lines2});
    }
    # print "2 : [", join("__AND__\n",@{$lines2}), "]\n";
    # @{$lines2} = ();
  }
  
  if(not($made_blanks))
  {
    $blanks1  = join($delim,@{&emptyTuple(scalar(@{$val1}))});
    $blanks2  = join($delim,@{&emptyTuple(scalar(@{$val2}))});
    $made_blanks = 1;
  }

  # Valid lines from both files exist.
  if(not($done1) and not($done2))
  {
    my $order = &compareKeys($key1,$key2);
    # Key 1 sorts before key 2
    if($order<0)
      { $print1 = 1; }
    elsif($order>0)
      { $print2 = 1; }
    # The keys match
    else
    {
      foreach my $vals1 (@values1)
      { 
        foreach my $vals2 (@values2)
          { print $key1, $delim, $vals1, $delim, $vals2, "\n"; } 
      }
      @{$lines1} = ();
      @{$lines2} = ();
      $in_both++;
    }
  }
  # Only have tuples remaining from the left file.
  elsif(not($done1))
    { $print1 = 1; }

  # Only have tuples remaining from the right file.
  elsif(not($done2))
    { $print2 = 1; }

  if($print1)
  {
    if($print_left)
    {
      foreach my $vals1 (@values1)
        { print $key1, $delim, $vals1, $delim, $blanks2, "\n"; }
    }
    @{$lines1} = ();
    $in1 += scalar(@{$lines1});
  }

  # Only have tuples remaining from the right file.
  if($print2)
  {
    if($print_left)
    {
      foreach my $vals2 (@values2)
        { print $key2, $delim, $blanks1, $delim, $vals2, "\n"; }
    }
    @{$lines2} = ();
    $in2 += scalar(@{$lines2});
  }

  if($done1)
    { @{$lines2} = (); }

  if($done2)
    { @{$lines1} = (); }

  $done = $done1 and $done2;

  # Print status.
  if($verbose)
  {
    my $c = $i - $k;
    if($c >= $passify)
    { 
      print STDERR " $i";
      $k = $i;
    }
  }
}
$verbose and print STDERR " done.\n";

__DATA__
syntax: join_sorted.pl [OPTIONS] FILE1 FILE2

FILE1 and FILE2 are tab-delimited files with a key in the first column.  Both must be
  sorted by their keys.

-q: Quiet mode (default is verbose).  If verbose, prints to standard error:

          IN_BOTH IN_ONE IN_TWO

    where IN_BOTH is the number of common keys between 1 and 2, IN_ONE are the
    number of keys in FILE1 only, and IN_TWO are the number of keys in FILE2 only.

-1 COLUMNS: Specify the columns for the key in FILE1.  Can specify multiple columns.

-2 COLUMNS: Same as -1 but for FILE2.

-d DELIM: Set the field delimiter to DELIM (default is <tab>).

-inner: only output tuples that are common to both files.

-outer: output all tuples and pad with blanks when a key from one file does not match in the other

-left: print tuples present in FILE1

-right: print tuples present in FILE2





