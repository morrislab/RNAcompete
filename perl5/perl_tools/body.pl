#!/usr/bin/perl

use strict;

my $beg          = undef;
my $end          = undef;
my $count_blanks = 1;
my @files;
while(@ARGV)
{
  my $arg = shift @ARGV;
  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
  elsif($arg eq '-b')
  {
    $count_blanks = 0;
  }
  elsif(not(defined($beg)))
  {
    $beg = int($arg);
  }
  elsif(not(defined($end)))
  {
    $end = int($arg);
  }
  elsif(-f $arg or -l $arg)
  {
     push(@files, $arg);
  }
  else
  {
    die("body.pl: Bad argument '$arg' given.  Use --help for help.");
  }
}

if(not(defined($beg)))
{
  $beg = 1;
}

if(not(defined($end)))
{
  $end = -1;
}

if(scalar(@files) == 0)
{
   push(@files, '-');
}

foreach my $file (@files)
{
   my $num_lines = undef;
   my $tmp_file  = undef;
   my $fin;
   open($fin, $file) or die("Could not open file '$file'");
   if($end < -1)
   {
      $tmp_file = '/tmp/' . time . '.' . rand() . '.body.pl';
      open(TMP, ">$tmp_file") or die("Could not open temporary file '$tmp_file' for writing");
      while(<$fin>)
        { print TMP; }
      close(TMP);

      my $wc = `wc -l $tmp_file`;
      my @tuple = split(/\s+/,$wc);
      $num_lines = $tuple[1];

      open($fin, "$tmp_file") or die("Could not open the temporary file '$tmp_file' for reading");

      $end = $num_lines + $end + 1;
   }

   my $line = 0;
   # $end = defined($num_lines) ? $num_lines + $end + 1 : $end;
   while(<$fin>)
   {
     if($count_blanks or /\S/)
     {
       $line++;
       if($line >= $beg and ($end == -1 or $line <= $end))
       {
         print;
       }
     }
   }

   if(defined($tmp_file))
   {
      system("rm -f $tmp_file");
   }

   close($fin);
}

exit(0);

__DATA__
Syntax: body.pl BEG END [FILE < FILE] [FILE2 FILE3 ...]

BEG, END are the beginning and end lines (inclusive) to select from
the file.  If END=-1 then the rest of the file is included for example BEG=2 END=-1
returns the whole file except the first row.

OPTIONS are:

-b: Do *not* include blank lines when counting (default counts them).
  
