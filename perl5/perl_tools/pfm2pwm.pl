#!/usr/bin/perl

use strict;
use warnings;

#print <>; # header
while(<>) {
	chomp;
	my @tabs = split (/\t/);
	
	my $id=shift (@tabs); 
	if($id =~ /[Pp]/){
		print "$id\t"; 
		print join("\t",@tabs),"\n";
	} else {
		print "$id"; 
		foreach (@tabs) {
			my $x=log2( $_ / 0.25 ); 
			print "\t$x"; 
		} 
		print "\n"
	}
}

exit(0);

sub log2 {
	my $n = shift;
	return log($n)/log(2);
}
