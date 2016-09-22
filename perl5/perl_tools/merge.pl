#!/usr/bin/perl

use strict;

require "libfile.pl";

my $verbose  = 1;
my $delim1   = "\t";
my $delim2   = ',';
my $file1    = undef;
my $file2    = undef;
my $key_col1 = 1;
my $key_col2 = 1;
my $header   = 1;

while(@ARGV)
{
  my $arg = shift @ARGV;
  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
  elsif($arg eq '-d1')
  {
    $delim1 = shift @ARGV;
  }
  elsif($arg eq '-d2')
  {
    $delim2 = shift @ARGV;
  }
  elsif($arg eq '-k1')
  {
    $key_col1 = int(shift @ARGV);
  }
  elsif($arg eq '-k2')
  {
    $key_col2 = int(shift @ARGV);
  }
  elsif($arg eq '-k')
  {
    $key_col1 = int(shift @ARGV);
    $key_col2 = $key_col1;
  }
  elsif($arg eq '-nh')
  {
    $header = 0;
  }
  elsif(not(defined($file1)) and ((-f $arg) or $arg eq '-'))
  {
    $file1 = &openFile($arg);
  }
  elsif(not(defined($file2)) and ((-f $arg) or $arg eq '-'))
  {
    $file2 = &openFile($arg);
  }
  else
  {
    die("Invalid argument '$arg'.");
  }
}
$key_col1--;
$key_col2--;

defined($file1) or die("Please supply 2 input files to merge.");
defined($file2) or die("Only 1 input file supplied.");

my @fields1;
my %field2col1;
my @fields2;
my %field2col2;
my @col2;
if($header)
{
  $_ = <$file1>; chomp;
  @fields1 = split($delim1);
  if(/$delim1\s*$/) { push(@fields1,''); }
  for(my $i=0; $i<=$#fields1; $i++)
    { $field2col1{$fields1[$i]} = $i; }

  $_ = <$file2>; chomp;
  @fields2 = split($delim1);
  if(/$delim1\s*$/) { push(@fields2,''); }
  for(my $i=0; $i<=$#fields2; $i++)
    { $field2col2{$fields2[$i]} = $i; }

  # Merge the headers
  my @header1 = @fields1;
  my @header2 = @fields2;
  for(my $i=$#header2; $i>=0; $i--)
  {
    if($i != $key_col2)
    {
      my $x = $header2[$i];
      if(exists($field2col1{$x}))
      {
        splice(@header2,$i,1);
      }
    }
    else
    {
      splice(@header2,$i,1);
    }
  }

  # Print the new header out.
  print join($delim1, @header1);

  if($#header2>=0)
  {
    print $delim1, join($delim1,@header2);
  }
  print "\n";
}

my $done = 0;
my $pop1 = 1;
my $pop2 = 1;
my @tuple1;
my @tuple2;
my $key1;
my $key2;
my @empty1 = ();
my @empty2 = ();
my $end1 = 0;
my $end2 = 0;
while(not($done))
{
  if($pop1)
  {
    $_ = <$file1>;

    if(defined($_))
    {
      chomp;
      @tuple1 = split($delim1);
      if(/$delim1\s*$/) { push(@tuple1,''); }
      $key1 = $tuple1[$key_col1];

      if($#empty1==-1)
      {
        for(my $i=0; $i<=$#tuple1; $i++)
          { push(@empty1,''); }
      }
    }
    else
    {
      $end1 = 1;
      $key1 = undef;
    }
  }

  if($pop2)
  {
    $_ = <$file2>;
    if(defined($_))
    {
      chomp;
      @tuple2 = split($delim1);
      if(/$delim1\s*$/) { push(@tuple2,''); }
      $key2 = $tuple2[$key_col2];

      if($#empty2==-1)
      {
        for(my $i=0; $i<=$#tuple2; $i++)
          { push(@empty2,''); }
      }
    }
    else
    {
      $end2 = 1;
      $key2 = undef;
    }
  }

  my $key;
  my @print1 = ();
  my @print2 = ();

  # If they're both equal merge them.
  if(defined($key1) and defined($key2) and ($key1 eq $key2))
  {
    $key    = $key1;
    @print1 = @tuple1;
    @print2 = @tuple2;
    $pop1   = 1;
    $pop2   = 1;
  }
  elsif(not(defined($key1)) and not(defined($key2)))
  {
    $key    = undef;
    @print1 = ();
    @print2 = ();
    $pop1   = 0;
    $pop2   = 0;
  }
  elsif((defined($key1) and defined($key2)) and ($key1 cmp $key2)<0)
  {
    $key    = $key1;
    @print1 = @tuple1;
    @print2 = @empty2;
    $pop1   = 1;
    $pop2   = 0;
  }
  elsif((defined($key1) and defined($key2)) and ($key1 cmp $key2)>0)
  {
    $key    = $key2;
    @print1 = @empty1;
    @print2 = @tuple2;
    $pop1   = 0;
    $pop2   = 1;
  }
  elsif(defined($key1) and not(defined($key2)))
  {
    $key    = $key1;
    @print1 = @tuple1;
    @print2 = @empty2;
    $pop1   = 1;
    $pop2   = 0;
  }
  elsif(not(defined($key1)) and defined($key2))
  {
    $key    = $key2;
    @print1 = @empty1;
    @print2 = @tuple2;
    $pop1   = 0;
    $pop2   = 1;
  }
  else
  {
    print STDERR "WTF?!\n";
    $key = undef;
  }

  # Merge any shared fields
  if(defined($key))
  {
    for(my $i=$#print2; $i>=0; $i--)
    {
      if(exists($field2col1{$fields2[$i]}))
      {
        my $j = $field2col1{$fields2[$i]};
        my $x = splice(@print2,$i,1);
        if(length($x)>0)
        {
          $print1[$j] .= length($print1[$j])>0 ? ($delim2 . $x) : $x;
        }
      }
    }

    splice(@print1, $key_col1, 1);

    # Print out the first tuple (includes merged entries)
    print $key,
          ($#print1>=0 ? ($delim1 . join($delim1, @print1)) : ''),
          ($#print2>=0 ? ($delim1 . join($delim1, @print2)) : '');
    print "\n";
  }
  else
  {
    $done = 1;
  }
}

exit(0);

__DATA__

syntax: merge.pl [OPTIONS] FILE1 FILE2

FILE1 and FILE2 are both tab-delimited files. (Or something-else-delimited,
but you must specify this explicitly with -d1 and -d2.)

Merges two files together, saving you the trouble of running
multiple joins.

**********************************************************************
** You might consider using "join_multi.pl" instead,
** which can merge two or more files (merge.pl is limited to two files).
**********************************************************************

If you start with two files,

File 1: (tab-delimited)

Alpha    a104.1
Beta     b432.4
Gamma    g902.2

And:

File 2: (tab-delimted)

Beta     b999.9
Omega    o414.4

Then merge.pl -nh file_1 file_2 will give you (shown as a table here--actual
output does not include the vertical bars):

Alpha | a104.1 |       |        |
Beta  | b432.4 | Beta  | b999.9 |
Gamma | g902.2 |       |        |
Omega |        | Omega | o414.4 |

Make SURE to say "no header" in cases like this. Also, both files must either have
or not have a header--you cannot mix header status.

Also, this program does NOT ignore blank lines.

OPTIONS:

-d1 DELIM: INPUT delimiter for *both* files.
           -d1 DELIM changes the input delimiter to DELIM (default is tab).

-d2 DELIM: OUTPUT delimiter (NOT the delimiter for file2).
           Change the delimiter for merged output entries to DELIM (default is comma).

-k  COL:   Set the key column for both file 1 and 2 to COL.
    -k1 COL:   Set the key column for just file 1 to COL (default is 1).
    -k2 COL:   Set the key column for just file 2 to COL (default is 1).

-nh: No header.  Tell the script that the input FILE1 and FILE2 both have no headers.


