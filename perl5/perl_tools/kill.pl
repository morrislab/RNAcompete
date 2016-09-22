#!/usr/bin/perl

use strict;

my $verbose = 1;
my @pids;

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
   elsif($arg eq '-')
   {
      while(<STDIN>)
      {
         if(/\S/)
	 {
	    chop;
	    my @tokens = split;
	    foreach my $token (@tokens)
	    {
               if($token =~ /^\s*(\d+)\s*$/)
	       {
                  push(@pids,$1);
	       }
	    }
	 }
      }
   }
   elsif($arg =~ /^\s*(\d+)\s*$/)
   {
      push(@pids,$1);
   }
   else
   {
      die("Invalid argument '$arg'");
   }
}

foreach my $pid (@pids)
{
   my $kill = "kill -9 $pid";
   $verbose and print STDERR "Killing process '$pid'...";
   `$kill`;
   $verbose and print STDERR " done.\n";
}

exit(0);

__DATA__
syntax: kill.pl [OPTIONS] PID1 [PID2 ...]

Kills a list of processes specified with their process id's.

PIDi - a process identifier.  If this equals a dash '-' then the script will read process
       id's from the standard input.

OPTIONS are:

-q: Quiet mode (default is verbose)



