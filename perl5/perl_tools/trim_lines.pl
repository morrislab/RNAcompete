#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;

my $len = undef;
my $trimOffFront = 0; # by default, we trim off the END, not the front

sub printUsage() {
    print STDOUT <DATA>;
    exit(0);
}

GetOptions("help|?|man" => sub { printUsage(); }
	   , "length|n=i" => \$len
	   ) or printUsage();

if (!defined($len)) {
    die "Error in trim_lines.pl parameters: you must pass in a length (-n=10 , for example).\n";
}

while (my $line = <>) {
    chomp($line);
    print substr($line, 0, $len) . "\n";
}

exit(0);

__DATA__

trim_lines.pl -n LENGTH [< INPUT_FILE]

***** NOTE: DEPRECATED. trunc.pl seems to be a better version of this. ****
***** NOTE: DEPRECATED. trunc.pl seems to be a better version of this. ****
***** NOTE: DEPRECATED. trunc.pl seems to be a better version of this. ****
***** NOTE: DEPRECATED. trunc.pl seems to be a better version of this. ****
***** NOTE: DEPRECATED. trunc.pl seems to be a better version of this. ****
***** NOTE: DEPRECATED. trunc.pl seems to be a better version of this. ****
***** NOTE: DEPRECATED. trunc.pl seems to be a better version of this. ****

So do not use this unless you really do not want to use trunc.pl!

Trims lines to length LENGTH. -n=3 would trim every line to three characters.

Trims off the END of a line by default. Thus, the earlier characters on the line are preserved.

I wrote this script because the sed command (with parentheses and \1) for trimming lines is actually very slow.
This perl version is at least twice as fast.

Note: trunc.pl seems to be a better version of this script!

