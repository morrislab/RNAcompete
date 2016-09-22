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
my ($vals1,$vals2)                    = (undef,undef);
my $passify = 100000;
my ($i,$k) = (0,0);
$verbose and print STDERR "Joining sorted files.";
while(not($done))
{
  my ($print1,$print2) = (0,0);

  my $x = $line1; chomp($x); my $y = $line2; chomp($y);
  # print "beg [$x] [$y]\n";

  if(not($done1) and (not(defined($line1)) or length($line1)==0))
  {
    if(eof($file1))
      { $done1 = 1; }
    else
    { 
      $line1 = <$file1>;
      my $x = $line1; chomp($x);
      # print "got 1 [$x]\n";
      ($key1,$vals1) = &splitKeyAndValue($line1,\@key_cols1,\@sorted_key_cols1);
      $i++;
    }
  }

  if(not($done2) and (not(defined($line2)) or length($line2)==0))
  {
    if(eof($file2))
      { $done2 = 1; }
    else
    { 
      $line2 = <$file2>;
      my $x = $line2; chomp($x);
      # print "got 2 [$x]\n";
      ($key2,$vals2) = &splitKeyAndValue($line2,\@key_cols2,\@sorted_key_cols2);
      $i++;
    }
  }
  
  if(not($made_blanks))
  {
    $blanks1  = join($delim,@{&emptyTuple(scalar(@{$vals1}))});
    $blanks2  = join($delim,@{&emptyTuple(scalar(@{$vals2}))});
    $made_blanks = 1;
  }

  # Valid lines from both files exist.
  my $order = undef;
  if(not($done1) and not($done2))
  {
    $order = &compareKeys($key1,$key2);
    # Key 1 sorts before key 2
    if($order<0)
      { $print1 = 1; }
    elsif($order>0)
      { $print2 = 1; }
    # The keys match
    else
    {
      print $key1, $delim, join($delim,@{$vals1}), $delim, join($delim,@{$vals2}), "\n";
      $line1 = '';
      $line2 = '';
      $in_both++;
    }
  }
  elsif(not($done1))
    { $print1 = 1; }

  elsif(not($done2))
    { $print2 = 1; }

  if($print1)
  {
    if($print_left)
      { print $key1, $delim, join($delim,@{$vals1}), $delim, $blanks2, "\n"; }
    $line1 = '';
    $in1++;
  }

  # Only have tuples remaining from the right file.
  if($print2)
  {
    if($print_left)
      { print $key2, $delim, $blanks1, $delim, join($delim,@{$vals2}), "\n"; }
    $line2 = '';
    $in2++;
  }

  if($done1)
    { $line2 = ''; }

  if($done2)
    { $lines1 = ''; }

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

  my $x = $line1; chomp($x); my $y = $line2; chomp($y);
  # print "end [$x] [$y] [$order] [$print1] [$print2] [$done1] [$done2]\n\n";

}
$verbose and print STDERR " done.\n";

__DATA__
syntax: join_sorted_uniq.pl [OPTIONS] FILE1 FILE2

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





