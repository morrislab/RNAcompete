#!/usr/bin/perl

##############################################################################
##############################################################################
##
## mapper.pl
##
##############################################################################
##
## Written by Josh Stuart
##

require "libfile.pl";
require "$ENV{MYPERLDIR}/lib/libset.pl";
require "$ENV{MYPERLDIR}/lib/libattrib.pl";

use strict;
use warnings;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-f', 'scalar',     1, undef]
                , [    '-a', 'scalar',     2, undef]
                , [    '-v', 'scalar',     1, undef]
                , [    '-b', 'scalar',    '', undef]
                , [    '-p', 'scalar',     0, undef]
                , [    '-d', 'scalar',  "\t", undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose        = not($args{'-q'});
my $key_col        = int($args{'-f'}) - 1;
my $alias_col      = int($args{'-a'}) - 1;
my $value_col      = int($args{'-v'}) - 1;
my $blank          = $args{'-b'};
my $delim          = $args{'-d'};
my $print_unmapped = $args{'-p'};
my $extra          = $args{'--extra'};

my @files   = @{&getFilesFromList($extra)};

scalar(@files) >= 2 or die("Please supply at least 2 files");

my $target_file = shift(@files);

my @alias_files = @files;

my $target_key_list = &getColumn($target_file, $key_col, $delim, $blank);

my $remaining       = &list2Set($target_key_list, -1);

my $total_keys = scalar(keys(%{$remaining}));

my $total_rows = &sumUpSizes($remaining);

my @mapped_keys;
foreach my $key (@{$target_key_list})
{
   push(@mapped_keys, undef);
}

while((scalar(keys(%{$remaining})) > 0) and
      (scalar(@alias_files) > 0))
{
   my $alias_file = shift(@alias_files);

   my $num_remaining = scalar(keys(%{$remaining}));

   $verbose and print STDERR "Mapping $num_remaining remaining keys using aliases from file '$alias_file'.\n";

   &doTheMap($remaining, \@mapped_keys, $alias_file, $delim, $alias_col, $value_col);
}

my $unmapped_keys = scalar(keys(%{$remaining}));

my $unmapped_rows = &sumUpSizes($remaining);

my $mapped_keys   = $total_keys - $unmapped_keys;

my $mapped_rows   = $total_rows - $unmapped_rows;

my $percent_keys  = int(100 * $mapped_keys / $total_keys);

my $percent_rows  = int(100 * $mapped_rows / $total_rows);

$verbose and print STDERR "Mapped $mapped_keys keys ($percent_keys%), $mapped_rows rows ($percent_rows%).\n";

$verbose and print STDERR "(Failed to map $unmapped_keys keys, $unmapped_rows rows).\n";

my $filep;
open($filep, $target_file) or die("Could not open file '$target_file' for reading");
my $row = 0;
while(<$filep>)
{
   my @tuple = split($delim, $_);

   chomp($tuple[$#tuple]);

   my $item  = $tuple[$key_col];

   if(defined($mapped_keys[$row]))
   {
      $tuple[$key_col] = $mapped_keys[$row];

      print STDOUT join($delim, @tuple), "\n";
   }
   elsif($print_unmapped)
   {
      print STDOUT $_;
   }

   $row++;
}
close($filep);

exit(0);

sub doTheMap
{
   my ($remaining, $mapped, $file, $delim, $alias_col, $value_col) = @_;

   my $filep = &openFile($file);

   while(my $line = <$filep>)
   {
      my @x = split($delim, $line);

      chomp($x[$#x]);

      if(($alias_col < scalar(@x)) and
         ($value_col < scalar(@x)))
      {
         my $alias = $x[$alias_col];

         my $value = $x[$value_col];

         if(exists($$remaining{$alias}))
         {
            my $rows = $$remaining{$alias};

            foreach my $row (@{$rows})
            {
               if($row >= scalar(@{$mapped}))
               {
                  $verbose and print STDERR "Warning: alias '$alias': row $row exceeds mapped array size.\n";
               }
               elsif(defined($$mapped[$row]))
               {
                  $verbose and print STDERR "Warning: alias '$alias': attempted to overwrite row $row in mapped array.\n";
               }
               else
               {
                  $$mapped[$row] = $value;
               }
            }

            delete($$remaining{$alias});
         }
      }
   }

   close($filep);
}

sub sumUpSizes
{
   my ($set) = @_;

   my $sum = 0;

   foreach my $key (keys(%{$set}))
   {
      my $list = $$set{$key};

      $sum += scalar(@{$list});
   }

   return $sum;
}

__DATA__
syntax: mapper.pl [OPTIONS]

OPTIONS are:

-q: Quiet mode (default is verbose)

-f COL: Compare the values in column COL to the threshold in the file (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-b BLANK (set the blank character, default is '').


