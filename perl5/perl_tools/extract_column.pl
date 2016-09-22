#!/usr/bin/perl

use strict;
use warnings;

require "libfile.pl";


# Flush output to STDOUT immediately.
$| = 1;

# GET PARAMETERS

my @flags   = (
                  [    '-s', 'scalar', undef, undef]
                , [    '-d', 'scalar',  "\t", undef]
                , [    '-e', 'scalar',  0, 1]
                , ['--file',   'list', undef, undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags, 1)};

my $help			= $args{'--help'};
my $search			= $args{'-s'};
my $delim           = $args{'-d'};
my $exact           = $args{'-e'};
my $files           = $args{'--file'};
$files              = defined($files) ? $files : ['-'];
my @extra           = @{$args{'--extra'}};

$help = 1 unless($search and $files);

# PRINT HELP
if ($help) {
    print STDOUT <DATA>;
   	exit(0);
}

#print "help: $help\n";
#print "search: $search\n";
#print "delim: $delim\n";
#print "exact: $exact\n";
#print "files: ",join("::",@$files),"\n";
#print "extras: ",join("::",@extra),"\n";

# split search terms:
my @searchArray = split(',',$search);

my @fullHeader = ();
#my %colToFileCol = ();
#my $curCol = 0;
for(my $i = 0; $i < scalar(@$files); $i++){
	my $header = `head -1 $files->[$i]`;
	chomp($header);
	my @heads = split($delim,$header);
	push(@fullHeader,@heads);
	#my $numCols = scalar(@heads);
	#$colToFile{$numCols} = $files->[$i];
	#@colToFileCol{curCol..($curCol+$numCols-1)} = map {$files->[$i].":".($_)} (0..($numCols-1));
	#$curCol += $numCols;
}
#print join("::",@fullHeader),"\n";
#while( my ($k, $v) = each %colToFileCol ) {
#	print "key: $k, value: $v.\n";
#}

my @matchingCols = ();

foreach my $s (@searchArray){
	#print "s: $s\n";
	if($exact){
		push(@matchingCols,grep $fullHeader[$_] eq $s, 0 .. $#fullHeader);
	} else {
		push(@matchingCols,grep { $fullHeader[$_] =~ /$s/ } 0..$#fullHeader);
	}
}
#print "matching cols:",join("::",@matchingCols),"\n";

$_++ for @matchingCols;

if(@matchingCols){
	my $shell;
	if($delim eq "\t"){
		$shell = "paste ".join(" ",@$files)." | cut -f ".join(",", @matchingCols);
	} else {
		$shell = "paste -d $delim ".join(" ",@$files)." | cut -d $delim -f ".join(",", @matchingCols);
	}
	
	#print ">>>",$shell,"<<<\n";
	print `$shell`;

}


__DATA__

syntax: extract_column.pl [OPTIONS] -s SEARCH_STIRNG TAB_FILE(s)

SEARCH_STRING should match one of the headers of TAB_FILE (can be a comma-separated list)
TAB_FILE is any tab-delimited file (or series of files separated by spaces).

OPTIONS are:

-d DELIM: Change the input and output delimiter to DELIM (default <tab>).

