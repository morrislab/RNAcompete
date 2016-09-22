#!/usr/bin/perl

use strict;
use warnings;

# modified from HTMLTable.pl by JP Vossen <jp@jpsdomain.org>


my %opts;

use Getopt::Std;           # Use Perl5 built-in program argument handler
getopts('blc',\%opts);    # Define possible args.


while( my ($k, $v) = each %opts ) {
	print STDERR "key: $k, value: $v.\n";
}


# my $BorderSize;
# if ($opts{'b'}) {
#    $BorderSize = $opts{'b'};
# } else {
#    $BorderSize = 0;
# }

if($opts{'b'}){
	print "<table>\n";
} else {
	print "<table class=\"noborder\">\n";
}

if ( $opts{'l'} ) {
	my $aline = <>;
	chomp($aline);
	my @arecord = split (/\t/, $aline);
	
	print  "  <tr>\n";
	foreach my $field (@arecord) {
		if($opts{'b'}){
			print  "    <th><h2>$field</h2></th>\n";
		} else {
			print  "    <th class=\"noborder\"><h2>$field</h2></th>\n";
		}
	}
	print "  </tr>\n";
}

while (my $aline = <>) {
    chomp($aline);

	my @arecord = split (/\t/, $aline);

    print  "  <tr>\n";
	foreach my $field (@arecord) {
		my $class = '';
		$class = " class=\"noborder\"" if $opts{'b'};
		my $codefield = $field;
		$codefield = "<code>$field</code>" if $opts{'c'};
		print  "    <td$class>$codefield</td>\n";
	}
    print "  </tr>\n";
    
} 

print "</table>\n";
