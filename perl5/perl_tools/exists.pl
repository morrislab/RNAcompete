#!/usr/bin/perl

use strict;

my $boolean = 0;
my $pos     = '';
my $neg     = '';
my $not     = 0;
my $type    = undef;
my @paths;
while(@ARGV)
{
  my $arg = shift @ARGV;
  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
  elsif($arg eq '-boolean')
  {
    $boolean = 1;
  }
  elsif($arg eq '-pos')
  {
    $pos = shift @ARGV;
  }
  elsif($arg eq '-neg')
  {
    $neg = shift @ARGV;
  }
  elsif($arg eq '-not')
  {
    $not = 1;
  }
  elsif($arg eq '-dir')
  {
    $type = defined($type) ? $type . ' dir' : 'dir';
  }
  elsif($arg eq '-file')
  {
    $type = defined($type) ? $type . ' file' : 'file';
  }
  elsif($arg eq '-link')
  {
    $type = defined($type) ? $type . ' link' : 'link';
  }
  elsif($arg eq '-')
  {
     while(<STDIN>)
     {
        my @tuple = split;
        chomp($tuple[$#tuple]);
        push(@paths,@tuple);
     }
  }
  else
  {
    push(@paths,$arg);
  }
}

my $return = '';
foreach my $path (@paths)
{
  my $positive = length($pos)>0 ? $pos : $path;
  my $negative = length($neg)>0 ? $neg : '';
  my $exists_report;
  if($boolean)
  {
    $exists_report = (&does_exist($path, $type)) ? '1' : '0';
  }
  elsif($not)
  {
    $exists_report = not(&does_exist($path, $type)) ? $positive : $negative;
  }
  else
  {
    $exists_report = &does_exist($path, $type) ? $positive : $negative;
  }

  if(length($exists_report)>0)
  {
    $return .= ((length($return)==0) ? '' : ' ') . $exists_report;
  }
}
print "$return\n";

exit(0);

sub does_exist
{
  my ($path, $type) = @_;
  $type = (not(defined($type)) or not($type =~ /\S/)) ? 'dir file link' : $type;

  my $exists = 0;

  if($type =~ /dir/i and (-d $path))
  {
     $exists = 1;
  }
  if($type =~ /file/i and (-f $path))
  {
     $exists = (-f $path);
  }
  if($type =~ /link/i and (-l $path))
  {
     $exists = (-f $path);
  }

  return $exists;
}

__DATA__
syntax: exists.pl [OPTIONS] PATH1 [PATH2 ...]

Prints a path if the path exists and a blank otherwise

OPTIONS are:

-boolean: make script output 1 if a PATHi exists and 0 otherwise.

-pos STRING: print out STRING if a PATHi exists (default is PATHi)

-neg STRING: print out STRING if a PATHi does *not* exist (default is blank)

-not: print out the arguments that are *not* paths.

-dir: Only print out if the entry is a directory.

-file: Only print out if the entry is a file.

-link Only print out if the entry is a symbolic link.

