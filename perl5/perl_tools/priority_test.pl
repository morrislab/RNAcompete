#!/usr/bin/perl

use lib "$ENV{SYSBIOPERLLIB}";
use strict;
use warnings;
use Heap::Priority;

my $h = new Heap::Priority;

$h->highest_first;          # set pop() in high to low priority order (default)
# $h->lowest_first;           # set pop() in low to high priority order
# $h->fifo;                   # set first in first out ie a queue (default)
# $h->lifo;                   # set last in first out ie a stack

$h->add('a->b',1); # add an item to the heap
$h->add('b->c',2); # add an item to the heap
$h->add('a->e',3); # add an item to the heap

my $top = $h->pop;       # get an item back from heap
print "Top = $top\n";

my $top = $h->pop;       # get an item back from heap
print "Top = $top\n";

# $h->modify_priority($item, $priority);
# $h->delete_item($item,[$priority]);
# $h->delete_priority_level($priority);
# @levels    = $h->get_priority_levels;
# @items     = $h->get_level($priority);
# @all_items = $h->get_heap;
# $h->raise_error(1);
# my $error_string = $h->err_str;

