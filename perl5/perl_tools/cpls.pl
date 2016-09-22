#!/usr/local/bin/perl

##############################################################################
##############################################################################
##
## skeleton.pl
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
                  [    '-q', 'scalar',     0,     1]
                , [    '-d', 'scalar',  "\t", undef]
                , ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

if(exists($args{'--help'})) {
   print STDOUT <DATA>;
   exit(0);
}

my $verbose = not($args{'-q'});
my $passify = 2;
my $file    = $args{'--file'};
my @extra   = @{$args{'--extra'}};

my ($old_dir, $new_dir) = (undef, undef);
if(scalar(@extra) == 1) {
   $new_dir = $extra[0];
   $old_dir = './';
}
elsif(scalar(@extra) == 2) {
   ($old_dir, $new_dir) = @extra;
}
else {
   die("Must supply a new destination directory or both an old and new.");
}


my $filep = &openFile($file);
my @files = <$filep>;
my $n = scalar(@files);
my $f = 0;
foreach my $file (@files) {
   $f++;
   chomp($file);
   if($file =~ /\S/) {
      my $old_path = $old_dir . '/' . $file;
      if(-f $old_path) {
	 my $new_path = $new_dir . '/' . $file;
	 my @p = split('/',$new_path);
	 my @new_subdir = @p;
	 pop @new_subdir;
	 my $new_subdir = join('/',@new_subdir);
	 if(not(-d $new_subdir)) {
	    print STDERR "Creating directory $new_subdir\n";
	    `mkdir -p $new_subdir`;
	 }
	 if(not(-f $new_path)) {
            if($f % $passify == 0) {
	       my $perc_done = sprintf("%.1f",$f / $n * 100);
	       print STDERR $perc_done . '%. ' . "From ==> $old_path\n";
	       print STDERR $perc_done . '%. ' . "  To ==> $new_subdir\n"; 
            }
	    `cp $old_path $new_subdir`;
	 }
      }
      else {
	 print STDERR "Does not exist: $old_path\n";
      }
   }
}
close($filep);

exit(0);

__DATA__
syntax: skeleton.pl [OPTIONS]

OPTIONS are:

-q: Quiet mode (default is verbose)

-k COL: Set the key column to COL (default is 1).

-d DELIM: Set the field delimiter to DELIM (default is tab).



