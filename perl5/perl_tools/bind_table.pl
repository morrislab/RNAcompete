#!/usr/bin/perl

##############################################################################
##############################################################################
##
## bind_table.pl
##
##############################################################################
##############################################################################
##
## Written by Josh Stuart in the lab of Stuart Kim, Stanford University.
##
##  Email address: jstuart@stanford.edu
##          Phone: (650) 725-7612
##
## Postal address: Department of Developmental Biology
##                 Beckman Center Room B314
##                 279 Campus Dr.
##                 Stanford, CA 94305
##
##       Web site: http://www.smi.stanford.edu/people/stuart
##
##############################################################################
##############################################################################
##
## Written: 00/00/02
## Updated: 00/00/02
##
##############################################################################
##############################################################################

require "libfile.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-k', 'scalar',     0, undef]
                , [    '-p', 'scalar',    '', undef]
                , ['--file',   'list',    [], undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose         = not($args{'-q'});
my $key_col         = $args{'-k'} - 1;
my $prefix          = $args{'-p'};
my @files           = @{$args{'--file'}};
my @extra           = @{$args{'--extra'}};

my $static_bindings = join(" ", @extra);

scalar(@files) == 2 or die("Please supply a TEMPLATE and TAB_FILE file");

my $template = $files[0];

my $tab_file = $files[1];

my $suffix   = '';
if($template =~ /(\..+)$/)
{
   $suffix = $1;
}

my $table = &openFile($tab_file);
my $i = 0;
my $line_no = 0;
my @fields;
my $num_fields = 0;
my $verb = $verbose ? '' : '-q';
while(<$table>)
{
   $line_no++;

   my @x = split("\t");

   chomp($x[$#x]);

   if($line_no == 1)
   {
      @fields = @x;
      $num_fields = scalar(@fields);
   }
   elsif(/\S/)
   {
      $i++;

      my $key = $key_col >= 0 ? $x[$key_col] : $i;

      my $out = $prefix . ($key_col >= 0 ? $x[$key_col] : ($i . $suffix));

      my $dynamic_bindings = '';

      for(my $j = 0; $j < $num_fields; $j++)
      {
         my $assignment = (defined($x[$j]) and $x[$j] =~ /\S/) ? "$fields[$j]=$x[$j]" : "$fields[$j]='&nbsp;'";
         $dynamic_bindings .= " $assignment";
      }

      my $cmd = "bind.pl $verb $template $static_bindings $dynamic_bindings > $out";

      $verbose and print STDERR "Binding row $i (key=$key) '$cmd'\n";
      `$cmd`;
      $verbose and print STDERR "Done binding row $i.\n";
   }
}
close($table);

exit(0);


__DATA__
syntax: bind_table.pl [OPTIONS] TEMPLATE TAB_FILE

The script iteratively calls bind.pl, producing a seperate, instantiated file for
each row in the TAB_FILE.  The TAB_FILE contains values for each variable.  The
variable names are defined in the first row.  The TEMPLATE file contains the
document containing the unbound fields.  If a key column in the TAB_FILE
exists then the script names each file with the key and the same suffix as the
TEMPLATE file.  If no key exists, the files are named sequentially from 1..n.

TEMPLATE - a file with bind.pl fields like $(foo) and $(bar) in them.

TAB_FILE - a tab-delimited file containing a different variable instantiation(s)
           on each line.  The first row contains the variable names and each
           subsequent row is assumed to contain a set of instantiations for the
           corresponding fields.

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Set the key column to COL (default is none).

-p PREFIX: Prepend PREFIX to each output file name (default is none).


