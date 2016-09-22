#!/usr/bin/perl

require "libfile.pl";

use strict;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-f', 'scalar', undef, undef]
                , [    '-k', 'scalar', undef, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [   '-di', 'scalar', undef, undef]
                , [   '-do', 'scalar', undef, undef]
                , [    '-m', 'scalar',     0, undef]
                , [   '-nt', 'scalar',     0,     1]
                , ['--file',   'list', undef, undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose         = not($args{'-q'});
my $fields          = $args{'-f'};
my $delim           = $args{'-d'};
my $delim_in        = $args{'-di'};
my $delim_out       = $args{'-do'};
my $delim           = $args{'-d'};
my $multi_delim_ins = $args{'-m'};
my $tight           = not($args{'-nt'});
my @extra           = @{$args{'--extra'}};
my $files           = $args{'--file'};
$files              = defined($files) ? $files : ['-'];

$delim_in  = defined($delim_in) ? $delim_in : $delim;
$delim_out = defined($delim_out) ? $delim_out : $delim;

# If the fields were supplied in a file, then read it.
if(-f $fields) {
   my $filep = &openFile($fields);
   my @fields;
   while(<$filep>) {
      my @tuple = split(/\s*/);
      push(@fields, @tuple);
   }
   $fields = join(',',@fields);
}

foreach my $file (@{$files}) {
   my $filep = &openFile($file);
   if(defined($filep)) {
      my @cols;
      my $prev_cols = 0;
      while(<$filep>) {
        my @tuple_all = $multi_delim_ins ? split(/[$delim_in]+/) : split(/$delim_in/);

        my $num_cols = scalar(@tuple_all);

        if(defined($fields)) {
          if($num_cols != $prev_cols) {
            @cols = &parseRanges($fields, $num_cols, -1);
          }
          if(not($tight)) {
            $fields = undef;
          }
        }

        if($#tuple_all >= 0)
          { chomp($tuple_all[$#tuple_all]); }

        my @tuple;

        foreach my $i (@cols) {
          if($i <= $#tuple_all) {
             push(@tuple,$tuple_all[$i]);
          }
        }

        print STDOUT join($delim_out, @tuple), "\n";

        $prev_cols = $num_cols;
      }
      close($filep);
   }
}

exit(0);

__DATA__

syntax: cut.pl [OPTIONS] TAB_FILE

TAB_FILE is any tab-delim_inited file.  Can also be passed into standard
   input.

OPTIONS are:

-q: Quiet mode: turn verbosity off (default verbose)
-d DELIM: Change the input and output delimiter to DELIM (default <tab>).
-di DELIM: Change the input delimiter to DELIM (default <tab>).
-do DELIM: Change the output delimiter to DELIM (default <tab>).
-nt:       Not tight.  Tell the script to expect the same number of columns in
           each row so that it does not need to recompute the column boundaries for
           each row.  This speeds the script up somewhat.

-f RANGES: specify column ranges to include.  RANGES are comma-
           separated lists of single columns or a range of columns
           for example:

                   5-6,2,1-3

           would select columns 1 through 6 except column 4.  Note
           that 2 is redundantly specified, but no error results.

           If RANGES is a file, then cut.pl reads in the ranges from the given
           file. Each line is treated as a seperate range if multiple lines
           are given.

           Negative numbers mean reading from the END of the list. So
           cut.pl -f -1 means "get the last column from each row." Note that
           this is calculated on EACH row, so variable length rows will still
           have their last elements returned.

Examples:

   cat MYFILE | cut.pl -f 1,3-10 > OUTPUT
