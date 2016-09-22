#!/usr/local/bin/perl

use File::Temp qw/ tempfile tempdir /;

##############################################################################
##############################################################################
##
## join_batch.pl
##
##############################################################################
##############################################################################
##
## Written by Josh Stuart.
##
##  Email address: jstuart@soe.ucsc.edu
##          Phone: (831) 459-1344
##
## Postal address: 1156 High Street, 308 Physical Sciences
##                 Mail Stop: SOE2
##                 Santa Cruz, CA 95064
##
##       Web site: http://www.soe.ucsc.edu/~jstuart/
##
##############################################################################
##############################################################################

require "libfile.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;


my @flags   = (
                  [     '-q', 'scalar',     0,     1]
                , [     '-d', 'scalar',  "\t", undef]
                , ['-tmpdir', 'scalar','/tmp', undef]
                , [   '-dos', 'scalar',     0,     1]
                , [ '--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose  = not($args{'-q'});
my $delim    = $args{'-d'};
my $tmp_dir  = $args{'-tmpdir'};
my $dos2unix = $args{'-dos'};
my $file     = $args{'--file'};
my @extra    = @{$args{'--extra'}};

my $extra_params = join(" ",@extra);

my $id_header  = 'ID';
my $data_delim = "\t";

my @data_files;
my @key_cols;
my @data_cols;
my @field_names;
my @head_lines;

my $output_has_header = 0;

my $filep;
open($filep, $file) or die("Could not open file '$file' for reading");
while(<$filep>)
{
   if(/^##\s*ID\s*=\s*(\S+)/) {
      $id_header = $1;
      $id_header =~ s/,/@@@@/g;
   }
   elsif(/^##\s*DELIM\s*=(.*)$/) {
      $data_delim = $1;
      $data_delim = ($data_delim =~ /\\t/) ? "\t" : $data_delim;
   }
   elsif(not(/^#/)) {
      my @x = split($delim, $_);
      chomp($x[$#x]);
      my ($data_file, $key_col, $data_col, $field_name, $head_lines) = @x;
      if(defined($data_file)) {
         $data_file  = &resolvePath($data_file);
         $verbose and print STDERR "join_batch.pl: Will include file '$data_file'\n";
         $key_col    = defined($key_col)    ? $key_col    : 1;
         $data_col   = defined($data_col)   ? $data_col   : '2-';
         $head_lines = defined($head_lines) ? $head_lines : 0;

         if(defined($field_name)) {
            $output_has_header = 1;
         }

         $field_name =~ s/,/\t/g;

         push(@data_files, $data_file);
         push(@key_cols, $key_col);
         push(@data_cols, $data_col);
         push(@field_names, $field_name);
         push(@head_lines, $head_lines);
      }
   }
}
close($filep);

my $maybeDos2UnixPipe = $dos2unix ? 'dos2unix.pl |' : '';

my $template = 'join_batch_XXXX';

my ($tmpFh1, $tmpFile1) = tempfile($template, UNLINK => 1, SUFFIX => '.tmp', DIR => $tmp_dir);
close($tmpFh1);

my ($tmpFh2, $tmpFile2) = tempfile($template, UNLINK => 1, SUFFIX => '.tmp', DIR => $tmp_dir);
close($tmpFh2);

if($output_has_header) {
   system("echo '$id_header' > $tmpFile1");
}

# Find all the keys.
if(scalar(@data_files) > 0) {
   for(my $i = 0; $i < scalar(@data_files); $i++) {
      my $tail = $head_lines[$i] + 1;
      system("tail -n +$tail $data_files[$i] | $maybeDos2UnixPipe cut.pl -f $key_cols[$i] | sed 's/\t/@@@@/g' >> $tmpFile2");
   }
   system("sort -u $tmpFile2 >> $tmpFile1");
   system("rm -f $tmpFile2");
}

if(scalar(@data_files) > 1) {
   for(my $i = 0; $i < scalar(@data_files); $i++) {
      my ($tmpFh2, $tmpFile2) = tempfile($template, UNLINK => 1, SUFFIX => '.tmp', DIR => $tmp_dir);
      close($tmpFh2);
      my ($tmpFh3, $tmpFile3) = tempfile($template, UNLINK => 1, SUFFIX => '.tmp', DIR => $tmp_dir);
      close($tmpFh3);

      if($output_has_header) {
         system("echo '$id_header	$field_names[$i]' > $tmpFile3");
      }

      my $tail = $head_lines[$i] + 1;
      system("tail -n +$tail $data_files[$i] | $maybeDos2UnixPipe cut.pl -f $key_cols[$i] | sed 's/\t/@@@@/g' > $tmpFile2");
      system("tail -n +$tail $data_files[$i] | $maybeDos2UnixPipe cut.pl -f $data_cols[$i] | paste $tmpFile2 - >> $tmpFile3");
      system("mv $tmpFile3 $tmpFile2");

      my $cmd = "join.pl -q $extra_params $tmpFile1 $tmpFile2 > $tmpFile3";
      $verbose and print STDERR "join_batch.pl: Command is: $cmd.\n";
      system("join.pl -q $extra_params $tmpFile1 $tmpFile2 > $tmpFile3");
      system("mv $tmpFile3 $tmpFile1");
      system("rm -f $tmpFile2");
   }
}

open($tmpFh1, "$tmpFile1");

while(<$tmpFh1>) {
   s/@@@@/\t/g;
   print STDOUT $_;
}
close($tmpFh1);

# while(1) {}

exit(0);

__DATA__
syntax: join_batch.pl [< BATCH_FILE | BATCH_FILE]

The BATCH_FILE should have on each line:

DATA_FILE \t KEY_COL(s) \t DATA_COL(S) \t FIELD_NAME(S) \t HEAD_LINES

DATA_FILE:   the name of a tab-delimited file containing data that is keyed with
             the same key space as the other files listed.
KEY_COL(s) : the column(s) to find the keys in the file in. The default is to use
             the first column.
FIELD_NAMES: Name each of the columns supplied.

HEAD_LINES:  the number of header lines to ignore in the file. The default is 0.

Parameters can be supplied using ## comment lines. Allowed parameters are:

## ID = ID_NAME(S)

Specifies the column name(s) of the identifier field. If multiple columns are used
for the key, use a comma-separated list of names.

OPTIONS are:

-q: Quiet mode (default is verbose)

-d DELIM: Set the field delimiter to DELIM (default is tab).

-dos: Run dos2unix on each file before using it because they have silly DOS line breaks.


