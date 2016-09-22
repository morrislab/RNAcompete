#!/usr/bin/perl

use strict;

require "libfile.pl";

$| = 1;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-k', 'scalar',     0, undef]
                , [    '-s', 'scalar', undef, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-h', 'scalar',     1, undef]
                , [    '-v', 'scalar',     1, undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose      = not($args{'-q'});
my $key_column   = $args{'-k'};
my $key_name     = $args{'-s'};
my $delim        = $args{'-d'};
my $headers      = $args{'-h'};
my $column_value = $args{'-v'};
my $file         = $args{'--file'};

open(FILE, $file) or die "could not open file '$file'";
my $line = <FILE>;
chop $line;
my @headers = split(/\t/, $line);

while(<FILE>)
{
  chop;

  my @row = split(/\t/);

  if (defined($key_name) and ($row[$key_column] eq $key_name))
  {
    for (my $i = 0; $i < @row; $i++)
    {
      if ($key_column != $i and $row[$i] eq $column_value)
      {
         print "$headers[$i]\n";
      }
    }
    last;
  }
}

__DATA__

find_columns.pl [FILE | < FILE]

   Prints the set of columns for a given row that have a certain value.
   For example, you can give it a GO file and specify a row you're
   interested in, and it will tell you all the GO categories that are '1'
   for that row/gene.

   -k <num>:    The key column (default: 0)
   -s <name>:   String value of the key column
   -v <value>:  Value to find in order to print (default: 1)

