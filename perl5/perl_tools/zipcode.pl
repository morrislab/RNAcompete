#!/usr/bin/perl

use strict;
require "libfile.pl";

if($#ARGV==-1)
{
  print STDOUT <DATA>;
  exit(0);
}

my @paths=();
my $input_dirs = '';
my $archive='';
my $include_makefiles=1;
my $include_rcsfiles=1;
my $follow_links=0;
my $verbose=1;
my $remove=0;
my $update=0;
my $time_index=9;
my $list_out='';
my $input_list='';
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
    $follow_links = 1;
  }
  elsif($arg eq '-m')
  {
    $include_makefiles = 0;
  }
  elsif($arg eq '-r')
  {
    $include_rcsfiles = 0;
  }
  elsif($arg eq '-i')
  {
    $input_list = shift @ARGV;
  }
  elsif($arg eq '-d')
  {
    $input_dirs = shift @ARGV;
  }
  elsif($arg eq '-o')
  {
    $list_out = shift @ARGV;
  }
  elsif($arg eq '-remove')
  {
    $remove = 1;
  }
  elsif(length($archive)<1)
  {
    $archive = $arg;
  }
  elsif(-d $arg or -f $arg)
  {
    push(@paths,$arg);
  }
}

my $archive_time;
if(length($archive)<1)
{
  die("Please supply an archive as an argument.\n");
}
elsif(not(-f $archive))
{
  $update = 0;
}
else
{
  my @stats = stat($archive);
  $archive_time = $stats[$time_index];
  $update = 1;
}

my @files_tmp;
if(length($input_dirs)>0)
{
  my $fp;
  if($input_dirs eq '-')
  {
    $fp = \*STDIN;
  }
  else
  {
    open(LIST,$input_dirs) or die("Could not open the directory list '$input_dirs': $!");
    $fp = \*LIST;
  }
  while(<$fp>)
  {
    if(/\S/)
    {
      chop;
      push(@paths,$_);
    }
  }
  close($fp);
  @files_tmp = &getAllFiles(@paths);
}
elsif($#paths>=0)
{
  @files_tmp = &getAllFilesRecursively($follow_links,@paths);
}

my @files = ();

foreach my $file (@files_tmp)
{
  if(-f $file)
  {
    my @stats = stat($file);
    my $file_time = $stats[$time_index];
    if(not($update) or $file_time>$archive_time)
    {
      if(&isCodeFile($file))
      {
        push(@files,$file);
        $verbose and print STDERR "Will zip '$file'.\n";
      }
      elsif($include_makefiles and $file =~ /[Mm]akefile/)
      {
        push(@files,$file);
        $verbose and print STDERR "Will zip '$file'.\n";
      }
      elsif($include_rcsfiles and $file =~ /,v$/)
      {
        push(@files,$file);
        $verbose and print STDERR "Will zip '$file'.\n";
      }
    }
  }
}

if(length($input_list)>0)
{
  @files = ();
  my $fp;
  if($input_list eq '-')
  {
    $fp = \*STDIN;
  }
  else
  {
    open(LIST,$input_list) or die("Could not open the directory list '$input_list': $!");
    $fp = \*LIST;
  }
  while(<$fp>)
  {
    if(/\S/)
    {
      chop;
      push(@files,$_);
    }
  }
  close($fp);
}

my %files;
foreach my $file (@files)
{
  $files{$file} = 1;
}
@files = keys(%files);

if(-f $archive and $#files>=0)
{
  `rm $archive`;
}

my $num = $#files+1;
$verbose and print STDERR "Zipping $num files to '$archive'.\n";
# system($zip);
if($num>0)
{
  open(ZIP,"| zip -@ $archive") or die("Could not execute zip command.");
  foreach my $file (@files)
  {
    print ZIP "$file\n";
  }
  close(ZIP);
  $verbose and print STDERR "Done zipping $num files to '$archive'.\n";
}

if(length($list_out)>0)
{
  $verbose and print STDERR "Writing file list to '$list_out'...";
  open(LIST,">$list_out") or die("Could not open list file '$list_out': $!\n");
  foreach my $file (@files)
  {
    print LIST "$file\n";
  }
  close(LIST);
  $verbose and print STDERR " done.\n";
}

if($remove)
{
  my $rem = "rm -f " . join(" ",@files);
  $verbose and print STDERR "Removing the files...";
  `$rem`;
  $verbose and print STDERR " done.\n";
}

__DATA__
syntax: zipcode.pl [OPTIONS] ARCHIVE PATH1 [PATH2 PATH3 ...]

Recursively zip up all source code files from the paths.  Everything ending in
  an extension that looks like code will be included:

    *.c *.h *.cc *.cpp *.C *.hh *.m *.S *.pl *.py *.y etc.,

ARCHIVE: Name of the archive to create
PATHs: Directories or files to include in the archive.  Directories are
  recursively expanded.

OPTIONS are:

 -l: Follow symbolic links while recursing (default does not follow).
 -m: do *not* include makefiles (Makefile or makefile files).  Default includes them.
 -d FILE: Supply a file containing directories on each line.  Will not recurse on these.
          If FILE equals '-' will read the list from standard input.
 -i FILE: Supply a file containing file names relative to where zipcode.pl called.
          If FILE equals '-' will read the list from standard input.
 -o FILE: write a list of files to FILE that were included in archive.
 -q: quiet mode.
 -remove: removes source files after being zipped.
 -r: do *not* include RCS files (default includes *,v files).

