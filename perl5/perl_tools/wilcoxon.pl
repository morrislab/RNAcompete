#!/usr/bin/perl

# Version History
#   v1.1    2007-08-10: Updated help information.
#   v1.0    Original version.


use strict;
use warnings;

use Data::Dumper;

# usage: wilcoxon list1 list2

my $verbose=0;

my @argv;
while (my $t=shift) {
  push @argv,$t;
}

if (@argv!=2) {
  printf STDERR "usage: wilcoxon.pl rankFile1 rankFile2\n\n";
  printf STDERR "The wilcoxon.pl script reports Wilcoxon (Mann-Whitney) z-scores for\n";
  printf STDERR "corresponding lines in rankFile1 and rankFile2. Each line in the rank\n";
  printf STDERR "files corresponds to a single query. A positive z-score indicates the\n";
  printf STDERR "query result in rankFile1 was better than the corresponding query\n";
  printf STDERR "result in rankFile2.\n\n";
  exit;
}

# print scalar(@argv)."\n";
my $p2=@argv/2*0;
my $p3=@argv/2*1;

#while($p3<@argv) {}
my $list1=$argv[$p2++];
my $list2=$argv[$p3++];


open(F1,"<$list1") || die "file $list1 not found.\n";
open(F2,"<$list2") || die "file $list2 not found.\n";
my $done=0;

while (!$done) {

my %pathway;
my @list1;
my @list2;
$pathway{'A'}="1";
my @Z;
my $t;

my $done2=0;
do {
  $t=<F1>;
exit if (!$t);
  chomp $t;
  $done2=1 if (!($t =~ /^#/) && length($t)>2);
} while (!$done2);

my @t=split "\t", $t;

for (my $i=0;  $i<$t[-1];  $i++) {
  $list1[$i]='x';
}
for (my $i=0;  $i<@t-2;  $i++) {
  $list1[$t[$i+2]]='A';
}



$done2=0;
{
do {
  $t=<F2>;
  chomp $t;
  $done2=1 if (!($t =~ /^#/) && length($t)>2)
} while (!$done2);
my @t=split "\t", $t;

for (my $i=0;  $i<$t[-1];  $i++) {
  $list2[$i]='x';
}
  
for (my $i=0;  $i<@t-2;  $i++) {
  $list2[$t[$i+2]]='A';
}
}
print scalar(@list1)." ".scalar(@list2)."\n" if ($verbose>0);

while(@list2-@list1>0) {
  push @list1,"-";
}
while(@list1-@list2>0) {
  push @list2,"-";
}
print scalar(@list1)." ".scalar(@list2)."\n" if ($verbose>0);

print "@list1\n@list2\n" if ($verbose>1);

my @x;
my @y;
my $n=0;

for (my $i=0;  $i<@list1;  $i++) {
  if (exists $pathway{$list1[$i]} && exists $pathway{$list2[$i]}) {
    $n++;
    push @x, $n+0.5;
    push @y, $n+0.5;
    $n++;
  } else {
    if (exists $pathway{$list1[$i]}) {
      $n++;
      push @x, $n;
    }
    if (exists $pathway{$list2[$i]}) {
      $n++;
      push @y, $n;
    }
  }
}

print "@x\n@y\n" if ($verbose>1);
print "scalar(x)=".scalar(@x)." scalar(y)=".scalar(@y)."\n" if ($verbose>0);


my $R=0;
foreach (@x) {
  $R+=$_;
}
print "R=$R\n" if ($verbose>0);

my $U=(@x*@y+(1/2*@x*(@x+1)))-$R;
print "U=$U\n" if ($verbose>0);

my $m=(@x*@y)/2;
print "m=$m\n" if ($verbose>0);

my $s=sqrt((@x*@y*(@x+@y+1))/12);
print "s=$s\n" if ($verbose>0);

my $Z=0;
$Z=($U-$m)/$s if ($s>0);
printf "Z=%f\n", $Z if ($verbose>0);

push @Z,$Z;

@Z=sort {$a <=> $b} @Z;
foreach (@Z) {
  printf "%8.5f\n", $_ if ($verbose>0);
}

printf "%f\n",$Z[scalar(@Z)/2-1] if ($verbose==0);

}

close(F1);
close(F2);
