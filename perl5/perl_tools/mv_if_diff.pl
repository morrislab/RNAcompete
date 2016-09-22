#!/usr/bin/perl

use strict;

my $be_safe = 1;
my $source = '';
my $destination = '';

while(@ARGV)
{
  my $arg = shift @ARGV;

  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
  elsif(-f $arg and length($source)==0)
  {
    $source = $arg;
  }
  elsif(-f $arg and length($destination)==0)
  {
    $destination = $arg;
  }
  else
  {
    die("Bad argument '$arg' given.");
  }
}

(length($source)>0 and length($destination)>0) or die("Please supply 2 input files.");

my @diff_wc_out = split(/\s+/,`diff $source $destination | wc`);

my $diff_lines = $diff_wc_out[1];

if($diff_lines > 0)
{
  `cp $destination $destination.backup`;
  `mv $source $destination`;
}
else
{
  `rm -f $source`;
}

exit(0);

__DATA__
mv_if_diff.pl [OPTIONS] SOURCE_FILE DESTINATION_FILE

Moves the SOURCE_FILE onto the DESTINATION_FILE only if the SOURCE_FILE is different
than the DESTINATION_FILE.  Creates a DESTINATION_FILE.backup as well.  If the two files
are identiical then this program *removes* the SOURCE_FILE.

