#!/usr/bin/perl

use strict;

my $verbose = 1;
my @files;

while(@ARGV)
{
   my $arg = shift @ARGV;
   if($arg eq '--help')
   {
      print STDOUT <DATA>;
      exit(0);
   }
   elsif(-f $arg)
   {
      push(@files, $arg);
   }
   elsif($arg eq '-q')
   {
      $verbose = 0;
   }
   else
   {
      die("Invalid argument '$arg'");
   }
}

if($#files == -1)
{
   push(@files,'-');
}

print "digraph G {\n";
foreach my $file (@files)
{
   open(FILE, $file) or die("Could not open file '$file' for reading");
   while(<FILE>)
   {
      my ($node,$left,$right,$score) = split;
      if($node =~ /node/i)
      {
         print "\t$left -> $node;\n",
               "\t$right -> $node;\n";
      }
   }
}
print "}\n";

exit(0);


__DATA__
syntax: SCRIPT.pl [OPTIONS]

OPTIONS are:

-q: Quiet mode (default is verbose)




