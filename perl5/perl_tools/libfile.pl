require "libstd.pl";

use strict;

sub fileFriendlyName {
   my ($name) = @_;

   $name =~ s/\//_/g;
   $name =~ s/\\/_/g;
   $name =~ s/\"/_/g;
   $name =~ s/\'/_/g;
   $name =~ s/\(/_/g;
   $name =~ s/\)/_/g;
   $name =~ s/\[/_/g;
   $name =~ s/\]/_/g;
   $name =~ s/\{/_/g;
   $name =~ s/\}/_/g;
   $name =~ s/\s+/_/g;

   $name =~ s/_[_]+/_/g;

   return $name;
}

# Reads a specific column ONLY. Column indices start at ZERO (not 1). Returns a
# REFERENCE. So if you want to use it, you say: my @resultColumnArray =
# @{readFileColumn(filename, 1, "\t")}; You then get just that ONE column that
# you wanted out of the file. Default values: read from standard input, read
# the first column, and use tabs as delimiters
sub readFileColumns {
   my ($fileName, $columns, $delim) = @_;
   $fileName = defined($fileName) ? $fileName : '-'  ;
   $columns  = defined($columns) ?  $columns  : [0]  ; # 0 == first column
   $delim    = defined($delim) ?    $delim    : "\t" ;
   my @tuples = ();
   my $file = &openFile($fileName);
   if (defined($file)) {
	 while(my $line = <$file>) {
	   my @tokens = split($delim, $line);
	   chomp($tokens[$#tokens]);
	   my @tuple;
	   foreach my $col (@{$columns}) {
         push(@tuple, $tokens[$col]);
	   }
	   push(@tuples, \@tuple);
	 }
	 close($file);
   }
   return \@tuples;  # <-- Returns a REFERENCE
}

# Arg 1: filename (reads from STDIN if given a - or no filename at all)
# Arg 2: column index (starting from 0. zero == first column)
# Arg 3: column delimiter (Default: tab)
# Returns: a reference to an array.
# If you want to use it, you say:
# my @resultColumnArray = @{readFileColumn(filename, 1, "\t")};
# You then get just that ONE column that you wanted out of the file. Default
# values: read from standard input, read the first column, and use tabs as
# delimiters.
sub readFileColumn {
   my ($fileName, $column, $delim) = @_;
   $fileName = defined($fileName) ?  $fileName : '-' ;
   $column   = defined($column)   ?  $column   : 0   ; # 0 == first column
   $delim    = defined($delim)    ?  $delim    : "\t";
   my @lines = ();
   my $file = &openFile($fileName);
   if (defined($file)) {
	 while(my $line = <$file>) {
	   my @tuple = split($delim, $line);
	   chomp($tuple[$#tuple]);
	   push(@lines, $tuple[$column]);
	 }
	 close($file);
   }
   return \@lines; # <-- Returns a REFERENCE
}


# Arg 1: file HANDLE (not a filename)
# Arg 2: number of lines to read. Read NUM lines only from a file handle, then
# stop If numLinesToRead is less than the number of lines in the file, then
# just reads the entire file
# Returns: a REFERENCE to an array.
sub readNumLinesFromFile($$) {
   my ($filehandle, $numLinesToRead) = @_;
   if ($numLinesToRead < 0) { die "ERROR: trying to read fewer than zero lines from a file!"; }
   my $numLinesReadSoFar = 0;
   my @lines = ();
   while(my $line = <$filehandle>) {
	 if ($numLinesReadSoFar >= $numLinesToRead) {
	   last; # breaks out of the loop if we've read as many lines as we wanted to
	 }
	 chomp($line);
	 push(@lines, $line);
	 $numLinesReadSoFar++;
   }
   return \@lines; # <-- Returns a REFERENCE to an array.
}

##------------------------------------------------------------------------
## \@ARRAY readFile(FILEHANDLE)
##------------------------------------------------------------------------
sub readFile {
   my ($FILEHANDLE) = @_;
   my @lines;
   while(my $line = <$FILEHANDLE>) {
      chomp($line);
      push(@lines, $line);
   }
   return \@lines;
}

##------------------------------------------------------------------------
## \@ARRAY readFileName($string filename=undef, int numLinesToRead)
##------------------------------------------------------------------------
sub readFileName($;$) {
   my ($filename, $numLinesToRead) = @_;
   my $FILEHANDLE  = &openFile($filename, "r");
   my $lines = undef; # <-- lines is actually a reference (e.g. $lines = \@array)
   if (defined($FILEHANDLE)) {
	 if (defined($numLinesToRead)) {
	   $lines = &readNumLinesFromFile($FILEHANDLE, $numLinesToRead);
	 } else {
	   $lines = &readFile($FILEHANDLE); # read ALL the lines
	 }
	 close($FILEHANDLE);
   }
   return $lines; # <-- This is actually a REFERENCE to an array.
}

##------------------------------------------------------------------------
## string getFileReaderMethod($string filename=undef)
##------------------------------------------------------------------------
sub getFileReaderMethod($) {
  # Looks at the extension of a file and finds a suitable
  # way to read it. Transparently handles gzipped files, for example.
  my ($filename) = @_;
  if (!defined($filename)) {
	print STDERR "ERROR in a call to getFileReaderMethod() inside <libfile.pl>: You should pass in a file name to the function getFileReaderMethod in libfile.pl\n";
  }
  if (not -f $filename) {
	print STDERR "WARNING: The file named <$filename> that was sent to getFileReaderMethod() to be read by code in libfile.pl was not found!!! Trying to proceed anyway...\n";
  }

  if ($filename =~ /\.gz$/ or $filename =~ /\.Z$/) {
	return "zcat $filename |"; # Transparently read from gzipped files
  }

  return "< $filename"; # <-- "<" is the default reader method
}
##------------------------------------------------------------------------
## string getFileWriterMethod($string filename=undef, bool shouldAppend)
##------------------------------------------------------------------------
sub getFileWriterMethod($;$) {
  # Looks at the extension of a file and finds a suitable
  # way to read it. Transparently handles gzipped files, for example.
  my ($filename, $shouldAppend) = @_;

  if (!defined($shouldAppend)) { $shouldAppend = 0; }

  if (!defined($filename)) {
	print STDERR "ERROR: You should pass in a file name to the function getFileWriterMethod in libfile.pl\n";
  }
  if (not -f $filename) {
	print STDERR "WARNING: The file $filename sent to getFileWriterMethod in libfile.pl was not found!!!
Trying to proceed anyway...\n";
  }

  my $writeString = $shouldAppend ? " >> " : " > ";

  # Transparently write to gzipped files
  if ($filename =~ /\.gz$/ or $filename =~ /\.Z$/) {
	return " | gzip -c $writeString $filename";
  }

  return "$writeString $filename"; # <-- this is the default writer method
}



##------------------------------------------------------------------------
## \*FILE openFile ($string file_name=undef, $string purpose="r")
## Note: Returns "undef" on error
##------------------------------------------------------------------------
sub openFile {
  my ($file_name, $purpose) = @_;
  $file_name    = defined($file_name) ? $file_name : '-'; # hyphen - means "STDIN"
  $purpose      = defined($purpose) ? $purpose : 'r'; # purpose means "read? write?"
  my $file      = undef;
  my $file_deal_with_method = undef; # <-- the reading string, e.g. "< $filename" or "zcat $filename |"
  if($file_name eq '-') {
    # Read-only files
    if($purpose =~ /^\s*r/i) {
      $file = \*STDIN;
    } elsif ($purpose =~ /^\s*w/i or $purpose =~ /^\s*a/i) { # Overwrite the file
      $file = \*STDOUT;
    }
  } else { # Ok, so it's a real file
    if($purpose =~ /^\s*r/i or not(defined($purpose))) { # READ-ONLY
	  $file_deal_with_method = getFileReaderMethod($file_name);
	  #print STDERR "Reading with: " . getFileReaderMethod($file_name) . "\n";
    }
    elsif($purpose =~ /^\s*w/i) {  # OVERWRITER
	  $file_deal_with_method = getFileWriterMethod($file_name);
    }
    elsif($purpose =~ /^\s*a/i) {  # APPEND
	  $file_deal_with_method = getFileWriterMethod($file_name, "APPEND");
    }
	
    if(not(open($file, $file_deal_with_method))) {
       $file = undef; # Returns "undef" on error
    }
  }
  return $file;
}

sub printFilep
{
   my ($file_in, $file_out) = @_;
   $file_in  = defined($file_in)  ? $file_in  : \*STDIN;
   $file_out = defined($file_out) ? $file_out : \*STDOUT;

   while(my $line = <$file_in>) {
      print $file_out $line;
   }
}

sub GetNumRows {
   my ($file_name, $count_blanks) = @_;
   $count_blanks = defined($count_blanks) ? $count_blanks : 1;
   my $num_rows = 0;
   my $file = &openFile($file_name);
   if (defined($file)) {
	 while(my $line = <$file>) {
	   if($count_blanks or ($line =~ /\S/)) {
         $num_rows++;
	   }
	 }
	 close($file);
   }
   return $num_rows;
}

sub numLines {
   return &GetNumRows(@_);
}

sub GetAllDirs
{
   return &getAllDirs(@_);
}

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub getAllDirs
{
  my @dirs = @_;
  my @subdirs;
  foreach my $dir (@dirs)
  {
     my $dirp;
     if(opendir($dirp, $dir))
     {
        my @files = readdir($dirp);
        foreach my $file (@files)
        {
          my $path = $dir . '/' . $file;
          if ((-d $path) and (not($file =~ /^\.\.$/)) and (not($file =~ /^\.$/)))
          {
             push(@subdirs, $path);
          }
        }
        closedir($dirp);
     }
  }
  return @subdirs;
}

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub getAllFiles
{
  my @dirs = @_;
  my @paths;
  foreach my $dir (@dirs)
  {
    my $dirp;
    if(opendir($dirp,$dir))
    {
      my @files = readdir($dirp);
      foreach my $file (@files)
      {
        push(@paths, $dir . '/' . $file);
      }
      closedir($dirp);
    }
  }
  return @paths;
}

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub getAllFilesRecursively # ($follow_links,@dirs)
{
  my $follow_links = shift;
  my @dirs = @_;
  my @files = ();
  my @allEntries;
  my @entries;
  my $entry;
  my $subEntry;

  foreach $entry (@dirs)
  {
    if(-d $entry and ($follow_links or not(-l $entry)))
    {
      if(opendir(DIR,$entry))
      {
        @allEntries = readdir(DIR);
        @entries = ();
        while(@allEntries)
        {
          $subEntry = shift @allEntries;
          if($subEntry ne '..' and $subEntry ne '.')
          {
            if($entry =~ /\/$/)
            {
              push(@entries, $entry . $subEntry);
            }
            else
            {
              push(@entries, $entry . '/' . $subEntry);
            }
          }
        }
        closedir(DIR);
        push(@files, &getAllFilesRecursively($follow_links,@entries));
      }
      else
      {
        print STDERR "Could not open directory -->$entry<-- skipping.\n";
      }
    }
    elsif(-f $entry)
    {
      push(@files,$entry);
    }
  }
  return @files;
}

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub getAllCodeRecursively # ($follow_links,@dirs)
{
  my $follow_links = shift;
  my @dirs = @_;
  my @files = ();
  my @allEntries;
  my @entries;
  my $entry;
  my $subEntry;

  foreach $entry (@dirs)
  {
    if(-d $entry and ($follow_links or not(-l $entry)))
    {
      if(opendir(DIR,$entry))
      {
        @allEntries = readdir(DIR);
        # print STDERR "[[$allEntries[0] $allEntries[1]]]\n";
        @entries = ();
        while(@allEntries)
        {
          $subEntry = shift @allEntries;
          if($subEntry ne '..' and $subEntry ne '.')
          {
            if($entry =~ /\/$/)
            {
              push(@entries, $entry . $subEntry);
            }
            else
            {
              push(@entries, $entry . '/' . $subEntry);
            }
          }
        }
        closedir(DIR);
        push(@files, &getAllCodeRecursively($follow_links,@entries));
      }
      else
      {
        print STDERR "Could not open directory -->$entry<-- skipping.\n";
      }
    }
    elsif(-f $entry and isCodeFile($entry))
    {
      push(@files,$entry);
    }
  }
  return @files;
}

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub getPathPrefix
{
  my $path = shift @_;

  $path =~ s/[^\/]*[\/]*$//;
  return $path;
}

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub getPathSuffix
{
  my $path = shift @_;

  while($path =~ /\/$/)
  {
    chop($path);
  }
  if($path =~ /([^\/]+)$/)
  {
    $path = $1;
  }
  return $path;
}

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub remPathExt
{
  my $path = shift @_;

  $path =~ s/\.[^\.]*$//;

  return $path;
}

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub getPathExt
{
  my $path = shift @_;

  my $ext = '';
  if($path =~ /(\.[^\.]*)$/)
  {
    $ext = $1;
  }

  return $ext;
}

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub expandEnv
{
   my ($text, $undef_val) = @_;
   $undef_val = defined($undef_val) ? $undef_val : '';

   while($text =~ /\$\((\w+)\)/) {
      my $env_var = $1;
      my $env_val = exists($ENV{$env_var}) ? $ENV{$env_var} : $undef_val;
      $text =~ s/\$\($env_var\)/$env_val/g;
   }
   while($text =~ /\$(\w+)/) {
      my $env_var = $1;
      my $env_val = exists($ENV{$env_var}) ? $ENV{$env_var} : $undef_val;
      $text =~ s/\$$env_var/$env_val/g;
   }

   return $text;
}

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub expandPath
{
  my $file = shift @_;
  my $home = "$ENV{HOME}";

  # print STDERR "'$file' --> ";
  $file =~ s/^\s+//;
  $file =~ s/\s+$//;
  $file =~ s/~/$home/ge;
  $file =~ s/\$HOME/$home/ge;
  $file =~ s/\$\(HOME\)/$home/ge;
  $file =~ s/\$\{HOME\}/$home/ge;
  # print STDERR "'$file'\n";

  $file = &expandEnv($file);

  return $file;
}

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub resolvePath # ($file,$pwd)
{
  my $file = &expandPath(shift);
  my $pwd  = shift;
  $pwd = defined($pwd) ? $pwd : '.';
  $pwd =~ s/[\/]+\s*$//;

  $file = &isRelative($file) ? ($pwd . '/' . $file) : $file;

  return $file;
}

##------------------------------------------------------------------------
## Returns the depth of the file from the root directory.
##------------------------------------------------------------------------
sub getPathDepth
{
  my $file = &expandPath(shift);
  # Remove any leading ./ that indicate "current" directory.
  while($file =~ s/^\.\///) {}

  my $depth=0;
  for(; $file =~ /\S/; $file = &getPathPrefix($file))
    { $depth++; }

  return $depth;
}


##------------------------------------------------------------------------
## Returns 1 if the file is an absolute path, 0 otherwise.
##------------------------------------------------------------------------
sub isAbsolute # ($file)
{
  my $file = &expandPath(shift);

  # If the first symbol is /, it's absolute.
  return ($file =~ /^\s*\//);
}

##------------------------------------------------------------------------
## Returns 1 if the file is a relative path, 0 otherwise.
##------------------------------------------------------------------------
sub isRelative # ($file)
{
  my $file = shift;
  return not(&isAbsolute($file));
}

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub dos2unix
{
  my $file = shift @_;

  $file =~ s/\\/\//g;
  $file =~ s/[Cc]:/\/cygdrive\/c/;

  return $file;
}

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub isCodeFile
{
  my $file = shift;

  if(not(-f $file))
  {
    return 0;
  }

  if($file =~ /\.c$/i)   { return 1; }
  if($file =~ /\.cc$/i)  { return 1; }
  if($file =~ /\.cpp$/i) { return 1; }
  if($file =~ /\.h$/i)   { return 1; }
  if($file =~ /\.hh$/i)  { return 1; }
  if($file =~ /\.hpp$/i)  { return 1; }
  if($file =~ /\.pl$/i)  { return 1; }
  if($file =~ /\.pm$/i)  { return 1; }
  if($file =~ /\.py$/i)  { return 1; }
  if($file =~ /\.m$/i)  { return 1; }
  if($file =~ /\.s$/i)  { return 1; }
  if($file =~ /\.y$/i)  { return 1; }

  return 0;
}

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub protectFromShell # ($file)
{
  my $file = shift;
  my $doubleQuote = qq{\"};
  my $singleQuote = qq{\'};
  $file =~ s/([\s~$doubleQuote$singleQuote)(&])/\\$1/g;
  return $file;
}

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub deprotectFromShell # ($file)
{
  my $file = shift;
  $file =~ s/\\([^\\])/$1/g;
  return $file;
}

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub getFileText($)
{
   my ($fileName) = @_;
   my $lines    = &readFileName($fileName);
   my $text      = join("\n",@{$lines});
   return $text;
}

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub getFileNumbers($$)
{
   my ($fileName,$delim) = @_;
   my $file = &openFile($fileName);
   my @tokens = ();
   if (defined($file)) {
	 while(my $line = <$file>) {
	   my @x = defined($delim) ? split($delim,$line) : split(/\s+/,$line);
	   chomp($x[$#x]);
	   foreach my $token (@x) {
		 if(&isNumber($token)) {
		   push(@tokens,$token);
		 }
	   }
	 }
   }
   return \@tokens;
}

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub getFileTokens($$)
{
   my ($fileName,$delim) = @_;
   my $file = &openFile($fileName);
   my @tokens = ();
   if (defined($file)) {
	 while(my $line = <$file>) {
	   my @x = split($delim,$line);
	   chomp($x[$#x]);
	   push(@tokens,@x);
	 }
   }
   return @tokens;
}

##------------------------------------------------------------------------
## $int numRows ($string file_name, $int blanks=1)
##------------------------------------------------------------------------
sub numRows
{
   my ($file_name, $blanks) = @_;

   $blanks = defined($blanks) ? $blanks : 1;

   my $num_rows = 0;

   if(-f $file_name)
   {
      my $wc = $blanks ? (`wc $file_name`) : (`grep -v '^[ ][ ]*\$' $file_name | wc`);

      my @wc = split(/\s+/, $wc);

      $num_rows = $wc[1];
   }
   return $num_rows;
}

sub pad
{
   my ($list, $filler) = @_;

   my @padded;

   my $list_len = scalar(@{$list});
   my $filler_len = scalar(@{$filler});

   for(my $i = 0; $i < $list_len; $i++)
   {
      my $j = $i % $filler_len;
      push(@padded, defined($$list[$i]) ? $$list[$i] : $$filler[$j]);
   }

   return \@padded;
}

sub replicate {
   my ($num, $text, $delim, $returnList) = @_;
   $num  = defined($num) ? $num : 2;
   $text = defined($text) ? $text : $_;
   $delim = defined($delim) ? $delim : "\t";
   $returnList = defined($returnList) ? $returnList : 0;
   my @repeats;
   for(my $i = 0; $i < $num; $i++) {
      if($returnList or defined($text)) {
         push(@repeats, $text);
      }
      else {
         push(@repeats, '');
      }
   }
   if($returnList) {
      return \@repeats;
   }
   return join($delim,@repeats);
}

##------------------------------------------------------------------------
## $string fill ($int max_cols, \@list filling=[''], $int pad=0,
##               $string delim="\t", $string line=$_)
##------------------------------------------------------------------------
sub fill
{
   my ($max_cols, $filling, $pad, $delim, $line) = @_;
   $pad     = defined($pad)     ? $pad     :    0;
   $delim   = defined($delim)   ? $delim   : "\t";
   $line    = defined($line)    ? $line    :   $_;

   my $chomped = 0;
   if($line =~ /\n$/)
   {
      chomp($line);
      $chomped = 1;
   }

   my @tuple    = split($delim, $line);
   my $num_cols = scalar(@tuple);
   my $num_fill = defined($filling) ? scalar(@{$filling}) : 0;

   if(not($pad))
   {
      for(my $i = 0; $i < $num_cols; $i++)
      {
         if(length($tuple[$i]) == 0 and $num_fill > 0)
         {
            $tuple[$i] = $$filling[$i % $num_fill];
         }
      }
   }

   for(my $i = $num_cols; $i < $max_cols; $i++)
   {
      my $filler = $num_fill > 0 ? $$filling[$i % $num_fill] : '';
      push(@tuple, $filler);
   }

   my $filled = join($delim, @tuple);

   if($chomped)
   {
      $filled .= "\n";
   }

   return $filled;
}

##------------------------------------------------------------------------
## $int numTokens ($delim="\t", $line=$_)
##------------------------------------------------------------------------
sub numTokens
{
   my ($delim, $line) = @_;
   $delim = defined($delim) ? $delim : "\t";
   $line  = defined($line)  ? $line  : $_;
   my $tokens = &mySplit($delim, $line);
   return scalar(@{$tokens});
}

##------------------------------------------------------------------------
## \@ints numTokensPerLine ($file_name="-", $delim="\t", $inc_blank=1)
##------------------------------------------------------------------------
sub numTokensPerLine {
   my ($file_name, $delim, $inc_blank) = @_;
   $file_name = defined($file_name) ? $file_name : "-";
   $delim     = defined($delim)     ? $delim : "\t";
   $inc_blank = defined($inc_blank) ? $inc_blank : 1;
   my $file = &openFile($file_name);
   my @nums = ();
   if (defined($file)) {
	 while(my $line = <$file>) {
	   if($inc_blank or ($line =~ /\S/)) {
         my $tuple = &mySplit($delim, $line);
         push(@nums, scalar(@{$tuple}));
	   }
	 }
	 close($file);
   }
   return \@nums;
}

##------------------------------------------------------------------------
## $int numCols ($string file='-', $string delim="\t", \$string eaten=undef)
##
## Takes a file name as an argument.  If the file is STDIN then it has to 
## eat a line to determine the columns.  This eaten line is saved in
## eaten if supplied.
##------------------------------------------------------------------------
sub numCols
{
   my ($file, $delim, $eaten) = @_;
   $file  = defined($file)  ? $file  : '-';
   $delim = defined($delim) ? $delim : "\t";

   my $filep;
   open($filep, $file) or die("Could not open file '$file'");
   my $num_cols = &numCols2($filep, $delim, $eaten);

   if($file ne '-')
   {
      close($filep);
      $$eaten = undef;
   }

   return $num_cols;
}

##-----------------------------------------------------------------------------
## $int numCols2 (\*FILE file=\*STDIN, $string delim="\t", \$string eaten=undef)
##
## Takes a file pointer as an argument.
##
## Eats a line of the file to figure out how many columns there are.
##-----------------------------------------------------------------------------
sub numCols2
{
   my ($file, $delim, $eaten) = @_;

   $file        = defined($file)  ? $file  : \*STDIN;
   $delim       = defined($delim) ? $delim : "\t";

   my $line     = <$file>;
   my $num_cols = &numTokens($delim, $line);

   if(defined($eaten))
   {
      $$eaten = $line;
   }

   return $num_cols;
}

##------------------------------------------------------------------------
## $int maxCols ($string file='-', $string delim="\t", \@list eaten=undef)
##
## Takes a file name as an argument.  If the file is STDIN then it has to 
## eat a line to determine the columns.  This eaten line is saved in
## eaten if supplied.
##------------------------------------------------------------------------
sub maxCols
{
   my ($delim, $file, $eaten) = @_;

   $file  = defined($file)  ? $file  : '-';

   $delim = defined($delim) ? $delim : "\t";

   my $filep;

   open($filep, $file) or die("Could not open file '$file'");

   my $max_cols = 0;

   while(my $line = <$filep>)
   {
      my $num_cols = &numTokens($delim, $line);

      if($num_cols > $max_cols)
      {
         $max_cols = $num_cols;
      }

      if($file eq '-' and defined($eaten))
      {
         push(@{$eaten}, $line);
      }
   }
   close($filep);

   return $max_cols;
}

##----------------------------------------------------------------------------
## \@list &readHeader(\*FILE file=\*STDIN, $int num_rows=1, $string delim="\t")
#
#  Read columns from the file.  Returns a list containing each column
#  where the elements in the column are seperated by delim.
##----------------------------------------------------------------------------
sub readHeader
{
   my ($file, $num_rows, $delim_in, $delim_out) = @_;
   $file      = defined($file)      ? $file      : \*STDIN;
   $num_rows  = defined($num_rows)  ? $num_rows  : 1;
   $delim_in  = defined($delim_in)  ? $delim_in  : "\t";
   $delim_out = defined($delim_out) ? $delim_out : $delim_in;

   my @column;

   for(my $i = 0; ($i < $num_rows) and not(eof($file)); $i++)
   {
      my $line  = <$file>;

      my @tuple = split($delim_in, $line);

      chomp($tuple[$#tuple]);

      for(my $j = 0; $j < scalar(@tuple); $j++)
      {
         $column[$j] .= ($i == 0) ? $tuple[$j] : ($delim_out . $tuple[$j]);
      }
   }

   return \@column;
}

sub duplicate
{
   my ($num_copies, @entries) = @_;

   $num_copies = defined($num_copies) ? $num_copies : 2;

   if(scalar(@entries) == 0)
   {
      push(@entries, '');
   }

   my @tuple;

   for(my $i = 0; $i < $num_copies; $i++)
   {
      push(@tuple, @entries);
   }

   return \@tuple;
}

##----------------------------------------------------------------------------
## \@list &getCols(\@list, $string ranges, \$int max_cols)
##----------------------------------------------------------------------------
sub getCols
{
   my ($list, $ranges, $max_cols) = @_;

   if(defined($list) and defined($ranges) and defined($max_cols))
   {
      my $num_cols  = scalar(@{$list});
      my $updated   = 0;
      if($num_cols > $$max_cols)
      {
         $$max_cols = $num_cols;
         if(defined($ranges))
         {
            my @cols = &parseRanges($ranges, $$max_cols);
            for(my $i  = 0; $i < scalar(@cols); $i++)
            {
               $cols[$i]--;
            }
            return \@cols;
         }
      }
   }
   return undef;
}


##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub fileExists
{
   my ($file) = @_;
   return (-f $file);
}

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub dirExists
{
   my ($dir) = @_;
   return (-d $dir);
}

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub linkExists
{
   my ($link) = @_;
   return (-l $link);
}

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub pathExists
{
   my ($path) = @_;
   return ((-f $path) or (-d $path) or (-l $path));
}

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub allFilesExist
{
   foreach my $file (@_)
   {
      if(not(&fileExists($file)))
      {
         return 0;
      }
   }
   return 1;
}

##------------------------------------------------------------------------
##
##------------------------------------------------------------------------
sub allPathsExist
{
   foreach my $path (@_)
   {
      if(not(&pathExists($path)))
      {
         return 0;
      }
   }
   return 1;
}

##------------------------------------------------------------------------
## \@list getHeader ($string file, $int num_lines=1, $string delim="\t"
##                   \$FILE* filep)
##
##    \$FILE* filep - If supplied gets a copy of the file pointer (and
##                    the file is *not* closed but kept open).
##------------------------------------------------------------------------
sub getHeader
{
   my ($file, $num_lines, $delim, $filep) = @_;
   $num_lines = defined($num_lines) ? $num_lines : 1;
   $delim     = defined($delim) ? $delim : "\t";

   my $fp = &openFile($file);

   my @header = ();
   for(my $i = 0; $i < $num_lines; $i++) {
      my $line = <$fp>;
      my @line = split($delim, $line);
      chomp($line[$#line]);

      for(my $j = 0; $j < scalar(@line); $j++)
      {
         $header[$j] .= length($header[$j]) > 0 ? " $line[$j]" : $line[$j];
      }
   }

   if(not(defined($filep))) {
	 close($fp);
   } else {
	 $$filep = $fp;
   }

   return \@header;
}


#------------------------------------------------------------------------
# \@list getRanges ($string ranges)
#------------------------------------------------------------------------
sub parseRangeSegments
{
   my ($string) = @_;

   my @strings = split(",", $string);

   my @ranges;

   foreach my $range (@strings)
   {
      my $beg = undef;
      my $end = undef;
      my $inc = undef;

      if($range =~ /^([-]{0,1}\d+)[-:]([-]{0,1}\d+)[-:]([-]{0,1}\d+)/)
      {
         $beg = $1;
         $inc = $2;
         $end = $3;
      }
      elsif($range =~ /^([-]{0,1}\d+)[:-]([-]{0,1}\d+)/)
      {
         $beg = $1;
         $end = $2;
         $inc = $beg < $end ? 1 : -1;
      }
      elsif($range =~ /^([-]{0,1}\d+)[:-]\s*$/)
      {
         $beg = $1;
         $end = -1;
         $inc = ($beg >= 0) ? 1 : -1;
      }
      elsif($range =~ /^([-]{0,1}\d+)/)
      {
         $beg = $1;
         $end = $1;
         $inc = 1;
      }

      push(@ranges, [$beg, $end, $inc]);
   }
   return \@ranges;
}

#------------------------------------------------------------------------
# \@list getSubList (\@list, \@ranges)
#
# Note that the first index is 1 (not 0)!
#------------------------------------------------------------------------
sub getSublist
{
   my ($list, $ranges) = @_;

   my @sublist;

   my $n = scalar(@{$list});

   foreach my $range (@{$ranges})
   {
      my ($beg, $end, $inc) = @{$range};

      ($beg, $end, $inc) = &forceRangeBounds($beg, $end, $inc, $n);

      for(my $i = $beg; $i <= $end; $i += $inc)
      {
         push(@sublist, $$list[$i-1]);
      }
   }

   return \@sublist;
}

sub forceRangeBounds
{
   my ($beg, $end, $inc, $n) = @_;

   $beg = &forceIndexBounds($beg, $n);

   $end = &forceIndexBounds($end, $n);

   # Make sure the iteration will end.
   if((($end - $beg + 1) * $inc) < 0)
   {
      $inc = -$inc;
   }

   return ($beg, $end, $inc);
}

sub forceIndexBounds
{
   my ($i, $n) = @_;

   $i = $i < 0 ? $n + $i + 1 : $i;

   $i = $i <= 0 ? 1 : $i;

   $i = $i > $n ? $n : $i;

   return $i;
}

#------------------------------------------------------------------------
# @list parseRanges ($string ranges, $int last_col, $int offset=0)
#------------------------------------------------------------------------
sub parseRanges
{
   my ($ranges, $last_col, $offset) = @_;
   $offset = defined($offset) ? $offset : 0;

   my @segments                     = ();
   my @range                        = ();
   my @fields                       = ();
   my ($i,$beg,$end,$inc)           = (0,-1,-1,1);
   my $seg;
   @segments = split(",", $ranges);
   foreach $seg (@segments)
   {
      $beg = undef;
      $end = undef;
      $inc = undef;

      if($seg =~ /^([-]{0,1}\d+)[-:](\d+)[-:]([-]{0,1}\d+)/)
      {
         $beg = $1;
         $inc = $2;
         $end = $3;
      }
      elsif($seg =~ /^([-]{0,1}\d+)[:-]([-]{0,1}\d+)/)
      {
         $beg = $1;
         $end = $2;
         $inc = 1;
      }
      elsif($seg =~ /^([-]{0,1}\d+)[:-]\s*$/)
      {
         $beg = $1;
         $end = -1;
         $inc = ($beg >= 0) ? 1 : -1;
      }
      elsif($seg =~ /^([-]{0,1}\d+)/)
      {
         $beg = $1;
         $end = $1;
         $inc = 1;
      }

      $beg = (defined($beg) and $beg =~ /\S/) ? $beg : 0;
      $beg = (defined($beg) and $beg < 0)     ? (defined($last_col) ? $last_col + $beg + 1 : undef) : $beg;
      $end = (defined($end) and $end =~ /\S/) ? $end : (defined($last_col) ? $last_col : undef);
      $end = (defined($end) and $end < 0)     ? (defined($last_col) ? $last_col + $end + 1 : undef) : $end;
      $inc = $inc =~ /\S/ ? $inc : 1;

      if(defined($beg) and defined($end) and defined($inc))
      {
         for($i = $beg; $i <= $end; $i += $inc)
         {
            push(@fields, $i);
         }
      }
   }

   if($offset != 0)
   {
      for(my $i = 0; $i < scalar(@fields); $i++)
      {
         $fields[$i] += $offset;
      }
   }

   return @fields;
}

##--------------------------------------------------------------------------------------
## $int evalRegex ($string value=$_, $string regex='/\S/',
##                    $string op='=~', $string hardop=undef, $int negate=0)
##
## Returns 1 if the regular expression evaluates to true.
##
## hardop - supplies a specific operation.  Valid are:
##             'gt'  for $value >  $regex
##             'gte' for $value >= $regex
##             'lt'  for $value <  $regex
##             'lte' for $value <= $regex
##--------------------------------------------------------------------------------------
sub evalRegex
{
   my ($value, $regex, $op, $hardop, $negate) = @_;
   $value  = defined($value)  ? $value  : $_;
   $regex  = defined($regex)  ? $regex  : '/\S/';
   $op     = defined($op)     ? $op     : '=~';
   $hardop = defined($hardop) ? $hardop : undef;
   $negate = defined($negate) ? $negate : 0;

   my $result = 0;

   if(not(defined($hardop)))
   {
      $result = $negate ? eval("not(\$value $op $regex);") :
                          eval("\$value $op $regex;");
      $result = (defined($result) and $result) ? 1 : 0;
   }
   elsif($hardop eq 'eq')
   {
      $result = $value eq $regex ? 1 : 0;
   }
   elsif($hardop eq 'ne')
   {
      $result = $value ne $regex ? 1 : 0;
   }
   elsif($hardop eq 'gt')
   {
      $result = $value gt $regex ? 1 : 0;
   }
   elsif($hardop eq 'lt')
   {
      $result = $value lt $regex ? 1 : 0;
   }
   elsif($hardop eq 'gte')
   {
      $result = (($value gt $regex) or ($value eq $regex)) ? 1 : 0;
   }
   elsif($hardop eq 'lte')
   {
      $result = (($value lt $regex) or ($value eq $regex)) ? 1 : 0;
   }
   elsif($hardop eq '=')
   {
      $result = $value == $regex ? 1 : 0;
   }
   elsif($hardop eq '==')
   {
      $result = $value == $regex ? 1 : 0;
   }
   elsif($hardop eq '!=')
   {
      $result = $value != $regex ? 1 : 0;
   }
   elsif($hardop eq '>')
   {
      $result = $value > $regex ? 1 : 0;
   }
   elsif($hardop eq '>=')
   {
      $result = $value >= $regex ? 1 : 0;
   }
   elsif($hardop eq '<')
   {
      $result = $value < $regex ? 1 : 0;
   }
   elsif($hardop eq '<=')
   {
      $result = $value <= $regex ? 1 : 0;
   }
   return $result;
}

##------------------------------------------------------------------------
## \%attrib parseArgs (\@list args, \@list flag_tuples, $int store_extra=0)
##
## \@args        - list of arguments (from @ARGV usually)
##
## \@flag_tuples - a list of triples where each triple gives:
##
##                        (FLAG,TYPE,DEFAULT,EATS)
##
##           for each option.  FLAG is the string (or regular expression)
##           that indicates use of the option (including the dash if 
##           dashes are being used!).  DEFAULT is the default value for
##           the option used when the option's flag is not found in the
##           argument list.  If EATS is defined then the next argument in
##           \@args is "eaten" to retrieve the value for the option; if
##           EATS is undef then it does *not* eat the next character
##           but fills in the string contained in EATS for the option
##           when its flag is encountered. TYPE can be any of:
##
##                'scalar' - the option is a scalar quantity
##                'list'   - the option is a list
##                'set'    - the option is a set
##                'map'    - the option is an associative array
##                'file'   - the option is the name of a file
##
##
##           The special FLAG '--file' reads a file from the arguments.
##
## $store_extra - If 1 stores unrecognized arguments in a list that can
##                be accessed with '--extra'.  Otherwise the function
##                dies if an unrecognized argument is encountered (default)
##
##------------------------------------------------------------------------
sub parseArgs
{
   my ($args, $flag_tuples, $store_extra) = @_;
   $store_extra = defined($store_extra) ? $store_extra : 0;

   my @args = defined($args)        ? @{$args}        : ();
   my @f    = defined($flag_tuples) ? @{$flag_tuples} : ();
   my %options;
   my %option_overwritten;
   my @extra;

   # Store the defaults in the options.
   for(my $i = 0; $i < scalar(@f); $i++)
   {
      my ($flag, $type, $default, $eats) = ($f[$i][0],$f[$i][1],$f[$i][2],$f[$i][3]);
      $options{$flag} = $default;
   }

   while(@args)
   {
      my $arg = shift @args;
      if($arg eq '--help')
      {
         @args    = ();
         $options{'--help'} = 1;
      }
      else
      {
         my $matched_arg = 0;
         for(my $i = 0; $i < scalar(@f); $i++)
         {
            my ($flag, $type, $default, $eats) = ($f[$i][0],$f[$i][1],$f[$i][2],$f[$i][3]);

            if(($flag =~ /^--file/ and ((-f $arg) or ($arg eq '-'))) or
               ($arg eq $flag))
            {
               $matched_arg = 1;
               my $value = $arg;
               if(defined($eats))
               {
                  $value = $eats;
               }
               elsif(not($flag =~ /^--file/))
               {
                  $value = shift @args;
               }

               if($type eq 'scalar')
               {
                  $options{$flag} = $value;
               }
               elsif($type eq 'list')
               {
                  if(not(defined($option_overwritten{$flag})))
                  {
                     my @empty_list;
                     $options{$flag} = \@empty_list;
                  }
                  my $list = $options{$flag};
                  push(@{$list}, $value);
               }
               elsif($type eq 'set')
               {
                  if(not(defined($option_overwritten{$flag})))
                  {
                     my %empty_set;
                     $options{$flag} = \%empty_set;
                  }
                  my $set = $options{$flag};
                  $$set{$value} = 1;
               }
               elsif($type eq 'map')
               {
                  if(not(defined($option_overwritten{$flag})))
                  {
                     my %empty_map;
                     $options{$flag} = \%empty_map;
                  }
                  my ($attrib,$val) = split('=',$value);
                  my $map = $options{$flag};
                  $$map{$attrib} = $val;
               }
               $option_overwritten{$flag} = 1;
            }
         }
         if(not($matched_arg))
         {
            if($store_extra)
            {
               push(@extra, $arg);
            }
            else
            {
               die("Bad argument '$arg' given");
            }
         }
      }
   }

   # If we picked up any extra arguments put them in the hash.
   $options{'--extra'} = \@extra;

   return \%options;
}

sub readKeyedTuples
{
   my ($file, $delim, $key_col, $headers, $append) = @_;
   $file    = defined($file)    ? $file    : $_;
   $delim   = defined($delim)   ? $delim   : "\t";
   $key_col = defined($key_col) ? $key_col : 0;
   $headers = defined($headers) ? $headers : 0;
   $append  = defined($append) ? $append : 0;

   my %set;

   my $filep   = &openFile($file);
   my $line_no = 0;
   while(<$filep>)
   {
      $line_no++;
      if($line_no > $headers)
      {
         my @x = split($delim);
         chomp($x[$#x]);
         my $key = splice(@x, $key_col, 1);
         if($append) {
            if(exists($set{$key})) {
               push(@{$set{$key}}, \@x);
            }
            else {
               $set{$key} = [\@x];
            }
         }
         else {
            $set{$key} = \@x;
         }
      }
   }
   close($filep);
   return \%set;
}

sub readKeyedValues
{
   my ($file, $delim, $key_col, $val_col, $headers, $append) = @_;
   $file    = defined($file)    ? $file    : $_;
   $delim   = defined($delim)   ? $delim   : "\t";
   $key_col = defined($key_col) ? $key_col : 0;
   $headers = defined($headers) ? $headers : 0;
   $append  = defined($append)  ? $append : 0;

   my %set;

   my $filep   = &openFile($file);
   my $line_no = 0;
   while(my $line = <$filep>) {
      $line_no++;
      if($line_no > $headers) {
         my @x = split($delim, $line);
         chomp($x[$#x]);
         my $key = splice(@x, $key_col, 1);
         my $vals = defined($val_col) ? [$x[$val_col]] : \@x;

         foreach my $val (@{$vals}) {
            if($append) {
               if(exists($set{$key})) {
                  push(@{$set{$key}}, $val);
               }
               else {
                  $set{$key} = [$val];
               }
            }
            else {
               $set{$key} = $val;
            }
         }
      }
   }
   close($filep);
   return \%set;
}

sub download
{
   my ($url, $dir, $pattern) = @_;
   $dir = defined($dir) ? $dir : '.';

   my $wget = "wget --retr-symlinks --passive-ftp --follow-ftp -Q 0 -N -nd -t 1 -P $dir";

   my $cmd  = defined($pattern) ? "$wget '$url/*' -A$pattern" :
                                  "$wget '$url'";

   `$cmd`;

   my $downloaded_file = undef;

   if($url =~ /\/([^\/]+)\s*$/)
   {
      $downloaded_file = $dir . '/' . $1;
   }

   return $downloaded_file;
}

sub downloadMultiple
{
   my ($url, $dir, $pattern) = @_;
   $dir = defined($dir) ? $dir : '.';

   my $wget = "wget --retr-symlinks --passive-ftp -Q 0 -N -nd -t 1 -P $dir";

   my $cmd  = "$wget $url";

   `$cmd`;

   my $downloaded_file = undef;

   if($url =~ /\/([^\/]+)\s*$/)
   {
      $downloaded_file = $dir . '/' . $1;
   }

   return $downloaded_file;
}

sub copyFile
{
   my ($source, $destination) = @_;

   my $s = &openFile($source, "r");

   my $d = &openFile($destination, "w");

   (defined($s) and defined($d)) or die("Could not copy '$source' to '$destination'");

   while(my $line = <$s>)
   {
      print $d $line;
   }

   close($s);

   close($d);
}

sub deleteFile
{
   my ($file) = @_;

   system("rm -f $file");
}

sub makeTmpFile
{
   my ($prefix, $file) = @_;

   $prefix = defined($prefix) ? $prefix : '';

   my $suffix = '.tmp';

   my $tmpname  = '';

   my $tmpfile  = undef;

   my $maxtries = 1000000;

   for(my $i = 0; not(defined($tmpfile)) and ($i < $maxtries); $i++)
   {
      my $time = time;

      my $rand = int(rand(1000000));

      $tmpname = $prefix . '_' . $time . '_' . $rand . $suffix;

      if(&pathExists($tmpname))
      {
         $tmpfile = undef;
      }

      else
      {
         if(defined($file))
         {
            &copyFile($file, $tmpname);
         }
         return $tmpname;
      }
   }

   die("Could not open a temporary file");

   return $tmpname;
}

sub findLine
{
   my ($filep, $patterns, $logic) = @_;

   $logic = defined($logic) ? $logic : 'and';

   my $result = undef;

   if(($logic =~ /and/i) or ($logic =~ /all/i))
   {
      $result = &findLineWhereAllMatch($filep, $patterns);
   }

   if(($logic =~ /or/i) or ($logic =~ /any/i))
   {
      $result = &findLineWhereAnyMatch($filep, $patterns);
   }

   return $result;
}

sub findLineWhereAllMatch
{
   my ($filep, $patterns) = @_;

   while(my $line = <$filep>)
   {
      my $match = 1;

      foreach my $pattern (@{$patterns})
      {
         if(not($line =~ /$pattern/))
         {
            $match = 0;
         }
      }

      if($match)
      {
         return $line;
      }
   }

   return undef;
}

sub findLineWhereAnyMatch
{
   my ($filep, $patterns) = @_;

   while(my $line = <$filep>)
   {
      my $match = 0;

      foreach my $pattern (@{$patterns})
      {
         if($line =~ /$pattern/)
         {
            $match = 1;
         }
      }

      if($match)
      {
         return $line;
      }
   }

   return undef;
}

sub printMatrix
{
   my ($matrix, $file, $delim_col, $delim_row) = @_;

   $file  = defined($file)  ? $file  : \*STDOUT;

   $delim_col = defined($delim_col) ? $delim_col : "\t";

   $delim_row = defined($delim_row) ? $delim_row : "\n";

   my $n = scalar(@{$matrix});

   for(my $i = 0; $i < $n; $i++)
   {
      print $file join($delim_col, @{$$matrix[$i]}), $delim_row;
   }
}

sub readAggregate {

   my ($file, $key_col, $delim, $function) = @_;
   $file     = defined($file)? $file : $_;
   $key_col  = defined($key_col) ? $key_col : 0;
   $delim    = defined($delim) ? $delim : "\t";
   $function = defined($function) ? $function : 'cat';

   my ($data, $ids, $rows, $max_cols) = &readDataAndIds($file,$key_col,$delim);

   my $get_add_stats = 0;
   if(($function eq 'mean') or ($function eq 'sum')) {
      $get_add_stats = 1;
   }
   my $get_prod_stats = 0;
   if(($function eq 'prod')) {
      $get_prod_stats = 1;
   }

   my @agg;

   for(my $i = 0; $i < scalar(@{$rows}); $i++) {

      my @num;
      my @sum;
      my @sumsqr;
      my @prod;
      if($get_add_stats) {
         for(my $j = 0; $j < $max_cols; $j++) {
            $num[$j]    = 0;
            $sum[$j]    = 0;
            $sumsqr[$j] = 0;
         }
      }

      if($get_prod_stats) {
         for(my $j = 0; $j < $max_cols; $j++) {
            $prod[$j] = 1;
         }
      }

      my $id = $$ids[$i];

      my @r = @{$$rows[$i]};

      my @a;

      for(my $j = 0; $j < $max_cols; $j++) {
         $a[$j] = [];
      }

      for(my $k = 0; $k < scalar(@{$$rows[$i]}); $k++) {
         my $row = $$rows[$i][$k];
         for(my $j = 0; $j < $max_cols; $j++) {
            if(defined($$data[$row][$j])) {
               if($$data[$row][$j] =~ /^\s*[\d+\.eE-]+\s*$/) {
                  if($get_add_stats) {
                     $num[$j]    += 1;
                     $sum[$j]    += $$data[$row][$j];
                     $sumsqr[$j] += $$data[$row][$j] * $$data[$row][$j];
                  }
                  if($get_prod_stats) {
                     $prod[$j] *= $$data[$row][$j];
                  }
                  if($function eq 'cat') {
                     push(@{$a[$j]},$$data[$row][$j]);
                  }
               }
            }
         }
      }

      for(my $j = 0; $j < $max_cols; $j++) {
         if($function eq 'sum') {
            $a[$j] = $num[$j] > 0 ? $sum[$j] : undef;
         }
         if($function eq 'mean') {
            $a[$j] = $num[$j] > 0 ? $sum[$j] / $num[$j] : undef;
         }
      }
      $agg[$i] = [$id, \@a]; # or should this be ($id, \@a) ?
   }
   return \@agg;
}

sub readDataAndIds {
   my ($file, $key_col, $delim, $headers) = @_;
   $file    = defined($file)? $file : $_;
   $key_col = defined($key_col) ? $key_col : 0;
   $delim   = defined($delim) ? $delim : "\t";
   $headers = defined($headers) ? $headers : 0;

   my %ids;
   my @ids;
   my @rows;
   my @data;
   my $nids   = 0;
   my $row    = 0;
   my $max    = 0;
   my $fp     = &openFile($file);
   my $lines  = 0;
   my $header = undef;

   while(my $line = <$fp>) {
      $lines++;
      my @x = @{&mySplit($delim, $line)};
      chomp($x[$#x]);
      my $id = splice(@x, $key_col, 1);
      my $n = scalar(@x);

      if($lines > $headers) {
         push(@data, \@x);
         if($n > $max) {
            $max = $n;
         }
         if(not(exists($ids{$id}))) {
            $ids{$id} = $nids;
            push(@ids, $id);
            my @r;
            $rows[$nids] = \@r;
            $nids++;
         }
         my $first_row = $ids{$id};
         push(@{$rows[$first_row]}, $row);
         $row++;
      }
      elsif(not(defined($header))) {
         $header = [$id, @x];
      }
   }
   close($fp);

   if($headers > 0) {
      return (\@data, \@ids, \@rows, $max, $header);
   }
   return (\@data, \@ids, \@rows, $max);
}

sub readIds {
   my ($file, $col, $delim) = @_;
   $file  = defined($file)  ? $file  : $_;
   $col   = defined($col)   ? $col   : 0;
   $delim = defined($delim) ? $delim : "\t";

   my %ids;

   my @ids;

   my @rows;

   my $fp = &openFile($file);

   my $nids = 0;

   my $row = 0;
   while(my $line = <$fp>)
   {
      my @x = split($delim, $line);

      chomp($x[$#x]);

      my $id = $x[$col];

      if(not(exists($ids{$id})))
      {
         $ids{$id} = $nids;
         push(@ids, $id);
         my @r;
         $rows[$nids] = \@r;
         $nids++;
      }

      my $first_row = $ids{$id};

      push(@{$rows[$first_row]}, $row);

      $row++;
   }
   close($fp);

   return (\@ids, \@rows);
}

sub readDataMatrix
{
   my ($file, $key_col, $delim, $max_cols) = @_;
   $key_col = defined($key_col) ? $key_col : 0;
   $delim   = defined($delim) ? $delim : "\t";

   my $fp = &openFile($file);

   my @data;

   my $max = 0;
   while(my $line = <$fp>)
   {
      my @x = split($delim, $line);
      chomp($x[$#x]);
      my $key = splice(@x, $key_col, 1);
      splice(@x, 0, 0, $key);
      my $n = scalar(@x);
      push(@data, \@x);
      if($n > $max)
      {
         $max = $n;
      }
   }
   close($fp);

   if(defined($max_cols)) {
      $$max_cols = $max;
   }

   return \@data;
}

sub multiSplice
{
   my ($list, $indices, $delim) = @_;

   $delim = defined($delim) ? $delim : "\t";

   my @removed;

   my @sorted_indices = sort { $b <=> $a; } @{$indices};

   foreach my $index (@sorted_indices)
   {
      push(@removed, splice(@{$list}, $index, 1));
   }

   return join($delim, @removed);
}

sub makeValidFileName
{
   my ($name) = @_;

   my $fileName = $name;

   $fileName =~ s/\\/ /g;
   $fileName =~ s/\// /g;
   $fileName =~ s/\[/ /g;
   $fileName =~ s/\]/ /g;
   $fileName =~ s/\)/ /g;
   $fileName =~ s/\(/ /g;
   $fileName =~ s/\*/ /g;
   $fileName =~ s/\+/ /g;
   $fileName =~ s/~/ /g;
   $fileName =~ s/\./ /g;
   $fileName =~ s/,/ /g;
   $fileName =~ s/;/ /g;
   $fileName =~ s/:/ /g;
   $fileName =~ s/!/ /g;
   $fileName =~ s/\?/ /g;
   $fileName =~ s/\s+/_/g;

   return $fileName;
}

sub tableSwapColumns
{
   my ($table, $col1, $col2) = @_;
   for(my $row = 0; $row < @{$table}; $row++)
   {
      my ($entry1,$entry2) = ($$table[$col1],$$table[$col2]);
      $$table[$col1] = $entry2;
      $$table[$col2] = $entry1;
   }
}

#------------------------------------------------------------------------
# $int getNumCols($string file, $string delim="\t")
#------------------------------------------------------------------------
sub getNumCols
{
   my ($file, $delim) = @_;
   $delim = not(defined($delim)) ? "\t" : $delim;
   my $fp;
   open($fp, $file) or die("Could not open file '$file'");
   my $done = 0;
   my $num_cols = undef;
   while(not(defined($num_cols)) and not(eof($fp)))
   {
      my $line  = <$fp>;
      if($line =~ /\S/)
      {
         my @tuple = split($delim, $line);
         $num_cols = scalar(@tuple);
         # print STDERR "$num_cols : ", join("-", @tuple), "'\n";
      }
   }
   return $num_cols;
}

#------------------------------------------------------------------------
# ($string, \@list) splitKeyAndValue ($string line, \@list key_cols,
#                                     \@list sorted_key_cols, $string delim)
#------------------------------------------------------------------------
sub splitKeyAndValue
{
  my ($line,$key_cols,$sorted_key_cols,$delim) = @_;
  $sorted_key_cols = defined($sorted_key_cols) ? $sorted_key_cols : $key_cols;
  $delim = defined($delim) ? $delim : "\t";
  my @tuple = split($delim, $line);
  my @tuple_copy = @tuple;
  
  if($#tuple == -1)
    { return (undef,undef); }

  chomp($tuple[$#tuple]);
  chomp($tuple_copy[$#tuple]);

  # Remove key entries from the tuple in reverse order to
  # preserve the indexing.
  my @key;
  my $j=0;
  for(my $i=scalar(@{$sorted_key_cols})-1; $i>=0; $i--)
  {
    $j++;
    push(@key, $tuple_copy[$$key_cols[$j]]);
    splice(@tuple,$$sorted_key_cols[$i], 1);
  }
  return (join($delim,@key),\@tuple);
}

#---------------------------------------------------------------------------
# \@list listRead ($string file, $string delim="\t", \@list key_cols=(1))
#---------------------------------------------------------------------------
sub tableRead
{
   my ($file, $delim, $key_cols, $num_headers) = @_;
   $delim = not(defined($delim)) ? "\t" : $delim;
   $num_headers = defined($num_headers) ? $num_headers : 0;

   my $header = undef;

   if(not(defined($key_cols)))
   {
      my @key_cols = (1);
      $key_cols = \@key_cols;
   }
   my @sorted_key_cols = sort { $a <=> $b; } @{$key_cols};
   my $filep;
   open($filep, $file) or die("Could not open file '$file'");
   my @tuples;
   my $line_no = 0;
   my $max_fields = 0;
   while(my $line = <$filep>)
   {
      $line_no++;
      chomp($line);
      my ($key, $tuple) = &splitKeyAndValue($line, $key_cols, \@sorted_key_cols, $delim);
      my @key_tuple = ($key);
      push(@key_tuple, @{$tuple});
      if($line_no > $num_headers)
      {
         push(@tuples, \@key_tuple);
      }
      elsif(not(defined($header)))
      {
         $header = \@key_tuple;
      }
      else
      {
         for(my $i = 0; $i < @key_tuple; $i++)
         {
            $$header[$i] .= $delim . $key_tuple[$i];
         }
      }
   }
   close($filep);

   if($num_headers > 0)
   {
      return (\@tuples, $header);
   }
   return \@tuples;
}

#------------------------------------------------------------------------
# \@list emptyTuple ($int n)
#------------------------------------------------------------------------
sub emptyTuple
{
  my $n = shift;
  my @blanks = ();

  for(my $i=0; $i<$n; $i++)
    { push(@blanks,''); }
  
  return \@blanks;
}

sub isEmpty {
   my ($x) = @_;
   return (not(defined($x))
          or ($x eq 'NaN')
          or ($x eq 'NA')
          or ($x !~ /\S/))
          ;
}

#------------------------------------------------------------------------
# $int getTupleLength ($string line, $string delim)
#------------------------------------------------------------------------
sub getTupleLength
{
   my ($line, $delim) = @_;
   $line  = defined($line)  ? $line  : $_;
   $delim = defined($delim) ? $delim : "\t";

   my @tuple  = split($delim, $line);
   return ($#tuple + 1);
}

#------------------------------------------------------------------------
# $int compareKeys ($string key1, $string key2)
#------------------------------------------------------------------------
sub compareKeys {
  my ($key1, $key2) = @_;
  if(not(defined($key1)) or length($key1)==0)
    { return 1; }
  if(not(defined($key2)) or length($key2)==0)
    { return -1; }
  return($key1 cmp $key2);
}

#------------------------------------------------------------------------
# Same as compareKeys, but can be used with the sort() function.
#------------------------------------------------------------------------
sub cmpKeys {
   return &compareKeys($a,$b);
}

#------------------------------------------------------------------------
# $int compareNumbers ($scalar num1, $scalar num2)
#------------------------------------------------------------------------
sub compareNumbers {
  my ($num1, $num2) = @_;
  if(not(defined($num1)) or &isEmpty($num1))
    { return 1; }
  if(not(defined($num2)) or &isEmpty($num2))
    { return -1; }
  return($num1 <=> $num2);
}

#------------------------------------------------------------------------
# Same as compareNumbers, but can be used with the sort() function.
#------------------------------------------------------------------------
sub cmpNums {
   return &compareNumbers($a,$b);
}

#------------------------------------------------------------------------
# $string getSubTupleString ($string line, \@list cols, $string delim)
#------------------------------------------------------------------------
sub getSubTupleString
{
  my ($line,$cols,$delim) = @_;
  $delim = defined($delim) ? $delim : "\t";
  my @tuple = split($delim, $line);

  if($#tuple==-1 or scalar(@{$cols})<=0)
    { return undef; }

  chomp($tuple[$#tuple]);

  my $sub = $tuple[$$cols[0]];
  for(my $i=1; $i<scalar(@{$cols}); $i++)
    { $sub .= $delim . $tuple[$$cols[$i]]; } 
  return $sub;
}

#------------------------------------------------------------------------
# \@list getSubTuple ($string line, \@list cols, $string delim)
#------------------------------------------------------------------------
sub getSubTuple
{
  my ($line,$cols,$delim) = @_;
  $delim = defined($delim) ? $delim : "\t";
  my @tuple = split($delim, $line);
  my @sub_tuple;

  chomp($tuple[$#tuple]);

  for(my $i=0; $i<scalar(@{$cols}); $i++)
  {
    push(@sub_tuple,$tuple[$$cols[$i]]);
  }
  return \@sub_tuple;
}

#------------------------------------------------------------------------
# $string getTupleEntry ($string line, int $i, $string delim)
#------------------------------------------------------------------------
sub getTupleEntry # ($line,$i,$delim)
{
  my ($line,$i,$delim) = @_;
  my @cols = ($i);
  return &getSubTupleString($line,\@cols,$delim);
}

#------------------------------------------------------------------------
# void forceTuplePrecision (\@list tuple, $double precision, $int skip)
#------------------------------------------------------------------------
sub forceTuplePrecision
{
  my ($tuple,$precision,$skip) = @_;
  $skip = (not(defined($skip)) or $skip < 0) ? 0 : $skip;
  $precision = 10**$precision;
  for(my $i=$skip; $i<scalar(@{$tuple}); $i++)
  {
    if($$tuple[$i] =~ /\d/)
    {
      $$tuple[$i] = int($$tuple[$i]*$precision) / $precision;
    }
  }
}

#------------------------------------------------------------------------
# $string forcePrecision ($string value, $double precision)
#------------------------------------------------------------------------
sub forcePrecision
{
   my ($value, $precision) = @_;
   if($value =~ /\d/)
   {
     $value = int($value*(10**$precision)) / (10**$precision);
   }
   return $value;
}

#------------------------------------------------------------------------
# $int getTuplePrecision (\@list tuple, $int skip)
#------------------------------------------------------------------------
sub getTuplePrecision
{
  my ($tuple,$skip) = @_;
  $skip = (not(defined($skip)) or $skip < 0) ? 0 : $skip;
  my $precision = 0;
  for(my $i=$skip; $i<scalar(@{$tuple}); $i++)
  {
    my $num = ($$tuple[$i] =~ s/(\d)/$1/g);
    if($num > $precision)
      { $precision = $num; }
  }
  return $precision;
}

#------------------------------------------------------------------------
# (\@list lines, $string last_line)
# getLinesWithIdenticalKeys ($fp file, \@list key_cols,
#                            $string last_line, string $delim)
#------------------------------------------------------------------------
sub getLinesWithIdenticalKeys
{
  my ($file,$key_cols,$last_line,$delim) = @_;
  my $key       = undef;
  my $first_key = undef;
  my @lines     = ();
  my $done      = 0;

  if(eof($file))
  {
    @lines = ($last_line);
    return (\@lines,undef);
  }

  while(not($done))
  {
    my $line   = defined($last_line) ? $last_line : <$file>;
    $last_line = undef;
    $key       = &getSubTupleString($line,$key_cols,$delim);
    $first_key = defined($first_key) ? $first_key : $key;
    my $order  = &compareKeys($key,$first_key);
    if($order == 0)
      { push(@lines, $line); } 
    else
    { 
      $done = 1;
      $last_line = $line;
    }
    
    if(eof($file))
      { $done = 1; }
  }
  return (\@lines,$last_line);
}

##------------------------------------------------------------------------
## void sequentialJoin ($string out_file, @list in_files)
##------------------------------------------------------------------------
sub sequentialJoin
{
   my ($out_file, @in_files) = @_;
   my $in_file = $in_files[0];
   my $join = "cat $in_file ";
   for(my $i = 1; $i <= $#in_files; $i++)
   {
      my $in_file   = $in_files[$i];
      $join .= "| join.pl -q - $in_file ";
   }
   $join .= "> $out_file";

   print STDERR "--> $join <--\n";
   `$join`;
   print STDERR "--> Done. <--\n";
}

sub tablePrint($\@$$$)
{
   my ($table, $fileName, $delim, $col_header, $row_header) = @_;
   $fileName   = defined($fileName) ? $fileName : '>-';
   $delim      = defined($delim) ? $delim : "\t";
   $col_header = defined($col_header) ? $col_header : "";
   $row_header = defined($row_header) ? $row_header : "";

   my $file;
   if(open($file, $fileName))
   {
      for(my $r = 0; $r < @{$table}; $r++)
      {
         my $row    = $$table[$r];
         my $header = $row_header;
         my $rowi   = $r + 1;
         $header    =~ s/\$\(ROW\)/$rowi/gi;
         print $file $header, join($delim, @{$row}), "\n";
      }
   }
   close($file);
}

sub getPermutation
{
   my ($n) = @_;

   my @pairs;
   for(my $i = 0; $i < $n; $i++)
   {
      my $r = rand;
      push(@pairs, [$r,$i]);
   }
   @pairs = sort {$$a[0] <=> $$b[0];} @pairs;

   my @permutation;
   foreach my $pair (@pairs)
   {
      push(@permutation, $$pair[1]);
   }

   return \@permutation;
}

# Permute the entries of a list in place.
sub permuteList
{
   my ($list) = @_;

   my $n = scalar(@{$list});

   my $perm = &getPermutation($n);

   my @copy;

   for(my $i = 0; $i < $n; $i++)
   {
      push(@copy, $$list[$i]);
   }

   for(my $i = 0; $i < $n; $i++)
   {
      $$list[$i] = $copy[$$perm[$i]];
   }
}

sub permuteColumn
{
   my ($table, $col) = @_;
   $col = defined($col) ? $col : 0;

   my $num_rows = scalar(@{$table});

   my $perm = &getPermutation($num_rows);

   my @copy;
   for(my $i = 0; $i < $num_rows; $i++)
   {
      push(@copy, $$table[$i][$col]);
   }

   for(my $i = 0; $i < $num_rows; $i++)
   {
      $$table[$i][$col] = $copy[$$perm[$i]];
   }
}

sub createIfNotExist
{
   return &newEntryIfNoneExists(@_);
}

sub newEntryIfNoneExists
{
   my ($set, $key, $type) = @_;
   $type = defined($type) ? $type : 'set';

   if(not(exists($$set{$key})))
   {
      my $entry = undef;
      if($type eq 'set')
      {
         my %new_set;
         $entry = \%new_set;
      }
      elsif($type eq 'list')
      {
         my @new_list;
         $entry = \@new_list;
      }
      $$set{$key} = $entry;
      return 1;
   }
   return 0;
}

sub keepDefined
{
   my @keep;
   foreach my $x (@_)
   {
      if(defined($x))
      {
         push(@keep, $x);
      }
   }
   return \@keep;
}

sub undefAdd
{
   my $sum = undef;

   foreach my $x (@_)
   {
      if(not(defined($x)))
      {
         return undef;
      }
      $sum = defined($sum) ? $sum + $x : $x;
   }
   return $sum;
}

sub safeAdd
{
   my $sum = undef;

   foreach my $x (@_)
   {
      if(defined($x))
      {
         $sum = defined($sum) ? $sum + $x : $x;
      }
   }
   return $sum;
}

sub isNumber($) {
   my ($str) = @_;
   $str =~ s/\s+//g;  # Remove any spaces.
   $str =~ s/^[+-]//; # Remove leading + or -.
   $str =~ s/[Ee][+-]{0,1}\d+[\.]{0,1}$//; # Remove trailing exponents.
   $str =~ s/[Ee][+-]{0,1}\d+\.\d+$//; # Remove trailing exponents.
   my $answer = 0;
   if($str =~ /^\d+[\.]{0,1}$/) {
      $answer = 1;
   }
   elsif($str =~ /^\d+\.\d*$/) {
      $answer = 1;
   }
   return $answer;
}

sub interpMetaChars {
   my ($text) = @_;
   $text =~ s/\\t[+*]/\t/g;
   $text =~ s/\\t/\t/g;
   $text =~ s/\\n/\n/g;
   $text =~ s/\\s[+*]/ /g;
   $text =~ s/\\s/ /g;
   return $text;
}

sub format_number
{
  my ($number, $sig_digits, $missing) = @_;
  $missing = defined($missing) ? $missing : '';

  if($number !~ /\S/) {
     return $missing;
  }

  my @num = split(/\./, $number);

  if (scalar(@num) < 2) {
      # if there isn't even a decimal point, then we just return the original number
      return $number;
  }

  my $suffix = "";
  if ($num[1] =~ /e(.*)/) { $suffix = "e$1"; }

  my $decimal = "";

  if ($num[0] == 0)  {
    my $lsb_len = length($num[1]);

    $num[1] =~ /([1-9].*)/;

    my $significant_len = length($1);

    $decimal = substr($num[1], 0, $lsb_len - $significant_len + $sig_digits);
  }
  else  {
    $decimal = substr($num[1], 0, $sig_digits);
  }

  if (length("$decimal$suffix") > 0) { return "$num[0].$decimal$suffix"; }
  else { return "$num[0]"; }
}

1
