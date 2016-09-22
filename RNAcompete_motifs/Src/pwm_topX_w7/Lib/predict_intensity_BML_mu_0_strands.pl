#!/usr/bin/perl

use strict;
use warnings;

my $e = 2.718281828;

my $seqfile = shift (@ARGV);
my $infile = shift (@ARGV);

die unless (defined ($infile));

open (F, $infile) || die "couldn't open $infile";
$_ = <F>;
my @tabs = split (/\t/);
my $mu = shift (@tabs);
$mu =~ s/# mu =\s+//;
$mu = 0;

my $len = 0;
my %matrix = ();

while(<F>)
{
   chomp;
   my @tabs = split (/\t/);

   shift (@tabs);
   $matrix{"$len	A"} = $tabs[0];
   $matrix{"$len	C"} = $tabs[1];
   $matrix{"$len	G"} = $tabs[2];
   $matrix{"$len	U"} = $tabs[3];

   $len++;
}
close (F) || die;

open (F, $seqfile) || die;
$_ = <F>;
print;

while(<F>)
{
   chomp;
   my @tabs = split (/\t/);

   my $tf = shift (@tabs);
   my $type = shift (@tabs);
   my $seq = shift (@tabs);
   my $answer = shift (@tabs);
   my $probeid = shift (@tabs);

   my @seq = split (//, $seq);

#   warn "LINE |@seq|\n";
#   warn "$len\n";

   #score both strands using BEEML method
   my $score = 0;
   for (my $i=0; $i < scalar @seq - $len + 1; $i++) {

      #score current position on forward strand
      my $Ei = 0;
#      print "FOR:";
      for (my $j=0; $j < $len; $j++) {
          my $pos = $i+$j;
          my $val = $matrix{"$j	$seq[$pos]"};

          $Ei += $val;
          my $s=$seq[$pos];
#	  print "$s";
      }
#      print "\n";
      my $p_f = ($e**-$Ei)/($e**-$mu + $e**-$Ei);

      $score += $p_f;
   }

   print "$tf\t$type\t$seq\t$score\t$probeid\n";
#   print "@seq\n";
#   print "@rev_seq\n";
}

exit(0);


