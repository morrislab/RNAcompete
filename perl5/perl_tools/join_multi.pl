#!/usr/bin/perl

require "libfile.pl";
require "liblist.pl";
require "libstd.pl";
require "libstring.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [     '-q', 'scalar',     0,     1]
                , [     '-f', 'scalar',     1, undef]
                , [     '-d', 'scalar',  "\t", undef]
                , [     '-l', 'scalar', undef, undef]
                , [     '-m', 'scalar',     1, undef]
                , [     '-b', 'scalar',    '', undef]
                , ['-fnames', 'scalar', undef, undef]
                , ['--file',   'list',    [], undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose        = not($args{'-q'});
my $arg_cols       = $args{'-f'};
my $delim          = $args{'-d'};
my $list           = $args{'-l'};
my $min            = $args{'-m'};
my $blank          = $args{'-b'};
my $fnames_delim   = $args{'-fnames'};
my @files          = @{$args{'--file'}};
my @extra          = @{$args{'--extra'}};

my $blank_placeholder = '___@@@_THIS_IS_A_BLANK_VALUE_@@@___';

my @global_cols;

if(defined($arg_cols))
{
   my @col_list = split(',', $arg_cols);

   foreach my $col (@col_list)
   {
      push(@global_cols, $col - 1);
   }
}

if(defined($list))
{
   my $file_list = &openFile($list);
   while(<$file_list>)
   {
      chomp;
      push(@files, $_);
   }
   close($file_list);
}

(scalar(@files) >= 2) or die("Must supply 2 or more files");

my @cols = @{&parseColsFromArgs(\@extra)};

# The number of files the key appears in:
my %count;

# Keep track of the keys_in_order keys are found in.
my @keys_in_order;

my $num_files = scalar(@files);

my @max_tuple;

for(my $j = 0; $j < $num_files; $j++)
{
   $verbose and print STDERR "(", $j+1, "/$num_files). ",
                             "Collecting every key from file '$files[$j]'...";

   my $file     = &openFile($files[$j]);

   my $key_cols = defined($cols[$j]) ? $cols[$j] : \@global_cols;

   my @sorted_key_cols = sort { $a <=> $b; } @{$key_cols};

   my %file_keys;

   my @file_keys;

   while(<$file>)
   {
      my @tuple = split($delim);

      chomp($tuple[$#tuple]);

      my $key = &extractKey(\@tuple, $key_cols, \@sorted_key_cols);

      if(not(exists($file_keys{$key})))
      {
         $file_keys{$key} = 1;

         push(@file_keys, $key);
      }

      if(not(defined($max_tuple[$j])) or $max_tuple[$j] < scalar(@tuple)) {
         $max_tuple[$j] = scalar(@tuple);
      }
   }
   close($file);

   foreach my $key (@file_keys)
   {
      if(not(exists($count{$key})))
      {
         $count{$key} = 1;

         push(@keys_in_order, $key);
      }
      else
      {
         $count{$key} += 1;
      }
   }
   $verbose and print STDERR " done.\n";
}

my $num_keys_total = scalar(keys(%count));

my %row;

my @data;

my $num_keys_kept = 0;

foreach my $key (@keys_in_order)
{
   if($count{$key} >= $min)
   {
      $data[$num_keys_kept][0] = $key;

      $row{$key} = $num_keys_kept;

      $num_keys_kept++;
   }
}

$verbose and print STDERR "$num_keys_kept keys present in $min or more files kept (out of $num_keys_total total found).\n";

my @blanks;

for(my $j = 0; $j < $num_files; $j++)
{
   $verbose and print STDERR "(", $j+1, "/$num_files). ",
                             "Collecting data from file '$files[$j]'...";

   my $file = &openFile($files[$j]);

   my %keys_not_seen = %count;

   $blanks[$j] = &duplicate($max_tuple[$j], $blank_placeholder);

   my $key_cols  = defined($cols[$j]) ? $cols[$j] : \@global_cols;

   my @sorted_key_cols = sort { $a <=> $b; } @{$key_cols};

   my $line_no = 0;
   while(my $line = <$file>)
   {
      $line_no++;

      # my @tuple = split($delim, $line);
      my $tuple = &mySplit($delim, $line);

      my $last = scalar(@{$tuple}) - 1;

      chomp($$tuple[$last]);

      my $key = &extractKey($tuple, $key_cols, \@sorted_key_cols);

      if(defined($fnames_delim) and $line_no == 1) {
         &listPrepend($tuple, $files[$j] . $fnames_delim);
      }

      if(exists($row{$key}))
      {
         if(exists($keys_not_seen{$key})) {
            my $i = $row{$key};
            push(@{$data[$i]}, &pad($tuple, $blanks[$j]));
            delete($keys_not_seen{$key});
         }
      }
   }

   foreach my $key (keys(%keys_not_seen)) {
      if(exists($row{$key})) {
         my $i = $row{$key};
         push(@{$data[$i]}, $blanks[$j]);
      }
   }

   close($file);

   $verbose and print STDERR " done.\n";
}

$verbose and print STDERR "Printing out the combined data...";

for(my $i = 0; $i < $num_keys_kept; $i++)
{
   my $key = defined($data[$i][0]) ? $data[$i][0] : $blank_placeholder;

   my $printable = $key;
   for(my $j = 1; $j <= $num_files; $j++) {
      my $val_list = defined($data[$i][$j]) ? $data[$i][$j] : $blanks[$j-1];
      my $values   = join($delim, @{$val_list});
      $printable .= $delim . $values;
   }
   $printable =~ s/$blank_placeholder/$blank/g;

   print STDOUT $printable, "\n";
}
$verbose and print STDERR " done.\n";

exit(0);

sub parseColsFromArgs
{
   my ($args) = @_;

   my @cols;

   my $fileno = undef;

   while(@{$args})
   {
      my $arg = shift @{$args};

      if($arg =~ /^-(\d+)/)
      {
         $fileno = int($1) - 1;

         $arg = shift @{$args};

         my @col_list = split(',', $arg);

         foreach my $col (@col_list)
         {
            push(@{$cols[$fileno]}, $col - 1);
         }
      }
   }
   return \@cols;
}

sub extractKey
{
   my ($tuple, $cols, $ordered_cols) = @_;

   my $key = '';

   for(my $i = 0; $i < scalar(@{$cols}); $i++) {
      $key .= (($i > 0) ? "\t" : "") . $$tuple[$$cols[$i]];
   }

   for(my $i = scalar(@{$cols}) - 1; $i >= 0; $i--) {
      splice(@{$tuple}, $$ordered_cols[$i], 1);
   }

   return $key;
}

__DATA__
syntax: join_multi.pl [OPTIONS] FILE1 FILE2 [FILE3 FILE4 ...]

Joins multiple files together, saving you from having to call
join.pl over and over. Note that this is a specific kind of join,
and the results from join_multi.pl will most likely be *DIFFERENT*
from the results of regular join.pl .

If you want to merge files together, for example, to collect all
the runs of a various experiments into one file, you can use
join_multi.pl like this:

Example:

You have a file:

Experiment1  0.11
Experiment2  2.22

And a second file:

Experiment1  1.111
Experiment5  5.55
Experiment6  6.6

If you run join_multi.pl FILE1 FILE2 on them, you will get:

Experiment1  0.11   1.111
Experiment2  2.22
Experiment5         5.55
Experiment6         6.6

(Note that join_multi.pl may also insert an extra tab between
 the key and the first value, so you may need to check for this
 and use "cut" appropriately.)

CAVEATS:

join_multi.pl has weird behavior when you use a totally empty file.
It will usually add two tabs between fields instead of one. To fix this,
echo '' >> PREVIOUSLY_EMPTY_FILE before you join_multi.pl it.


OPTIONS are:

-q: Quiet mode (default is verbose)

-f COL: Set the key column to COL (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).

-l LIST:  Reads the list of files from the file LIST

-m MIN: Set the minimum number of files that an entry has to 
        exist in to MIN.  The default is 1 which means the entry
        has to appear in at least one file.

-# COL: Set the key column of file # to COL.  For example -1 2
        tells the script to read the first file's key from the
        second column.

-b BLANK: Set the blank character to BLANK (default is empty).

-fnames DELIM: Use the file prepended to the column field header
               delimited by DELIM. Default does not prepend the
               file name to the column header field names.


