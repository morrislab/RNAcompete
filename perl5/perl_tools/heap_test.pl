#!/usr/bin/perl

use lib "$ENV{SYSBIOPERLLIB}";
use strict;
use warnings;

use Heap::Fibonacci;

use Heap::Elem::Num;

my $heap = Heap::Fibonacci->new;

foreach my $i ( 1..100 ) {
    my $elem = Heap::Elem::Num->new($i);
    $heap->add( $elem );
}

while( defined( my $elem = $heap->extract_top ) ) {
    print "Smallest is ", $elem->val, "\n";
}
