#!/usr/bin/perl

use strict;
use warnings;

my $seqIn = $ARGV[0];

my @seqs = ();

while ($seqIn =~ /(.)/g) {
	#print ">> $1\n";
	my $char = $1;
	if($char =~ /[ACGU]/){
		@seqs = _add_char($char,@seqs);
	} elsif ($char eq 'T'){
		@seqs = _add_char('U',@seqs);
	} elsif ($char eq 'Y'){
		my @seqs1 = _add_char('U',@seqs);
		my @seqs2 = _add_char('C',@seqs);
		@seqs = (@seqs1,@seqs2);
	} elsif ($char eq 'W'){
		my @seqs1 = _add_char('A',@seqs);
		my @seqs2 = _add_char('U',@seqs);
		@seqs = (@seqs1,@seqs2);
	} elsif ($char eq 'R'){
		my @seqs1 = _add_char('A',@seqs);
		my @seqs2 = _add_char('G',@seqs);
		@seqs = (@seqs1,@seqs2);
	} elsif ($char eq 'S'){
		my @seqs1 = _add_char('C',@seqs);
		my @seqs2 = _add_char('G',@seqs);
		@seqs = (@seqs1,@seqs2);
	} elsif ($char eq 'B'){
		my @seqs1 = _add_char('C',@seqs);
		my @seqs2 = _add_char('G',@seqs);
		my @seqs3 = _add_char('U',@seqs);
		@seqs = (@seqs1,@seqs2,@seqs3);
	} elsif ($char eq 'D'){
		my @seqs1 = _add_char('A',@seqs);
		my @seqs2 = _add_char('G',@seqs);
		my @seqs3 = _add_char('U',@seqs);
		@seqs = (@seqs1,@seqs2,@seqs3);
	} elsif ($char eq 'H'){
		my @seqs1 = _add_char('A',@seqs);
		my @seqs2 = _add_char('C',@seqs);
		my @seqs3 = _add_char('U',@seqs);
		@seqs = (@seqs1,@seqs2,@seqs3);
	} elsif ($char eq 'V'){
		my @seqs1 = _add_char('C',@seqs);
		my @seqs2 = _add_char('G',@seqs);
		my @seqs3 = _add_char('A',@seqs);
		@seqs = (@seqs1,@seqs2,@seqs3);
	} elsif ($char eq 'N'){
		my @seqs1 = _add_char('A',@seqs);
		my @seqs2 = _add_char('C',@seqs);
		my @seqs3 = _add_char('G',@seqs);
		my @seqs4 = _add_char('U',@seqs);
		@seqs = (@seqs1,@seqs2,@seqs3,@seqs4);
	}
}

foreach (@seqs){
	print $_,"\n";
}


sub _add_char{
	my $char = shift;
	my @ary = @_;
	#print "adding $char to ",_print_ary(\@ary),"\n";
	if (!@ary){ #if it's empty
		#print "empty!\n";
		@ary = ($char);
		return @ary;
	} else {
		foreach (@ary){
			$_ .= $char;
		}
		return @ary;
	}
}

sub _print_ary{
	my $arrayRef = shift;
	my @ary = @{$arrayRef};
	my $seq = ' :: ';
	foreach (@ary){
		$seq .= $_," :: ";
	}
	return $seq . " :: ";
}