#!/usr/bin/perl

use strict;

require "libfile.pl";

$| = 1;

my @flags   = (
                  [    '-q', 'scalar',     0,     1]
                , [    '-p', 'scalar',     0,     1]
                , [    '-n', 'scalar',     0,     1]
                , [    '-k', 'scalar',     0, undef]
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
my $delim        = $args{'-d'};
my $headers      = $args{'-h'};
my $column_value = $args{'-v'};
my $partial_match = $args{'-p'};
my $negation	 = $args{'-n'};
my $file         = $args{'--file'};


#print "partial_match:${partial_match}::\n";
#print "column_value:${column_value}::\n";
#print "negation:${negation}::\n";
#print "key_column:${key_column}::\n";

open(FILE, $file) or die "could not open file '$file'";
while($headers > 0){
	my $line = <FILE>;
	print $line;
	$headers--;
}

while(my $line = <FILE>)
{
	chop($line);
	my @row = split($delim,$line);
	
	#print "test:$column_value::\trow:$row[$key_column-1]::\n";
	
	
	if($partial_match){
		if($negation){
			if ($row[$key_column] !~ /$column_value/){
				print $line,"\n";
			}
		} else {
			if ($row[$key_column] =~ /$column_value/){
				print $line,"\n";
			}			
		}
	} else { # exact match
		if($negation){
			if ($row[$key_column] ne $column_value){
				print $line,"\n";
			}
		} else {
			if ($row[$key_column] eq $column_value){
				print $line,"\n";
			}		
		}
	}
}

__DATA__

filter_rows.pl [FILE | < FILE]

   Prints the set of columns for a given row that have a certain value.
   For example, you can give it a GO file and specify a row you're
   interested in, and it will tell you all the GO categories that are '1'
   for that row/gene.
   
   Note: assumes first line is header! use -h 0 to say no header lines

   -k <num>:    The key column (default: 0)
   -v <value>:  Value to find in order to print (default: 1)

