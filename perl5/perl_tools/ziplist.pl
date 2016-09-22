#!/usr/bin/perl

use strict;

if($#ARGV != 0)
{
  print STDOUT <DATA>;
  exit(0);
}

my $zip_table = `unzip -l $ARGV[0]`;
# $zip_table =~ s/\n[ -]+\n.+$//;
# $zip_table =~ s/^.+\n[ -]+\n//;
# $zip_table =~ s/^.+\n[ -]+\n//;
# $zip_table =~ s/^\.+---//;
# $zip_table =~ s/[ ]+/\t/g;

my @zip_table = split("\n",$zip_table);
my $seen_header=0;
my $seen_footer=0;
foreach $_ (@zip_table)
{
  if(/\S/)
  {
    if(/^[ -]+$/)
    {
      if(not($seen_header))
      {
        $seen_header=1;
      }
      elsif(not($seen_footer))
      {
        $seen_footer=1;
      }
    }
    elsif($seen_header and not($seen_footer))
    {
      my @tuple = split(/\s+/,$_);
      print "$tuple[4]\n";
    }
  }
}

__DATA__

syntax: ziplist.pl zipfile

Prints out a list of the file names in the zip archive.
This script requires the command 'unzip' be in your path.

