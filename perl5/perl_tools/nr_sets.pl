#!/usr/bin/perl

##############################################################################
##############################################################################
##
## nr_sets.pl
##
##############################################################################
##############################################################################
##
## Written by Josh Stuart
##
##############################################################################

require "libfile.pl";
require "$ENV{MYPERLDIR}/lib/libset.pl";

use strict;
use warnings;

# Flush output to STDOUT immediately.
$| = 1;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-l', 'scalar', undef, undef]
                , [    '-p', 'scalar', undef, undef]
                , [    '-o', 'scalar',     1, undef]
                , [ '-qtol', 'scalar',    50, undef]
                , [ '-dtol', 'scalar', undef, undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $verbose           = not($args{'-q'});
my $delim             = &interpMetaChars($args{'-d'});
my $set_list_file     = $args{'-l'};
my $pval_cut          = $args{'-p'};
my $LOG_PVAL_CUTOFF   = defined($pval_cut) ? log($pval_cut) / log(10) : undef;
my $OVERLAP_MIN       = $args{'-o'};
my $QUERY_TOLERANCE   = defined($args{'-qtol'}) ? $args{'-qtol'} / 100 : undef;
my $DB_TOLERANCE      = defined($args{'-dtol'}) ? $args{'-dtol'} / 100 : undef;
my $file              = $args{'--file'};

# Records the order in which the sets were read from the file.
my @order;

$verbose and print STDERR "Reading in sets from a set-major list.\n";
my $sets = &setsReadLists($file, $delim, 0, 0, \@order, undef, 0);
$verbose and print STDERR "Finished reading in the sets.\n";

my $union      = &setsUnionSelf($sets);
my $UNION_SIZE = &setSize($union);

# If the user supplied a subset of sets, restrict to these.
if(defined($set_list_file)) {
   my %selection;
   @order = ();
   foreach my $set_key (@{&readFileColumn($set_list_file)}) {
      chomp($set_key);
      if(exists($$sets{$set_key})) {
         $selection{$set_key} = $$sets{$set_key};
         push(@order, $set_key);
      }
   }
   $sets = \%selection;
}

# All of the sets we've kept so far.
my %kept;

foreach my $set_key (@order) {
   my $set = exists($$sets{$set_key}) ? $$sets{$set_key} : undef;
   if(&isRedundant($set, \%kept)) {
      # Skip this set since it overlaps with another set we've kept.
      # Note: Do *not* put this set in what we've kept since we don't want
      # to penalize future sets from overlapping with it!
   }
   else {
      # Store it in the current list of sets we've kept.
      $kept{$set_key} = $set;
      &setPrint($set, undef, "\t", undef, $set_key, "\n");
   }
}

exit(0);

sub isRedundant {
   my ($query_set, $db_sets) = @_;

   # Empty or undefined sets are considered redundant so we don't
   # save them.
   if(not(defined($query_set)) or &setSize($query_set) == 0) {
      return 1;
   }
   # If there are no sets in the database, this new set is obviously
   # non-redundant.
   if(not(defined($db_sets)) or &setSize($db_sets) == 0) {
      return 0;
   }
   foreach my $set_key (@{&setMembersList($db_sets)}) {
      my $db_set = $$db_sets{$set_key};
      if(&minOverlap($query_set, $db_set)) {
         return 1;
      }
   }
   return 0;
}

sub minOverlap {
   my ($query_set, $db_set) = @_;
   if(defined($query_set) and defined($db_set)) {
      my ($lpval,$ov,$query_size,$db_size,$pop,$intersect) = &setOverlap($query_set, $db_set, $UNION_SIZE);
      my $perc_query    = $query_size > 0 ? $ov / $query_size : 0;
      my $perc_db       = $db_size > 0 ? $ov / $db_size : 0;

      my $min_overlap   = $ov >= $OVERLAP_MIN;
      my $query_covered = defined($QUERY_TOLERANCE) ? $perc_query > $QUERY_TOLERANCE : 1;
      my $db_covered    = defined($DB_TOLERANCE) ? $perc_db > $DB_TOLERANCE : 1;
      my $signif        = defined($LOG_PVAL_CUTOFF) ? $lpval < $LOG_PVAL_CUTOFF : 1;

      my $result = ($min_overlap and $query_covered and $db_covered and $signif);

      return $result;
   }
   return 1;
}

__DATA__
syntax: nr_sets.pl [OPTIONS] [SETS_FILE | < SETS_FILE]

Produces a non-redundant set of sets. The script reads in a set of sets
in set-major format. In the order that the sets were read in, the script
keeps a set if it does not overlap with another set that it has seen up
to that point. The script tolerates a certain amount of overlap between
the current set and a previously seen set. The tolerance parameter can
be set to allow greater or lesser overlap.

Note that the script's behavior depends on the order of the input sets.
One could rank the sets in order of significance (highest significance
first) and the script will keep the most significant sets first and
throw out any redundant, lesser significant sets.

OPTIONS are:

-q: Quiet mode (default is verbose)

-d DELIM: Set the field delimiter to DELIM (default is tab).

-h HEADERS: Set the number of header lines to HEADERS (default is 1).
            This is not used when the input type is "p" or "P".

-l SET_LIST_FILE: Provide a file containing a selection of sets to use.
            Only sets in this file will be considered. They will be
            considered in the order supplied in this file. Note that,
            for overlap analysis, the population size (number of members
            in any set) is still considered to be the union of all sets
            provided in the SETS_FILE.

-p PVAL: If a query set overlaps with a pval of PVAL or smaller with some
         database set, it is considered redundant (default is not defined
         so the significance is ignored). This is used in combination with
         -o, -qtol, and -dtol using a logical AND operation. In other words,
         a set will be considered redundant if it meets the overlap criteria
         AND is significant.

-o OVERLAP: If a query set overlaps by OVERLAP or more with any database set,
            it is considered to be redundant (default is 1).

-qtol PERC: If at least PERC percent of the query set overlaps with a database
            set, the query is considered to be redundant with the database set
            (default 50%).

-dtol PERC: If at least PERC percent of a database set overlaps with the query
            set, the query is considered to be redundant with the database set
            (default is not defined; i.e. this overlap is ignored).

SETS_FILE: The input is a list of vectors where the first column is a set ID
and the remaining entries in a row is a list of member IDs in that set (i.e.
this is set major format).


