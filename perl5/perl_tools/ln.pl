#!/usr/bin/perl

require("$ENV{MYPERLDIR}/lib/libfile.pl");

use strict;

my $verbose = 1;
my $dir     = undef;

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
   elsif($arg eq '-l')
   {
      $arg = shift @ARGV;
      open(LIST, $arg) or die("Could not open file list '$arg'");
      while(<LIST>)
      {
         chomp;
         if(/\S/)
         {
            push(@files, $_);
         }
      }
      close(LIST);
   }
   elsif($arg eq '-d')
   {
      $dir = shift @ARGV;
   }
   else
   {
      push(@files,$arg);
   }
}

foreach my $file (@files)
{
   if(defined($dir))
   {
      $file = $dir . '/' . $file;
   }

   if((-f $file) or (-d $file) or (-l $file))
   {
      my $link = &getPathSuffix($file);

      if(not(-l $link) and not(-f $link))
      {
         my $link_command = "ln -s \"$file\" \"$link\"";
         `$link_command`;
         $verbose and $? != 0 and print STDERR "Problems issuing '$link_command'.";
      }
      else
      {
         $verbose and print STDERR "A link with the name '$link' already exists, skipping.\n";
      }
   }
   else
   {
      $verbose and print STDERR "No such file or directory '$file', skipping.";
   }
}

exit(0);

__DATA__
syntax: ln.pl [OPTIONS] FILE

Creates a symbolic link to the file FILE in the current directory.   The link is
given the same name as FILE.

OPTIONS are:

-q: Quiet mode. Turn verbosity off (default is verbose).

-l LIST: Tell the script to read in the list of files from the file LIST.

-d DIR: Supply a directory to prepend to the file names before looking them up (useful
        when used in combination with the -l option).

