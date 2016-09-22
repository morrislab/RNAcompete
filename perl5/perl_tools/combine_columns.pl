#!/usr/bin/perl

use strict;

my $verbose = 1;
my $boolean = 0;
my $logic   = 'and';
my @files;

while(@ARGV)
{
   my $arg = shift @ARGV;
   if($arg eq '--help')
   {
      print STDOUT <DATA>;
      exit(0);
   }
   elsif($arg eq '-q')
   {
      $verbose = 0;
   }
   elsif($arg eq '-or')
   {
      $boolean = 1;
      $logic   = 'or';
   }
   elsif(-f $arg)
   {
      push(@files, $arg);
   }
   else
   {
      die("Invalid argument '$arg'");
   }
}

# Read in all the column fields from every file.
my %fields;
foreach my $file (@files)
{
   open(FILE,$file) or die("Could not open file '$file'");
   $_ = <FILE>; chop;
   my ($key,@header) = split(/\t/);
   foreach my $field (@header)
   {
      $fields{$field} = 1;
   }
   close(FILE);
}
my @fields = sort {$a cmp $b} keys(%fields);

foreach my $file (@files)
{
   open(FILE,$file) or die("Could not open file '$file'");
   $_ = <FILE>; chop;
   my ($key,@header) = split(/\t/);
   while(<FILE>)
   {
      if(/\S/)
      {
	 chop;
         my ($key,@tuple) = split(/\t/);
         for(my $i=0; $i<=$#tuple; $i++)
	 {
	    $entry{$header[$i]} = $tuple[$i];
	 }

	 print $key;
	 foreach my $field (@fields)
	 {
	    if(exists($entry{$field}))
	    {
	       if($boolean)
	       {
	       }
	    }
	    else
	    {
	       if($boolean)
	       {
		  print "\t0";
	       }
	    }
	 }
      }
   }
   close(FILE);
}

exit(0);


__DATA__
syntax: combine_columns.pl [OPTIONS]

OPTIONS are:

-q: Quiet mode (default is verbose)

-or: Tab file is a boolean matrix and the columns should be logically ORed.



