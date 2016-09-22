#!/usr/bin/perl

use strict;

my $home = "$ENV{HOME}";
my $dir  = "$ENV{PWD}";


`cd $home; rm -f 1; ln -s $dir 1`;

