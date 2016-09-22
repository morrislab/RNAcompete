#!/usr/bin/perl

# Numbers lines in a file.
# Equivalent to:   awk '{ print FNR "\t" $0 }' FILENAME
# But with more options

# To number your file with awk, you can run:
# *** cat YOURFILE | awk '{ print FNR "\t" $0 }'

use strict;

my $arg='';
my $delim="\t";
my $i=1;
my $after=0;
my $neg = '';
my $inc=1;
my $file='-';

while(@ARGV)
{
   $arg = shift @ARGV;
   if($arg =~ /^-([-]*\d)/)
   {
       # Start counting from the number they pass in:
       $i=int($1);
   }
   elsif($arg eq '-s') {
       $i = shift @ARGV;
   }
   elsif($arg eq '-d')
   {
       $delim = shift @ARGV;
   }
   elsif($arg eq '-a')
   {
       $after=1;
   }
   elsif($arg eq '-n')
   {
       $neg = '-';
   }
   elsif($arg eq '-i')
   {
       $inc = shift @ARGV;
   }
   elsif(-f $arg)
   {
      $file = $arg;
   }
}

open(FILE, $file) or die("Could not open file '$file'");

# Add line numbers to the file.
while(<FILE>)
{ 
   chop;
   if(not($after))
     { print STDOUT $neg, "$i", $delim, "$_\n"; }
   else
     { print STDOUT "$_", $delim, $neg, "$i\n"; }

   $i += $inc;
}

close(FILE);
