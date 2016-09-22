#!/usr/bin/perl

require 'libpwm.pl';


my $pfmfile1 = "/home/hugheslab2/kate/RNAcompete_bakeoff/Predictions/BEEML_ss/RBP_20/pfm.txt";

my $pfm1 = read_pwm($pfmfile1);

print "pfm1:\n";
print_pfm($pfm1);

my $pfm1_trimmed = trim_pwm($pfm1);

print "pfm1 trimmed:\n";
print_pfm($pfm1_trimmed);


my $pfm1_padded = pad_pfm($pfm1,3,'before');

print "pfm1 padded:\n";
print_pfm($pfm1_padded);


my $pfm1_padded2 = pad_pfm($pfm1_padded,2,'after');

print "pfm1 padded 2:\n";
print_pfm($pfm1_padded2);