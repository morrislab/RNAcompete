#!/usr/bin/perl

use strict;

my $verbose   = 1;
my $delim     = "\t";
my $delim_in  = undef;
my $delim_out = undef;
my @is_file;
my @columns;
my @files;
my $num_files = 0;

while(@ARGV)
{
   my $arg = shift @ARGV;
   if($arg eq '--help')
   {
      print STDOUT <DATA>;
      exit(0);
   }
   elsif((-f $arg) or (-l $arg) or ($arg eq '-'))
   {
      $num_files++;
      push(@files, $arg);
      push(@is_file, $num_files);
      push(@columns, $arg);
   }
   elsif($arg eq '-q')
   {
      $verbose = 0;
   }
   elsif($arg eq '-d')
   {
       $delim = shift(@ARGV);
   }
   elsif($arg eq '-di')
   {
       $delim_in = shift(@ARGV);
   }
   elsif($arg eq '-do')
   {
       $delim_out = shift(@ARGV);
   }
   else
   {
      push(@is_file, 0);
      $arg =~ s/([^\\])\\t/$1\t/g;
      $arg =~ s/^\\t/\t/;
      $arg =~ s/([^\\])\\n/$1\n/g;
      $arg =~ s/^\\n/\n/;
      $arg =~ s/\\\\/\\/g;
      push(@columns, $arg);
   }
}

$delim_in  = defined($delim_in)  ? $delim_in  : $delim;
$delim_out = defined($delim_out) ? $delim_out : $delim;

if(scalar(@files) == 0)
{
   push(@files,'-');
}

my @fins;
my @blanks;
for(my $f = 0; $f <= $#files; $f++)
{
    open($fins[$f], $files[$f]) or die("Can't read file '$files[$f]'");
    $blanks[$f] = [];
}
my $done = 0;
while(not($done))
{
    my @tokens;
    my $num_file_tokens = 0;
    $done = 1;
    for(my $c = 0; $c < @columns; $c++)
    {
        my $f = $is_file[$c];
        if($f)
        {
           $f--;
           my $fin = $fins[$f];
	   # Alex: there was a bug here: if you have the line below
	   # check for "not(eof($fin))", then it actually CLIPS OFF
	   # the last line when pasting.
           if((my $line = <$fin>)) # and not(eof($fin)))
           {
               my @tuple = split($delim_in, $line);
               chomp($tuple[$#tuple]);
               if(scalar(@tuple) > scalar(@{$blanks[$f]}))
               {
                  $blanks[$f] = &makeBlankList(scalar(@tuple));
               }
               push(@tokens, \@tuple);
               $done = 0;
               $num_file_tokens++;
           }
           else
           {
               push(@tokens, $blanks[$f]);
           }
        }
        else
        {
           push(@tokens, [$columns[$c]]);
        }
    }
    if(scalar(@files) == 0 or $num_file_tokens > 0)
    {
       &printMultiLists($delim_in, $delim_out, @tokens);
    }
}
for(my $f = 0; $f < scalar(@files); $f++)
{
    close($fins[$f]);
}

exit(0);

sub printMultiLists
{
   my ($delim_within, $delim_between, @lists) = @_;

   for(my $i = 0; $i < @lists; $i++)
   {
      print STDOUT ($i > 0 ? $delim_between : ""), join($delim_within, @{$lists[$i]});
   }
   print STDOUT "\n";
}

sub makeBlankList
{
   my ($n) = @_;

   my @blanks;

   for(my $i = 0; $i < $n; $i++)
   {
      push(@blanks, '');
   }

   return \@blanks;
}

__DATA__
syntax: paste.pl [OPTIONS]

EXAMPLES:

paste.pl -do ''  '>' FILE
  Adds a > to the leftmost position of every line in a file.

paste.pl FILE 'UNKNOWN_SOURCE'
  Puts a tab and then "UNKNOWN_SOURCE" at the end of every line.

paste.pl 'LEFT' 'MORE' FILE FILE 'RIGHT'
  Pastes a bunch of files and text together.

CAVEAT:

You cannot paste text that is ALSO a filename!! (Files override literal text.)
 Therefore:  paste.pl FILE "FILE"
 will paste TWO copies of the FILE, not the literal text "FILE"

OPTIONS:

-q: Quiet mode (default is verbose)


-di: Set the input delimiter


-do: Set the output delimiter. Default is tab.
     Set this to '' in order to output nothing at
     all between the pasted value and the next item.


-d: Set the delimiter for both input AND output simultaneously.
    Same as:   -di SOMETHING  -do SOMETHING

