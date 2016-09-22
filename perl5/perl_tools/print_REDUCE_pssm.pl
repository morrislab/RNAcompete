#!/usr/bin/perl


use strict;
require "libfile.pl";
require "libpssm.pl";

$| = 1;

my @flags   = (
                 ['--file', 'scalar',   '-', undef]
              );

my %args = %{&parseArgs(\@ARGV, \@flags)};

if(exists($args{'--help'}))
{
   print STDOUT <DATA>;
   exit(0);
}

my $file  = $args{'--file'};

open(my $fh, $file) or die "could not open file '$file'";

my $rPSSM = readMatrix($fh);

print print_pssm_for_REDUCE($rPSSM);

# ===============
# SUBROUTINES

sub print_pssm_for_REDUCE {
	my $rPSSM = shift;
	my $nWidth = scalar @{$rPSSM};
	my $output = '';
	$output .=  "# The four columns must be in the order of A, C, G, and U\n";
	$output .=  "# \tA\tC\tG\tU\n";
	$output .=  "# --------------------------------------------------------\n";
	for (my $i=0; $i<$nWidth; $i++){
		foreach my $b ('A','C','G','U'){
			$output .=  "\t".sprintf("%.3f",$rPSSM->[$i]->{$b});
		}
		$output .= "\n";
	}
	return $output;
}


__DATA__

print_REDUCE_pssm.pl [FILE | < FILE]

Reads a PSSM (usually a PFM) in the format of 4 columns, n lines, where n is
the width of the matrix, and the values are tab delimited, and prints the output
in the format required by the REDUCE suite

TODO: make the delimiter adjustable

   -s:  apply small sample correction TODO: show math here

