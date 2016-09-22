#!/usr/bin/perl

require "libfile.pl";

use strict;

my @files;
my $verbose=1;
my $max_files_per_rm=100;
my @rm_options;
my @removed_files;


while(@ARGV)
{
  my $arg = shift(@ARGV);

  if($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }
  elsif($arg eq '-q')
  {
    $verbose = 0;
  }
  elsif($arg eq '-i')
  {
    $arg = shift @ARGV;
    my $fp;
    if($arg eq '-')
    {
      $fp = \*STDIN;
    }
    else
    {
      open(LIST,$arg) or die("Could not open the file list '$arg': $!");
      $fp = \*LIST;
    }
    while(<$fp>)
    {
      if(/\S/)
      {
        chomp;
	if(-f $_)
	{
          push(@files,$_);
	}
      }
    }
    close($fp);
  }
  elsif(-f $arg)
  {
    push(@files,$arg);
  }
  elsif(not(-d $arg) and not(-l $arg))
  {
    push(@rm_options,$arg);
  }
}

while(@files)
{
  my @rm_files=();
  for(my $f=0; $f<$max_files_per_rm and $#files>=0; $f++)
  {
    my $file = shift @files;
    if(&isCodeFile($file))
    {
      push(@rm_files,$file);
    }
  }
  &do_remove($verbose,join(' ', @rm_options),@rm_files);
  @removed_files = (@removed_files,@rm_files);
}

my $num_removed = $#removed_files+1;

if($num_removed>0)
{
  $verbose and print STDERR "Removed $num_removed source code file(s): ", join(" ",@removed_files), "\n";
}
exit(0);

sub do_remove
{
  my $verbose = shift;
  my $rm_options = shift;
  my @files = @_;
  my $files = join(' ', @files);
  my $rm_cmd = "rm $rm_options $files";
  # print STDERR "'$rm_cmd'\n";
  `$rm_cmd`;
}

__DATA__
syntax: rmcode.pl [OPTIONS] FILE1 [FILE2 FILE3 ...]

Removes only files that have a source code extension such as:

  *.c *.C *.cc *.cpp *.h *.y *.pl *.pm *.py etc.,

OPTIONS are:

-q: quiet mode (default is verbose)
-i FILE: supply list of files to remove from the list in FILE.  If file equals '-' the
         list is read from standard input.

