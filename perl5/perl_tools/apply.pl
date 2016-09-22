#!/usr/bin/perl

require "libfile.pl";

use strict;

my $arg;
my $verbose=0;
my @tmp_files;
my $recursive=0;
my $cmd='';
my $collectOptions=0;
my $ignore = 0;
my @options;
my $overWrite = 0;
my $test = 0;
my $stdout=1;
my $outExt='';
my $replExt=0;
my $follow_links=0;
my $input_list='';
my $input_dirs='';
my $in_pipe = 1;
my $print_file = 0;
my $only='';
my $exclude='';
my $batch=0;
my $names_stdin=0;

while(@ARGV)
{
  $arg = shift @ARGV;

  # See if we're collecting options for the command
  if($collectOptions)
  {
    # See if the user has ended the option collecting
    if($arg eq '--')
    {
      $collectOptions = 0;
    }
    else
    {
      push(@options,$arg);
    }
  }

  # The special argument '--' signifies to start collecting options
  elsif($arg eq '--')
  {
    $collectOptions = 1;
  }

  elsif($arg eq '--help')
  {
    print STDOUT <DATA>;
    exit(0);
  }

  elsif($arg eq '-t')
  {
    $test = 1;
  }

  elsif($arg eq '-v')
  {
    $verbose = 1;
  }

  elsif($arg eq '-w')
  {
    $overWrite = 0;
    $stdout = 0;
    $outExt = shift @ARGV;
    if($outExt =~ /^\.([^.]+)$/)
    {
      $outExt = $1;
      $replExt = 1;
    }
  }

  elsif($arg eq '-o')
  {
    $overWrite = 1;
    $stdout = 0;
  }

  elsif($arg eq '-d')
  {
    $input_dirs = shift @ARGV;
  }

  elsif($arg eq '-i')
  {
    $input_list = shift @ARGV;
  }

  elsif($arg eq '-ig')
  {
    $ignore = 1;
  }

  elsif($arg eq '-R')
  {
    $recursive = 1;
  }

  elsif($arg eq '-batch')
  {
    $batch = 1;
  }

  elsif($arg eq '-names')
  {
    $names_stdin = 1;
  }

  elsif($arg eq '-l')
  {
    $follow_links = 1;
  }

  elsif($arg eq '-only' or $arg eq '-suffix')
  {
    $only = shift @ARGV;
  }

  elsif($arg eq '-x')
  {
    $exclude = shift @ARGV;
  }

  elsif($arg eq '-np' or $arg eq '-arg')
  {
    $in_pipe = 0;
  }

  elsif($arg eq '-p')
  {
    $print_file = 1;
  }

  elsif(length($cmd)<1)
  {
    $cmd = $arg;
  }

  else
  {
    push(@tmp_files, $arg);
  }
}

if(length($input_list)>0)
{
  my $fp;
  if($input_list eq '-')
  {
    $fp = \*STDIN;
  }
  else
  {
    open(LIST,$input_list) or die("Could not open the file list '$input_list': $!");
    $fp = \*LIST;
  }
  while(<$fp>)
  {
    if(/\S/)
    {
      chomp;
      push(@tmp_files,$_);
    }
  }
  close($fp);
}

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
      chomp;
      if($recursive)
      {
        push(@tmp_files, &getAllFilesRecursively($follow_links,($_)));
      }
      else
      {
        push(@tmp_files, &getAllFiles(($_)));
      }
    }
  }
  close($fp);
}

if(length($cmd)<1)
{
  print STDOUT <DATA>;
  exit(1);
}

if($#options>=0)
{
  $cmd .= ' '. join(' ', @options);
}

my $call='';
my $inFile='';
my $tmpFile='';
my $randomNumber=0;
my @tree=();
my $result;
my $outFile;

if($recursive)
{
  foreach $inFile (@tmp_files)
  {
    push(@tree, &getAllFilesRecursively($follow_links,($inFile)));
  }
  @tmp_files = @tree;
}

# Filter the list of files
my @files;
foreach $inFile (@tmp_files)
{
  if(not(-f $inFile))
  {
    # print STDERR "Argument -->$inFile<-- is not a regular file, skipping.\n";
  }
  elsif((length($only)<1 or $inFile =~ /$only$/) and
        not(length($exclude)>0 and $inFile =~ /$exclude$/))
  {
    push(@files,$inFile);
  }
}

my $callBase;

if($batch)
{
  if($names_stdin)
  {
    $verbose and print STDERR "Executing: '$cmd' passing in files: " . join(" ",@files) . "\n";
    # $call = "echo " . join(" ", @files) . " | $cmd";
    open(PIPE,"| $cmd");
    print PIPE join("\n", @files);
    close(PIPE);
    $verbose and print STDERR "Done executing.\n";
  }
  else
  {
    $call = "$cmd " . join(" ", @files);
    $verbose and print STDERR "Executing: '$call'\n";
    print STDOUT `$call`;
    $verbose and print STDERR "Done executing.\n";
  }
}
else
{
  foreach $inFile (@files)
  {
    $randomNumber = int(rand()*100000);
    $tmpFile = '/tmp/' . &getPathSuffix($0) . '.' . $randomNumber . '.tmp';

    $call = $in_pipe ? "cat $inFile | $cmd" : "$cmd $inFile";
  
    $verbose and print STDERR "Executing: $call...";

    if($stdout)
    {
      if($print_file)
      {
        print "Applied to '$inFile' produced:\n";
      }
      print `$call`;

      $verbose and print STDERR " done.\n";
    }
  
    else
    {
      $result = system("$call > $tmpFile");
      if(not($result) or $ignore)
      {
        $verbose and print STDERR " success.\n";
  
        if($overWrite)
        {
          $outFile = $inFile;
          if($verbose)
            { print STDERR "Overwriting original file $outFile..."; }
        }
        else
        {
          if($replExt)
          {
            if($inFile =~ /\.[^\.]*$/)
            {
              $outFile = $inFile;
              $outFile =~ s/\.[^\.]*$//;
              $outFile = $outFile . '.' . $outExt;
            }
            else
            {
              $outFile = $inFile . '.' . $outExt;
            }
          }
          else
          {
            $outFile = $inFile . '.' . $outExt;
          }
          $verbose and print STDERR "Writing file $outFile...";
        }
  
        $call = "mv $tmpFile $outFile";
  
        if(not($test))
          { $result = system($call); }
        else
          { $result = system("rm $tmpFile"); }

        $verbose and print STDERR " done.\n";
      }
      else
      {
        $result = system("rm $tmpFile");
        if($verbose)
        {
          print STDERR " failure.\n";
          print STDERR "Leaving original file alone.\n";
        }
      }
    }
  }
}

exit(0);

my $name = &getPathSuffix($0);

__DATA__

syntax: apply.pl [OPTIONS] CMD [-- CMD_OPTIONS --] FILE1 [FILE2 FILE3 ...]

Calls CMD on each file in the list and overwrites the old file
with the new file resulting from the call.

CMD is any unix command that can be used in a bidirectional pipe.
For each file in the list, CMD < FILE is called and the standard
output of CMD is collected. Note: CMD must be in the users path or
must be absolute.

CMD_OPTIONS are options to be passed to the command CMD
being called.  These must be bracketed by the special double-dash
symbol, --, on either side of the options list.

FILE1, FILE2, FILE3 etc are any text file.

OPTIONS are:

-v: Turn verbose mode on (default is quiet)
-t: Test mode: don't actually overwrite the files, just execute
    CMD on each file, but ignore the results.

-w EXT: Write the output from each file to a new file named the same
    as the original file with the extension .EXT appended to the
    name.  If EXT is of the form .SFX, the script will attempt to replace
    each input file's original extension with .SFX.  For example
    foo.bar would generate output foo.SFX instead of foo.bar.SFX.
    
-o: Overwrite the original files with the output files generated
    from calling CMD (default is to write all output to stdout
-ig: Ignore exit status of CMD.  Default is to inspect exit status
    of CMD and assume 0 is success while non-zero is failure.  If
    CMD returns non-zero, then no result is produced for the file
    that produces non-zero exit status.  If -o is set, then the
    original file is not overwritten with the results.
-R: Recursive mode - directories expanded and all files processed
    (default is non-recursive)

-only SUFF: Only applies the command to files that end with the SUF pattern.

-x SUFF: Exclude filenames ending with SUFF.

-l: Follow links (default does not follow links)

-np: No pipe: pass files in as an argument to the command instead of through a pipe.

-arg: same as -np option.

-i FILE: read the list of files from a list in FILE.  If FILE equals '-' then takes
         the list from standard input.
-d FILE: reads a list of directories from FILE. If FILE equals '-' it reads the list
         from standard input.

-batch: Apply the command passing all the found files as one large argument list to
        the command.  The result of this batch application is printed to standard output.
	Note that options like -w and -o do not apply in this case.  Also, this assumes
	the command can take the files in as arguments (not pipes) of course.

-names: Pass the file names into the command's standard input instead of the file
        contents.  When used with -batch it passes all the file names in at once.
