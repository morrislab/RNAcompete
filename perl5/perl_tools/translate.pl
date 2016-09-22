#!/usr/bin/perl

$file = "/home/matt/Src/perl/Tools/trans.dat";
open(INFO, $file);

while ($string = <INFO>)
{
   $string =~ /^\s*([ACGT]{3})\s+(\S+)/ || die "Bad trans.dat line $string\n";
   $trans{$1} = $2;
}

close(INFO);

while (<>) {
   chomp;
   @tabs = split (/\t/);
   $id = shift (@tabs);
   $dna_string = shift (@tabs);
   $dna_string =~ tr/acgt/ACGT/;
   print "$id\t";
   while ($dna_string =~ s/(^[ACGT]{3})//i)
   {
      print "$trans{$1}";
   }
   print "\n";
}
