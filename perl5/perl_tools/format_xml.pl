#!/usr/bin/perl

use strict;

my $command = 'xmllint --format --nowrap';
my @files;
my $stdin = 0;
my $add_args;

while(@ARGV)
{
  my $arg = shift @ARGV;
  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
  elsif(-f $arg)
  {
    push(@files,$arg);
  }
  elsif($arg eq '-')
  {
    $stdin = 1;
  }
  else
  {
    $add_args .= length($add_args)>0 ? (' ' . $arg) : $arg;
  }
}

if($#files==-1)
  { $stdin = 1; }

my $tmp_file = '/tmp/format_xml_' . time;
foreach my $file (@files)
{
  system("cat $file >> $tmp_file");
}

if($stdin)
{
  open(TMP,">>$tmp_file");
  while(<STDIN>) { print TMP; }
  close(TMP);
}

system("$command $add_args $tmp_file");
system("rm -f $tmp_file");

__DATA__
syntax: format_xml [OPTIONS] FILE


